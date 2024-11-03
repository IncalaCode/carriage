<?php

namespace App\Http\Controllers;

use App\Models\User;
use App\Models\user_Request;
use App\Models\Driver;
use App\Models\driverRequest;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Log;

class client_request extends Controller
{
    protected $user;

    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->user = User::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    // Single endpoint to handle all request operations
    public function handleRequest(Request $request)
    {
        try {
            $action = $request->input('action');
            $rideRequest = user_Request::where('user_id', $this->user->id)->first();

            if (!$rideRequest && $action !== 'create') {
                return $this->errorResponse('No ride request found', Response::HTTP_NOT_FOUND);
            }

            // Handle explicit actions
            if ($action) {
                return match ($action) {
                    'cancel' => $this->cancelRequest($rideRequest),
                    'update' => $this->updateRequest($request, $rideRequest),
                    'create' => $this->createRequest($request),
                    default => $this->errorResponse('Invalid action'),
                };
            }

            // Handle status-based responses
            return match ($rideRequest->status) {
                'pending' => $this->getPendingResponse($rideRequest),
                'locked' => $this->getDriverLocation($rideRequest),
                'completed' => $this->successResponse(
                    [
                        'request_status' => 'completed',
                        'request_id' => $rideRequest->id,
                        'ride_details' => $this->getRideDetails($rideRequest),
                        'completion_time' => $rideRequest->updated_at
                    ],
                    'Ride completed successfully'
                ),
                'cancelled' => $this->successResponse(
                    [
                        'request_status' => 'cancelled',
                        'request_id' => $rideRequest->id,
                        'cancellation_time' => $rideRequest->updated_at
                    ],
                    'Ride was cancelled'
                ),
                default => $this->errorResponse('Invalid status'),
            };

        } catch (\Exception $e) {
            Log::error('Request handling error: ' . $e->getMessage());
            return $this->errorResponse('An error occurred', Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    private function cancelRequest($rideRequest)
    {
        if (!in_array($rideRequest->status, ['pending', 'locked'])) {
            return response()->json([
                'status' => 'error',
                'message' => 'Cannot cancel this ride',
                'error_code' => 'INVALID_CANCELLATION',
                'current_status' => $rideRequest->status
            ], Response::HTTP_BAD_REQUEST);
        }

        $rideRequest->update([
            'status' => 'cancelled',
            'cancelled_at' => now()
        ]);
        
        if ($rideRequest->accepted_driver_ids) {
            foreach (json_decode($rideRequest->accepted_driver_ids) as $driverId) {
                $this->removeUserFromDriverRequest($driverId, $this->user->id);
            }
        }

        return response()->json([
            'status' => 'success',
            'message' => 'Ride cancelled successfully',
            'request_id' => $rideRequest->id,
            'timestamp' => now(),
            'cancellation_details' => [
                'cancelled_at' => $rideRequest->cancelled_at,
                'original_status' => $rideRequest->getOriginal('status'),
                'refund_eligible' => $this->isRefundEligible($rideRequest)
            ]
        ]);
    }

    private function updateRequest(Request $request, $rideRequest)
    {
        $validated = $request->validate([
            'from' => 'sometimes|required|string',
            'destination' => 'sometimes|required|string',
            'material_type' => 'sometimes|required|string',
            'car_type' => 'sometimes|required|string',
            'latitude' => 'sometimes|required|string',
            'longitude' => 'sometimes|required|string',
        ]);

        if ($rideRequest->status !== 'pending') {
            return $this->errorResponse('Can only update pending requests', Response::HTTP_BAD_REQUEST);
        }

        $rideRequest->update(array_filter($validated));
        return $this->successResponse(
            [
                'message' => 'Request updated',
                'ride_details' => $this->getRideDetails($rideRequest)
            ],
            'Request updated successfully',
            Response::HTTP_OK
        );
    }

    private function createRequest(Request $request)
    {
        $validated = $request->validate([
            'from' => 'required|string',
            'destination' => 'required|string',
            'material_type' => 'required|string',
            'car_type' => 'required|string',
            'latitude' => 'required|string',
            'longitude' => 'required|string',
            'scheduled_time' => 'sometimes|date|after:now', // For scheduled rides
            'special_instructions' => 'sometimes|string',
            'preferred_driver_id' => 'sometimes|exists:drivers,id'
        ]);

        // Check for existing active request
        $existingRequest = $this->checkExistingRequest();
        if ($existingRequest) {
            return $this->errorResponse('Active request exists', Response::HTTP_BAD_REQUEST, [
                'existing_request' => $this->getRideDetails($existingRequest)
            ]);
        }

        // Create new request with additional features
        $rideRequest = user_Request::create([
            'user_id' => $this->user->id,
            'from' => $validated['from'],
            'destination' => $validated['destination'],
            'material_type' => $validated['material_type'],
            'car_type' => $validated['car_type'],
            'status' => 'pending',
            'accepted_driver_ids' => json_encode([]),
            'scheduled_time' => $validated['scheduled_time'] ?? null,
            'special_instructions' => $validated['special_instructions'] ?? null,
            'preferred_driver_id' => $validated['preferred_driver_id'] ?? null,
            'created_at' => now(),
            'expires_at' => now()->addMinutes(5)
        ]);

        // If it's a scheduled ride, handle differently
        if (isset($validated['scheduled_time'])) {
            return $this->handleScheduledRide($rideRequest, $validated);
        }

        // Match with drivers
        $this->matchWithDrivers($rideRequest, $validated);

        return $this->successResponse([
            'request_id' => $rideRequest->id,
            'timestamp' => $rideRequest->created_at,
            'request_details' => $this->getRideDetails($rideRequest),
            'matching_drivers' => $this->getMatchingDriversInfo($rideRequest),
            'expires_at' => $rideRequest->expires_at,
            'next_steps' => [
                'message' => 'Waiting for driver acceptance',
                'estimated_wait_time' => '3-5 minutes'
            ]
        ], 'Request created successfully', Response::HTTP_CREATED);
    }

    private function getDriverLocation($rideRequest)
    {
        if (!$rideRequest->locked_driver_id) {
            return response()->json([
                'status' => 'locked',
                'error' => true,
                'message' => 'No driver assigned',
                'request_id' => $rideRequest->id
            ], Response::HTTP_BAD_REQUEST);
        }

        $driverRequest = driverRequest::where('driver_id', $rideRequest->locked_driver_id)->first();
        $driver = Driver::find($rideRequest->locked_driver_id);
        
        return response()->json([
            'status' => 'locked',
            'request_id' => $rideRequest->id,
            'timestamp' => now(),
            'driver_details' => [
                'driver_id' => $driver->id,
                'name' => $driver->name,
                'car_type' => $driver->car_type,
                'rating' => $driver->rating,
                'location' => [
                    'latitude' => $driverRequest->latitude ?? null,
                    'longitude' => $driverRequest->longitude ?? null,
                    'last_updated' => $driverRequest->updated_at
                ],
                'estimated_arrival' => $this->calculateEstimatedArrival($driverRequest)
            ],
            'ride_status' => [
                'started_at' => $rideRequest->locked_at,
                'current_status' => 'en_route'
            ]
        ]);
    }

    private function calculateEstimatedArrival($driverRequest)
    {
        // Implement your ETA calculation logic here
        // For now, returning a placeholder
        return now()->addMinutes(15)->toDateTimeString();
    }

    private function getRideDetails($rideRequest)
    {
        $details = $rideRequest->toArray();
        
        if ($rideRequest->accepted_driver_ids) {
            $driverIds = json_decode($rideRequest->accepted_driver_ids);
            $details['available_drivers'] = Driver::whereIn('id', $driverIds)
                ->select('id', 'name', 'car_type', 'rating')
                ->get();
        }

        return $details;
    }

    private function matchWithDrivers($rideRequest, $validated)
    {
        // Get online drivers first
        $matchingDrivers = driverRequest::where('car_type', $validated['car_type'])
            ->where('status', 'pending')
            ->where('is_online', true)
            ->where('is_available', true)
            ->where('last_active', '>=', now()->subMinutes(5)) // Only drivers active in last 5 minutes
            ->get();

        // If no online drivers, check offline drivers within service area
        if ($matchingDrivers->isEmpty()) {
            $matchingDrivers = $this->findOfflineDriversInArea($validated);
        }

        $driverIds = [];
        foreach ($matchingDrivers as $driverRequest) {
            if ($this->isDriverEligible($driverRequest, $validated)) {
                $driverIds[] = $driverRequest->driver_id;
                $this->addUserToDriverRequest($driverRequest, $this->user->id, $validated);
                
                // Notify offline drivers via push notification
                if (!$driverRequest->is_online) {
                    $this->notifyOfflineDriver($driverRequest->driver_id, $rideRequest);
                }
            }
        }

        if (!empty($driverIds)) {
            $rideRequest->update([
                'accepted_driver_ids' => json_encode($driverIds),
                'matching_timestamp' => now()
            ]);
        }

        // Set up request expiration
        $this->scheduleRequestExpiration($rideRequest);
    }

    private function findOfflineDriversInArea($validated)
    {
        return driverRequest::where('car_type', $validated['car_type'])
            ->where('status', 'pending')
            ->where('is_available', true)
            ->where(function ($query) use ($validated) {
                // Check if driver's service area includes the pickup location
                $query->whereRaw("JSON_CONTAINS(service_area, ?)", [
                    json_encode([
                        'lat' => $validated['latitude'],
                        'lng' => $validated['longitude']
                    ])
                ]);
            })
            ->get();
    }

    private function isDriverEligible($driverRequest, $validated)
    {
        // Check driver's current request count
        $activeRequests = user_Request::where('locked_driver_id', $driverRequest->driver_id)
            ->whereIn('status', ['pending', 'locked'])
            ->count();

        if ($activeRequests >= $driverRequest->max_requests) {
            return false;
        }

        // Check driver preferences
        $preferences = json_decode($driverRequest->preferences, true) ?? [];
        if (!empty($preferences)) {
            if (isset($preferences['material_types']) && 
                !in_array($validated['material_type'], $preferences['material_types'])) {
                return false;
            }
            
            if (isset($preferences['max_distance']) && 
                $this->calculateDistance($driverRequest, $validated) > $preferences['max_distance']) {
                return false;
            }
        }

        return true;
    }

    private function calculateDistance($driverRequest, $validated)
    {
        // Implement distance calculation between driver and pickup location
        // Using Haversine formula or Google Distance Matrix API
        return 0; // Placeholder
    }

    private function notifyOfflineDriver($driverId, $rideRequest)
    {
        // Implement push notification logic here
        // Could use Firebase Cloud Messaging or similar service
        Log::info("Notifying offline driver: $driverId about request: {$rideRequest->id}");
    }

    private function scheduleRequestExpiration($rideRequest)
    {
        // Schedule request expiration after 5 minutes if no driver accepts
        // Implementation depends on your queue/job system
        // Example using Laravel's built-in scheduling:
        \Illuminate\Support\Facades\Schedule::call(function () use ($rideRequest) {
            $this->handleRequestExpiration($rideRequest);
        })->delay(now()->addMinutes(5));
    }

    private function handleRequestExpiration($rideRequest)
    {
        if ($rideRequest->status === 'pending') {
            $rideRequest->update([
                'status' => 'expired',
                'expired_at' => now()
            ]);

            // Notify user about request expiration
            // Implement notification logic here
        }
    }

    private function addUserToDriverRequest($driverRequest, $userId, $location)
    {
        $acceptedUserIds = json_decode($driverRequest->accepted_user_ids ?? '[]');
        if (!in_array($userId, $acceptedUserIds)) {
            $acceptedUserIds[] = $userId;
            $driverRequest->update(['accepted_user_ids' => json_encode($acceptedUserIds)]);
        }
    }

    private function removeUserFromDriverRequest($driverId, $userId)
    {
        $driverRequest = driverRequest::where('driver_id', $driverId)->first();
        if ($driverRequest) {
            $acceptedUserIds = array_diff(
                json_decode($driverRequest->accepted_user_ids ?? '[]'),
                [$userId]
            );
            $driverRequest->update(['accepted_user_ids' => json_encode(array_values($acceptedUserIds))]);
        }
    }

    private function getPendingResponse($rideRequest)
    {
        $response = [
            'status' => 'pending',
            'request_id' => $rideRequest->id,
            'timestamp' => $rideRequest->created_at,
            'ride_details' => [
                'from' => $rideRequest->from,
                'destination' => $rideRequest->destination,
                'material_type' => $rideRequest->material_type,
                'car_type' => $rideRequest->car_type,
            ],
            'matching_drivers' => $this->getMatchingDriversInfo($rideRequest),
            'message' => 'Waiting for driver acceptance'
        ];

        return response()->json($response);
    }

    private function getMatchingDriversInfo($rideRequest)
    {
        if (!$rideRequest->accepted_driver_ids) {
            return [];
        }

        $driverIds = json_decode($rideRequest->accepted_driver_ids);
        return Driver::whereIn('id', $driverIds)
            ->select('id', 'name', 'car_type', 'rating', 'total_rides')
            ->get()
            ->map(function ($driver) {
                return [
                    'driver_id' => $driver->id,
                    'name' => $driver->name,
                    'car_type' => $driver->car_type,
                    'rating' => $driver->rating,
                    'experience' => [
                        'total_rides' => $driver->total_rides,
                        'rating' => $driver->rating
                    ]
                ];
            });
    }

    private function errorResponse($message, $code = Response::HTTP_BAD_REQUEST)
    {
        return response()->json([
            'status' => 'error',
            'code' => $code,
            'message' => $message,
            'data' => null
        ], $code);
    }

    private function successResponse($data, $message, $code = Response::HTTP_OK)
    {
        return response()->json([
            'status' => 'success',
            'code' => $code,
            'data' => $data,
            'message' => $message
        ], $code);
    }

    private function isRefundEligible($rideRequest)
    {
        // Implement your refund eligibility logic here
        return $rideRequest->status === 'pending';
    }

    private function checkExistingRequest()
    {
        return user_Request::where('user_id', $this->user->id)
            ->whereIn('status', ['pending', 'locked'])
            ->first();
    }

    private function handleScheduledRide($rideRequest, $validated)
    {
        $rideRequest->update([
            'status' => 'scheduled',
            'scheduled_time' => $validated['scheduled_time']
        ]);

        return $this->successResponse([
            'request_id' => $rideRequest->id,
            'scheduled_time' => $validated['scheduled_time'],
            'request_details' => $this->getRideDetails($rideRequest)
        ], 'Ride scheduled successfully', Response::HTTP_CREATED);
    }
}