<?php

namespace App\Http\Controllers;

use App\Models\RideRequest;
use App\Models\DriverRequest;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class RideRequestController extends Controller
{
    public function __construct()
    {
        // $this->middleware(function ($request, $next) {
        //     $token = $request->input('token');

        //     if (!$token) {
        //         return response()->json(['error' => 'Token not found'], 401);
        //     }

        //     // Assuming you have a way to decode the token and get the user ID
        //     $user = Auth::guard('api')->user(); // Change to your authentication logic

        //     if (!$user) {
        //         return response()->json(['error' => 'Invalid token'], 401);
        //     }

        //     return $next($request);
        // });
    }

    public function requestRide(Request $request)
    {
        $validated = $request->validate([
            'from_location' => 'required|string',
            'to_location' => 'required|string',
            'material_type' => 'required|string',
            'car_type' => 'required|string',
            'token' => 'required|string',
        ]);

        // Retrieve the user from the token
        $user = Auth::guard('api')->user(); // Adjust this as per your logic
        if (!$user) {
            return response()->json(['error' => 'Invalid token'], 401);
        }

        $rideRequest = RideRequest::create([
            'user_id' => $user->id,  // Use user ID from authentication
            'from_location' => $validated['from_location'],
            'to_location' => $validated['to_location'],
            'material_type' => $validated['material_type'],
            'car_type' => $validated['car_type'],
            'status' => 'pending',
        ]);

        $drivers = DriverRequest::where('car_type', $validated['car_type'])
            ->where('status', 'pending')
            ->get();

        $availableDrivers = [];
        foreach ($drivers as $driver) {
            // Check if the ride request is already associated with the driver
            if (!$this->arrayExists($driver->ride_requests ?? [], $rideRequest->toArray())) {
                $driver->ride_requests = array_merge($driver->ride_requests ?? [], [$rideRequest->toArray()]);
                $driver->save();

                SSEController::notifyDriver($driver->driver_id, $rideRequest);
                $availableDrivers[] = $driver;
            }
        }

        if (empty($availableDrivers)) {
            return response()->json(['message' => 'No available driver found'], 404);
        }

        return response()->json([
            'message' => count($availableDrivers) . " driver(s) found that match your request. Please wait for their response.",
            'rideRequest' => $rideRequest,
        ], 201);
    }

    public function respondToRide(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required|string',
            'proposed_fare' => 'required|numeric',
            'rideRequestId' => 'required|integer|exists:ride_requests,id',
            'location' => 'required|string',
        ]);

        $rideRequest = RideRequest::findOrFail($validated['rideRequestId']);
        $driver = DriverRequest::findOrFail($validated['token']); // Adjusted to handle token appropriately

        $rideRequest->status = 'accepted';
        $rideRequest->accepted_driver_ids = array_merge(
            $rideRequest->accepted_driver_ids ?? [],
            [$driver->driver_id] // Use driver ID
        );
        $rideRequest->save();

        SSEController::notifyClient($rideRequest->user_id, $rideRequest);

        return response()->json($rideRequest);
    }

    public function requestConfirm(Request $request)
    {
        $validated = $request->validate([
            'driver_id' => 'required|exists:drivers,id',
            'rideRequestId' => 'required|exists:ride_requests,id',
        ]);

        $driverRequest = DriverRequest::findOrFail($validated['driver_id']);
        $rideRequest = RideRequest::findOrFail($validated['rideRequestId']);

        $driverRequest->status = 'pending';
        $driverRequest->save();

        SSEController::notifyClient($rideRequest->user_id,$rideRequest);
        SSEController::notifyDriver($driverRequest->driver_id,   $driverRequest);

        return response()->json(['message' => 'Ride confirmed', 'ride' => $rideRequest]);
    }

    public function lockRideRequest(Request $request)
    {
        $validated = $request->validate([
            'driver_id' => 'required|exists:drivers,id',
            'rideRequestId' => 'required|exists:ride_requests,id',
        ]);

        $driverRequest = DriverRequest::findOrFail($validated['driver_id']);
        $rideRequest = RideRequest::findOrFail($validated['rideRequestId']);

        if (in_array($driverRequest->status, ['lock', 'completed'])) {
            return response()->json(['error' => 'Ride request is already locked or completed'], 400);
        }

        $driverRequest->status = 'lock';
        $rideRequest->status = 'lock';
        $rideRequest->locked_driver_id = $validated['driver_id'];
        $driverRequest->save();
        $rideRequest->save();

        SSEController::notifyClient($rideRequest->user_id, $rideRequest);
        SSEController::notifyDriver($driverRequest->driver_id, $rideRequest);

        return response()->json(['message' => 'Ride request locked', 'ride' => $rideRequest]);
    }

    private function arrayExists(array $storedArray, array $givenArray): bool
    {
        foreach ($storedArray as $arr) {
            if ($arr == $givenArray) {
                return true;
            }
        }
        return false;
    }
}
