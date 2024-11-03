<?php

namespace App\Http\Controllers;

use App\Models\Driver;
use App\Models\user_Request;
use App\Models\driverRequest;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;

class driver_request extends Controller
{
    protected $driver;

    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->driver = Driver::where('uid', $token)->first();

        if (!$this->driver) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    // Update driver's online status and preferences
    public function updateStatus(Request $request)
    {
        $validated = $request->validate([
            'is_online' => 'required|boolean',
            'latitude' => 'required_if:is_online,true|string',
            'longitude' => 'required_if:is_online,true|string',
        ]);

        $driverRequest = driverRequest::where('driver_id', $this->driver->id)->first();
        
        if (!$driverRequest) {
            $driverRequest = driverRequest::create([
                'driver_id' => $this->driver->id,
                'car_type' => $this->driver->car_type,
                'status' => 'pending',
                'is_online' => $validated['is_online'],
                'last_active' => now(),
            ]);
        }

        $updateData = [
            'is_online' => $validated['is_online'],
            'last_active' => now(),
        ];

        if ($validated['is_online']) {
            $updateData['latitude'] = $validated['latitude'];
            $updateData['longitude'] = $validated['longitude'];
        }

        $driverRequest->update($updateData);

        return response()->json([
            'status' => 'success',
            'message' => 'Status updated successfully',
            'is_online' => $validated['is_online']
        ]);
    }

    public function updatePreferences(Request $request)
    {
        $validated = $request->validate([
            'max_requests' => 'sometimes|integer|min:1|max:5',
            'material_types' => 'sometimes|array',
            'max_distance' => 'sometimes|integer|min:1',
            'preferred_areas' => 'sometimes|array'
        ]);

        $driverRequest = driverRequest::where('driver_id', $this->driver->id)->first();
        
        if (!$driverRequest) {
            return response()->json([
                'status' => 'error',
                'message' => 'Driver request not found'
            ], Response::HTTP_NOT_FOUND);
        }

        $preferences = array_merge(
            json_decode($driverRequest->preferences ?? '{}', true) ?: [],
            $validated
        );

        $driverRequest->update([
            'preferences' => json_encode($preferences),
            'max_requests' => $validated['max_requests'] ?? $driverRequest->max_requests
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Preferences updated successfully',
            'preferences' => $preferences
        ]);
    }

    public function updateServiceArea(Request $request)
    {
        $validated = $request->validate([
            'service_area' => 'required|array',
            'service_area.*.lat' => 'required|numeric',
            'service_area.*.lng' => 'required|numeric',
            'service_area.*.radius' => 'required|numeric'
        ]);

        $driverRequest = driverRequest::where('driver_id', $this->driver->id)->first();
        
        if (!$driverRequest) {
            return response()->json([
                'status' => 'error',
                'message' => 'Driver request not found'
            ], Response::HTTP_NOT_FOUND);
        }

        $driverRequest->update([
            'service_area' => json_encode($validated['service_area'])
        ]);

        return response()->json([
            'status' => 'success',
            'message' => 'Service area updated successfully',
            'service_area' => $validated['service_area']
        ]);
    }

    public function getRequest(Request $request)
    {
        $validated = $request->validate([
            'latitude' => 'required|string',
            'longitude' => 'required|string',
        ]);

        // Update driver's location and online status
        $driverRequest = $this->updateDriverStatus($validated);

        $timeout = env("Timeout", 30);
        $startTime = now();

        while ($timeout > 0 && now()->diffInSeconds($startTime) < $timeout) {
            $matchingRequests = $this->findMatchingRequests($driverRequest);
            
            if ($matchingRequests->isNotEmpty()) {
                return response()->json([
                    'status' => 'success',
                    'message' => 'New requests found',
                    'requests' => $matchingRequests->map(function ($request) {
                        return [
                            'request_id' => $request->id,
                            'pickup' => [
                                'location' => $request->from,
                                'coordinates' => [
                                    'latitude' => $request->latitude,
                                    'longitude' => $request->longitude
                                ]
                            ],
                            'destination' => $request->destination,
                            'material_type' => $request->material_type,
                            'car_type' => $request->car_type,
                            'created_at' => $request->created_at,
                            'expires_at' => $request->expires_at
                        ];
                    })
                ]);
            }

            usleep(500000); // Sleep 500ms
            $timeout--;
        }

        return response()->json([
            'status' => 'success',
            'message' => 'No new requests',
            'driver_status' => [
                'is_online' => $driverRequest->is_online,
                'last_active' => $driverRequest->last_active
            ]
        ]);
    }

    private function updateDriverStatus($validated)
    {
        $driverRequest = driverRequest::where('driver_id', $this->driver->id)->first();

        if (!$driverRequest) {
            $driverRequest = driverRequest::create([
                'driver_id' => $this->driver->id,
                'longitude' => $validated['longitude'],
                'latitude' => $validated['latitude'],
                'car_type' => $this->driver->car_type,
                'status' => 'pending',
                'is_online' => true,
                'last_active' => now()
            ]);
        } else {
            $driverRequest->update([
                'longitude' => $validated['longitude'],
                'latitude' => $validated['latitude'],
                'last_active' => now(),
                'is_online' => true
            ]);
        }

        return $driverRequest;
    }

    private function findMatchingRequests($driverRequest)
    {
        $preferences = json_decode($driverRequest->preferences ?? '{}', true) ?: [];
        $maxDistance = $preferences['max_distance'] ?? 10; // Default 10km

        return user_Request::where('status', 'pending')
            ->where('car_type', $this->driver->car_type)
            ->where('expires_at', '>', now())
            ->whereRaw($this->getDistanceQuery(), [
                $driverRequest->latitude,
                $driverRequest->longitude,
                $maxDistance
            ])
            ->when(!empty($preferences['material_types']), function ($query) use ($preferences) {
                return $query->whereIn('material_type', $preferences['material_types']);
            })
            ->get();
    }

    private function getDistanceQuery()
    {
        // Haversine formula to calculate distance
        return "
            (6371 * acos(
                cos(radians(?)) * 
                cos(radians(CAST(latitude AS FLOAT))) * 
                cos(radians(CAST(longitude AS FLOAT)) - radians(?)) + 
                sin(radians(?)) * 
                sin(radians(CAST(latitude AS FLOAT)))
            )) <= ?
        ";
    }

    // Long polling to get confirmation updates
    public function getConfirmation()
    {
        $timeout =  env("Timeout");


        while ($timeout) {
            $rideRequest = driverRequest::where('driver_id', $this->driver->id)
                ->where('status', 'pending')
                ->first();
            usleep(500000);  // Sleep 500ms

            $timeout--;
        }

        if ($rideRequest) {
            return response()->json($rideRequest);
        }

        return response()->json(['message' => 'No confirmation yet'], Response::HTTP_NO_CONTENT);
    }

    // Accept a ride request (standard POST request)
    public function acceptRequest(Request $request)
    {
        $validated = $request->validate([
            'user_id' => 'required|string',
            'price' => 'required|numeric'
        ]);

        $driverRequest = driverRequest::where('driver_id', $this->driver->id)
            ->where('status', 'pending')
            ->first();

        if (!$driverRequest) {
            return response()->json(['error' => 'client request not found or already taken'], Response::HTTP_NOT_FOUND);
        }

        $rideRequest = user_Request::where('user_id', $validated['user_id'])->first();
        if (!$rideRequest) {
            return response()->json(['error' => 'User request not found'], Response::HTTP_NOT_FOUND);
        }

        $acceptedDrivers = json_decode($rideRequest->accepted_driver_ids ?? '[]', true); // Decode as associative array

        foreach ($acceptedDrivers as &$driver) {
            // Check if this is the current user's driver entry
            if ($driver['driver_id'] == $this->driver->id) {
                $driver['price'] = $validated['price']; // Set the price
            }
        }
        
        // Re-encode the modified array into JSON and update the ride request
        $rideRequest->update(['accepted_driver_ids' => json_encode($acceptedDrivers)]);
        
        return response()->json(['message' => 'Acceptance sent successfully, please wait for confirmation']);
    }

    // Send tracking updates (e.g., driver's location)
    public function sendTracking(Request $request)
    {
        $validated = $request->validate([
            'latitude' => 'required|string',
            'longitude' => 'required|string',
        ]);

        $rideRequest = driverRequest::where('uid', $this->driver->id)->first();
        if (!$rideRequest) {
            return response()->json(['error' => 'Ride request not found'], Response::HTTP_NOT_FOUND);
        }

        $rideRequest->update([
            'driver_latitude' => $validated['latitude'],
            'driver_longitude' => $validated['longitude'],
            'updated_at' => Carbon::now()
        ]);

        return response()->json(["status"=>true]);
    }


    public function cancelAcceptance()
    {
        // Fetch the driver's request entry based on the authenticated driver
        $driverRequest = driverRequest::where('driver_id', $this->driver->id)
            ->where('status', 'pending')
            ->first();
    
        if (!$driverRequest) {
            return response()->json(['message' => 'No pending request found for this driver'], Response::HTTP_NOT_FOUND);
        }
    
        // Fetch the rider's request entry based on the user accepted by the driver
        $rideRequest = user_Request::whereJsonContains('accepted_driver_ids', ['driver_id' => $this->driver->id])
            ->where('status', 'pending')
            ->first();
    
        if (!$rideRequest) {
            return response()->json(['message' => 'No matching ride request found for the user'], Response::HTTP_NOT_FOUND);
        }
    
        // Remove the user from the driver's accepted_user_ids list
        $existingAcceptedUsers = json_decode($driverRequest->accepted_user_ids ?? '[]', true);
        $updatedAcceptedUsers = array_filter($existingAcceptedUsers, function ($user) {
            return $user['user_id'] !== $this->driver->id;
        });
    
        $driverRequest->update([
            'accepted_user_ids' => json_encode(array_values($updatedAcceptedUsers))
        ]);
    
        // Remove the driver from the rider's accepted_driver_ids list
        $existingAcceptedDrivers = json_decode($rideRequest->accepted_driver_ids ?? '[]', true);
        $updatedAcceptedDrivers = array_filter($existingAcceptedDrivers, function ($driver) {
            return $driver['driver_id'] !== $this->driver->id;
        });
    
        $rideRequest->update([
            'accepted_driver_ids' => json_encode(array_values($updatedAcceptedDrivers))
        ]);
    
        return response()->json(['message' => 'Acceptance cancelled successfully']);
    }
    

    public function handleRequest(Request $request)
    {
        try {
            $action = $request->input('action');
            
            // Handle explicit actions
            if ($action) {
                return match ($action) {
                    'update_status' => $this->updateStatus($request),
                    'update_preferences' => $this->updatePreferences($request),
                    'update_service_area' => $this->updateServiceArea($request),
                    'accept_request' => $this->acceptRequest($request),
                    'cancel_acceptance' => $this->cancelAcceptance(),
                    'send_tracking' => $this->sendTracking($request),
                    default => $this->errorResponse('Invalid action'),
                };
            }

            // If no action specified, default to getting requests
            return $this->getRequest($request);

        } catch (\Exception $e) {
            Log::error('Driver request handling error: ' . $e->getMessage());
            return $this->errorResponse('An error occurred', Response::HTTP_INTERNAL_SERVER_ERROR);
        }
    }

    // Add these helper methods for consistent responses
    private function errorResponse($message, $code = Response::HTTP_BAD_REQUEST, $data = null)
    {
        return response()->json([
            'status' => 'error',
            'code' => $code,
            'message' => $message,
            'data' => $data
        ], $code);
    }

    private function successResponse($data, $message = '', $code = Response::HTTP_OK)
    {
        return response()->json([
            'status' => 'success',
            'code' => $code,
            'message' => $message,
            'data' => $data
        ], $code);
    }

}
