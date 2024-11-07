<?php

namespace App\Http\Controllers;

use App\Models\user_Request;
use App\Models\Driver;
use App\Models\User;
use App\Models\driverRequest;
use App\Models\RidePrice;
use App\Models\RequestStatus;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class client_request extends Controller
{
    protected $user;
    private const TIMEOUT = 30; // 30 seconds for polling

    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->user = User::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    public function handleRequest(Request $request)
    {
        // Get current user request if exists
        $currentRequest = user_Request::where('user_id', $this->user->id)
            ->whereIn('status', [
                RequestStatus::PENDING,
                RequestStatus::DRIVER_ACCEPTED,
                RequestStatus::LOCKED,
                RequestStatus::IN_PROGRESS
            ])
            ->first();

        // Determine action based on current status
        $action = $this->determineAction($currentRequest, $request);

        // If trying to create new request but has active one
        if ($request->has(['from', 'destination']) && $currentRequest) {
            return response()->json([
                'message' => 'Active request exists',
                'current_request' => [
                    'status' => $currentRequest->status,
                    'from' => $currentRequest->from,
                    'destination' => $currentRequest->destination,
                    'created_at' => $currentRequest->created_at
                ],
                'next_action' => $this->getStatusAction($currentRequest->status)
            ], 303); // 303 See Other
        }

        switch ($action) {
            case 'create_request':
                return $this->createRequest($request);
            case 'get_drivers':
                return $this->getDrivers($currentRequest);
            case 'select_driver':
                return $this->selectDriver($request, $currentRequest);
            case 'track_driver':
                return $this->trackDriver($currentRequest);
            case 'cancel_request':
                return $this->cancelRequest($currentRequest);
            case 'complete_ride':
                return $this->completeRide($currentRequest);
            case 'update_request':
                return $this->updateRequest($request, $currentRequest);
            default:
                return response()->json([
                    'error' => 'System cannot determine next action',
                    'current_status' => $currentRequest ? $currentRequest->status : 'none'
                ], 400);
        }
    }

    private function determineAction($currentRequest, $request)
    {
        // Check if this is an update request
        if (
            $currentRequest &&
            $currentRequest->status === 'pending' &&
            $request->has(['update']) &&
            ($request->has('from') || $request->has('destination') ||
                $request->has('material_type') || $request->has('car_type'))
        ) {
            return 'update_request';
        }

        // If creating new request but has active one, return current status info
        if ($request->has(['from', 'destination', 'material_type', 'car_type']) && $currentRequest) {
            return $this->getStatusAction($currentRequest->status);
        }

        // If no current request and request has required fields for creation
        if (!$currentRequest && $request->has(['from', 'destination', 'material_type', 'car_type'])) {
            return 'create_request';
        }
        if ($currentRequest && $request->has(['driver_id'])) {
            return 'select_driver';
        }



        if (!$currentRequest) {
            return 'create_request';
        }

        return $this->getStatusAction($currentRequest->status);
    }


    private function getStatusAction($status)
    {
        switch ($status) {
            case RequestStatus::PENDING:
                return 'get_drivers';
            case RequestStatus::DRIVER_ACCEPTED:
                return 'get_drivers';
            case RequestStatus::LOCKED:
                return 'track_driver';
            case RequestStatus::IN_PROGRESS:
                return 'track_driver';
            case RequestStatus::COMPLETED:
            case RequestStatus::CANCELLED:
                return 'create_request';
            default:
                return null;
        }
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
        ]);

        // Check existing pending request
        if (user_Request::where('user_id', $this->user->id)
            ->whereIn('status', ['pending', 'locked'])
            ->exists()
        ) {
            return response()->json([
                'error' => 'Active request already exists'
            ], 400);
        }

        $request = user_Request::create([
            'user_id' => $this->user->id,
            'from' => $validated['from'],
            'destination' => $validated['destination'],
            'material_type' => $validated['material_type'],
            'car_type' => $validated['car_type'],
            'status' => RequestStatus::PENDING,
            'accepted_driver_ids' => [],
            'prices' => []
        ]);

        return response()->json([
            'message' => 'Request created successfully',
            'request' => $request,
            'next_actions' => RequestStatus::getNextActions(RequestStatus::PENDING)
        ]);
    }



    private function getDrivers($currentRequest)
    {
        if (!$currentRequest || $currentRequest->status !== 'pending') {
            return response()->json(['error' => 'No active request found'], 404);
        }
    
        $timeout = self::TIMEOUT;
    
        while ($timeout > 0) {
            // Refresh request data
            $currentRequest->refresh();
    
            // Get accepted drivers from the request
            $acceptedDriverIds = json_decode($currentRequest->accepted_driver_ids ?? "[]");
            
            if (!empty($acceptedDriverIds)) {
                // Fetch drivers and relevant data
                $drivers = Driver::whereIn('uid', $acceptedDriverIds)
                    ->where('is_online', true)
                    ->get()
                    ->map(function ($driver) use ($currentRequest) {
                        // Get price from the prices table
                        $priceRecord = RidePrice::where('request_id', $currentRequest->id)
                            ->where('driver_id', $driver->id)
                            ->first();
                        $requestDriver = driverRequest::where('driver_id', $driver->id)
                            ->where('status', "pending")
                            ->first();
    
                        return [
                            'driver_id' => $driver->id,
                            'name' => $driver->first_name . " " . $driver->last_name,
                            'car_type' => $driver->car_type,
                            'price' => $priceRecord ? $priceRecord->price : null,
                            'latitude' => $requestDriver->latitude,
                            'longitude' => $requestDriver->longitude,
                        ];
                    });
    
                // Retrieve previous driver data from the cache
                $cachedDrivers = Cache::get("previous_drivers_{$currentRequest->id}", []);
    
                // Check if the current drivers list differs from the cached one
                if ($drivers->toArray() !== $cachedDrivers) {
                    // Update the cache with new driver data
                    Cache::put("previous_drivers_{$currentRequest->id}", $drivers->toArray(), now()->addMinutes(5));
    
                    return response()->json([
                        'drivers' => $drivers,
                        'next_actions' => RequestStatus::getNextActions($currentRequest->status),
                        'current_status' => $currentRequest->status
                    ]);
                }
            }
    
            // Decrement timeout and pause
            $timeout--;
            sleep(1);
        }
    
        return response()->json(['message' => 'No drivers available yet', 'drivers' => $drivers ], 200);
    }
    
    private function selectDriver(Request $request, $currentRequest)
    {
        if (!$currentRequest || $currentRequest->status !== 'pending') {
            return response()->json(['error' => 'No active request found'], 404);
        }

        $validated = $request->validate([
            'driver_id' => 'required|integer'
        ]);

        if (!in_array($validated['driver_id'], json_decode($currentRequest->accepted_driver_ids))) {
            return response()->json(['error' => 'Invalid driver selection'], 400);
        }

        if(!driverRequest::where("driver_id",$validated['driver_id'],)->where(
            'status', 'locked')){
                return response()->json(['error' => 'The driver you accpeted is locked to anothere user'], 404);
            }

        $currentRequest->update([
            'status' => 'locked',
            'locked_driver_id' => $validated['driver_id']
        ]);

        driverRequest::where("driver_id",$validated['driver_id'],)->update([
            'status' => 'locked',
            'locked_user_id' => $validated['driver_id']
        ]);

        return response()->json(['message' => 'Driver selected successfully']);
    }

    private function trackDriver($currentRequest)
    {
        if (!$currentRequest || $currentRequest->status !== 'locked') {
            return response()->json(['error' => 'No locked request found'], 404);
        }
    
        // Retrieve the locked driver
        $driver = Driver::where('uid', $currentRequest->locked_driver_id)
        ->where('status', 'locked')
        ->first();
    
        // Check if driver is available and online
        if (!$driver || !$driver->is_online) {
            return response()->json(['error' => 'Driver not online'], 404);
        }
    
        // Retrieve driver request information based on driver_id
        $driverRequest = driverRequest::where('driver_id', $driver->id)
            ->where('status', 'locked')
            ->first();
    
        if (!$driverRequest) {
            return response()->json(['error' => 'No active driver request found'], 404);
        }
    
        return response()->json([
            'latitude' => $driverRequest->latitude,
            'longitude' => $driverRequest->longitude
        ]);
    }
    
    private function cancelRequest($currentRequest)
    {
        if (!$currentRequest) {
            return response()->json(['error' => 'No active request found'], 404);
        }

        if ($currentRequest->status !== 'pending') {
            return response()->json(['error' => 'Can only cancel pending requests'], 400);
        }

        $currentRequest->update(['status' => 'cancelled']);

        return response()->json(['message' => 'Request cancelled successfully']);
    }

    private function completeRide($currentRequest)
    {
        if (!$currentRequest || $currentRequest->status !== 'locked') {
            return response()->json(['error' => 'No locked request found'], 404);
        }

        $currentRequest->update(['status' => 'completed']);

        return response()->json(['message' => 'Ride completed successfully']);
    }

    private function updateRequest(Request $request, $currentRequest)
    {
        if (!$currentRequest || $currentRequest->status !== 'pending') {
            return response()->json(['error' => 'Can only update pending requests'], 400);
        }

        $validated = $request->validate([
            'from' => 'string',
            'destination' => 'string',
            'material_type' => 'string',
            'car_type' => 'string',
            'latitude' => 'string',
            'longitude' => 'string',
        ]);

        // Update only provided fields
        $currentRequest->update(array_filter($validated));

        return response()->json([
            'message' => 'Request updated successfully',
            'request' => $currentRequest->fresh(),
            'next_actions' => RequestStatus::getNextActions($currentRequest->status)
        ]);
    }

    public function getOrder(Request $request)
    {

        $orders = user_Request::where('user_id', $this->user->uid)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($order) {

                $driver = Driver::where("uid", $order->locked_driver_id)->first();

                return [
                    'order_id' => $order->id,
                    'status' => $order->status,
                    'from' => $order->from,
                    'destination' => $order->destination,
                    'material_type' => $order->material_type,
                    'is_online' => $driver->is_online,
                    'name' => $driver->first_name . " " . $driver->last_name,
                    'created_at' => $order->created_at,
                    'updated_at' => $order->updated_at,
                ];
            });

        if ($orders->isEmpty()) {
            return response()->json(['error' => 'No orders found for this client'], 404);
        }

        return response()->json(['orders' => $orders]);
    }

}





// canleation place 