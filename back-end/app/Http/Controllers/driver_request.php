<?php

namespace App\Http\Controllers;

use App\Models\Driver;
use App\Models\User;
use App\Models\user_Request;
use App\Models\driverRequest;
use App\Models\RidePrice;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Carbon\Carbon;
use Illuminate\Support\Facades\Cache;

class driver_request extends Controller
{
    protected $user;
    public $previousRequests;
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
 

        // Get current driver request status
        $driverRequest = driverRequest::where('driver_id', $this->user->id)
            ->whereIn('status', ['pending', 'locked'])
            ->first();
               // Update last_active timestamp and location
        $this->updateDriverStatus($request,  $driverRequest);

        if(($request->has(['completed']) && $driverRequest) ){
            return response()->json($this->completrequest($request , $driverRequest));
        }

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

    private function updateDriverStatus(Request $request,  $driverRequest)
    {
        $this->user->update([
            'last_active' => Carbon::now(),
            'is_online' => true
        ]);

        $driverRequest->update([
            'latitude' => $request->input('latitude'),
            'longitude' => $request->input('longitude'),
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

    // Create a new driver request
    $driverRequest = driverRequest::create([
        'driver_id' => $this->user->id,
        'longitude' => $validated['longitude'],
        'latitude' => $validated['latitude'],
        'car_type' => $this->user->car_type,
        'status' => 'pending',
    ]);

    // Hide the 'id' field before returning
    return $driverRequest->makeHidden('id');
}

private function getRequests(Request $request)
{
    $timeout = self::POLLING_TIMEOUT;
    $cacheKey = 'driver_previous_requests_' . $this->user->id;

    while ($timeout > 0) {
        $requests = user_Request::where('car_type', $this->user->car_type)
            ->where('status', 'pending')
            ->get()
            ->map(function ($request) {
                $user = \App\Models\User::find($request->user_id);

                $acceptedUsers = json_decode($request->accepted_driver_ids ?? "[]") ?? []; // Get accepted driver IDs

                // Check if the current driver is in the accepted users
                $isAcceptedByDriver = in_array($this->user->id, $acceptedUsers);

                return [
                    'request_id' => $request->id,
                    'from' => $request->from,
                    'destination' => $request->destination,
                    'material_type' => $request->material_type,
                    'user' => $user ? $user->first_name . ' ' . $user->last_name : 'Unknown',
                    'is_accepted_by_driver' => $isAcceptedByDriver // Indicate if the current driver is accepted
                ];
            });

        if ($requests->isNotEmpty()) {
            $previousRequests = Cache::get($cacheKey);

            // If current requests are the same as previous ones, wait for new requests
            if ($previousRequests && $requests->toArray() === $previousRequests) {
                $timeout--;
                sleep(1);
                continue;
            }

            // Update previous requests in cache
            Cache::put($cacheKey, $requests->toArray(), now()->addMinutes(5)); // 5-minute cache duration

            return response()->json(['requests' => $requests]);
        }

        $timeout--;
        sleep(1);
    }

    return response()->json(['message' => 'No requests available','requests' => $requests]);
}


    private function acceptRide(Request $request) 
    {
        $validated = $request->validate([
            'user_request_id' => 'required',
            'price' => 'required'
        ]);

        $userRequest = user_Request::findOrFail($validated['user_request_id']);
        
        if ($userRequest->status !== 'pending') {
            return response()->json(['error' => 'Request no longer available'], 400);
        }

        // Add driver to accepted drivers list
        $acceptedDrivers = json_decode($userRequest->accepted_driver_ids ??  "") ?? [];
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

        $userRequest->accepted_driver_ids = $acceptedDrivers;
        $userRequest->save();

        return response()->json(['message' => ' Acceptance  sent  successfully']);
    }

    private function updateLocation(Request $request)
    {
        return response()->json([ "locked" => true]);
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

        if ($driverRequest && $request->has(['user_request_id', 'price'])) {
            return 'accept_ride';
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
    private function completrequest($request , $driverRequest){
        $driverRequest->update([
            "status" => "completed"
        ]);

        return ["message" => "waiting the client to confrim the completed request "];
    }

    public function getOrder(Request $request)
    {
        $orders = driverRequest::where('driver_id', $this->user->uid)
            ->orderBy('created_at', 'desc')
            ->get()
            ->map(function ($order) {
                // Fetch the user associated with the locked user ID
                $user = User::where("uid", $order->locked_user_id)->first();
                
    
                if ($user) {
                    return [
                        'order_id' => $order->id,
                        'status' => $order->status,
                        'name' => $user->first_name . " " . $user->last_name,
                        'created_at' => $order->created_at,
                        'updated_at' => $order->updated_at,
                    ];
                }
                
                return null; // If user or request not found, return null for this entry
            })
            ->filter(); // Remove null values from the collection
    
        if ($orders->isEmpty()) {
            return response()->json(['error' => 'No orders found for this client'], 404);
        }
    
        return response()->json(['orders' => $orders],200);
    }
    
}

