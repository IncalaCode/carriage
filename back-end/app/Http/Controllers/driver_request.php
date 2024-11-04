<?php

namespace App\Http\Controllers;

use App\Models\Driver;
use App\Models\user_Request;
use App\Models\driverRequest;
use App\Models\RidePrice;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Carbon\Carbon;

class driver_request extends Controller
{
    protected $user;
    private const INACTIVE_TIMEOUT = 300; // 5 minutes in seconds
    private const POLLING_TIMEOUT = 30; // 30 seconds for polling

    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->user = Driver::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    public function handleRequest(Request $request)
    {
        // Update last_active timestamp and location
        $this->updateDriverStatus($request);

        // Get current driver request status
        $driverRequest = driverRequest::where('driver_id', $this->user->id)
            ->whereIn('status', ['pending', 'locked'])
            ->first();

        // If trying to start new search but has active request
        if ($request->has(['latitude', 'longitude']) && $driverRequest) {
            return response()->json([
                'message' => 'Active request exists',
                'current_request' => [
                    'status' => $driverRequest->status,
                    'created_at' => $driverRequest->created_at,
                    'current_location' => [
                        'latitude' => $driverRequest->latitude,
                        'longitude' => $driverRequest->longitude
                    ]
                ],
                'next_action' => $this->getStatusAction($driverRequest->status)
            ], 303); // 303 See Other
        }

        $action = $this->determineAction($driverRequest, $request);
        
        switch($action) {
            case 'start_searching':
                return $this->startSearching($request);
            case 'get_requests':
                return $this->getRequests($request);
            case 'accept_ride':
                return $this->acceptRide($request);
            case 'update_location':
                return $this->updateLocation($request);
            default:
                return response()->json([
                    'error' => 'System cannot determine next action',
                    'current_status' => $driverRequest ? $driverRequest->status : 'none'
                ], 400);
        }
    }

    private function updateDriverStatus(Request $request)
    {
        $this->user->update([
            'last_active' => Carbon::now(),
            'latitude' => $request->input('latitude'),
            'longitude' => $request->input('longitude'),
            'is_online' => true
        ]);

        // Set drivers inactive after timeout
        Driver::where('last_active', '<', Carbon::now()->subSeconds(self::INACTIVE_TIMEOUT))
            ->update(['is_online' => false]);
    }

    private function startSearching(Request $request)
    {
        $validated = $request->validate([
            'latitude' => 'required|string',
            'longitude' => 'required|string',
        ]);

        // Clear any existing requests
        driverRequest::where('driver_id', $this->user->id)
            ->where('status', 'pending')
            ->delete();

        return driverRequest::create([
            'driver_id' => $this->user->id,
            'longitude' => $validated['longitude'],
            'latitude' => $validated['latitude'],
            'car_type' => $this->user->car_type,
            'status' => 'pending',
        ]);
    }

    private function getRequests(Request $request)
    {
        $timeout = self::POLLING_TIMEOUT;
        
        while ($timeout > 0) {
            $requests = user_Request::where('car_type', $this->user->car_type)
                ->where('status', 'pending')
                ->whereNotIn('id', function($query) {
                    $query->select('request_id')
                        ->from('driver_requests')
                        ->where('driver_id', $this->user->id);
                })
                ->get()
                ->map(function ($request) {
                    return [
                        'request_id' => $request->id,
                        'from' => $request->from,
                        'destination' => $request->destination,
                        'material_type' => $request->material_type,
                        'user' => $request->user
                    ];
                });

            if ($requests->isNotEmpty()) {
                return response()->json(['requests' => $requests]);
            }

            $timeout--;
            sleep(1);
        }

        return response()->json(['message' => 'No requests available']);
    }

    private function acceptRide(Request $request) 
    {
        $validated = $request->validate([
            'user_request_id' => 'required|integer',
            'price' => 'required|numeric'
        ]);

        $userRequest = user_Request::findOrFail($validated['user_request_id']);
        
        if ($userRequest->status !== 'pending') {
            return response()->json(['error' => 'Request no longer available'], 400);
        }

        // Add driver to accepted drivers list
        $acceptedDrivers = $userRequest->accepted_driver_ids ?? [];
        if (!in_array($this->user->id, $acceptedDrivers)) {
            $acceptedDrivers[] = $this->user->id;
        }
        
        // Store price in separate table
        RidePrice::updateOrCreate(
            [
                'request_id' => $validated['user_request_id'],
                'driver_id' => $this->user->id
            ],
            ['price' => $validated['price']]
        );

        $userRequest->update([
            'accepted_driver_ids' => $acceptedDrivers
        ]);

        return response()->json(['message' => 'Ride accepted successfully']);
    }

    private function updateLocation(Request $request)
    {
        $validated = $request->validate([
            'latitude' => 'required|string',
            'longitude' => 'required|string',
        ]);

        $this->user->update([
            'latitude' => $validated['latitude'],
            'longitude' => $validated['longitude']
        ]);

        return response()->json(['message' => 'Location updated successfully']);
    }

    private function cancelRequest($driverRequest)
    {
        if (!$driverRequest || $driverRequest->status !== 'pending') {
            return response()->json(['error' => 'Can only cancel pending requests'], 400);
        }

        $driverRequest->update(['status' => 'cancelled']);
        return response()->json(['message' => 'Request cancelled successfully']);
    }

    private function determineAction($driverRequest, $request)
    {
        // If starting new search but has active request, return current status
        if ($request->has(['latitude', 'longitude']) && $driverRequest) {
            return $this->getStatusAction($driverRequest->status);
        }

        // If no current request and location is provided
        if (!$driverRequest && $request->has(['latitude', 'longitude'])) {
            return 'start_searching';
        }

        if (!$driverRequest) {
            return 'start_searching';
        }

        return $this->getStatusAction($driverRequest->status);
    }

    private function getStatusAction($status)
    {
        switch($status) {
            case 'pending':
                return 'get_requests';
            case 'locked':
                return 'update_location';
            default:
                return 'start_searching';
        }
    }
}
