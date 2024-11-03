<?php

namespace App\Http\Controllers;

use App\Models\Driver;
use App\Models\user_Request;
use App\Models\driverRequest;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Carbon\Carbon;

class driver_request extends Controller
{
    protected $user;

    // Constructor to authenticate the driver using a token
    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->user = Driver::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    // Long polling to fetch new ride requests
    public function getRequest(Request $request)
    {

        $validated = $request->validate([
            'latitude' => 'required|string',
            'longitude' => 'required|string',

        ]);

        $timeout =  env("Timeout");  // Set timeout for long polling
        $startTime = Carbon::now();

        // Check if the driver has any pending or completed ride requests
        $rideRequest = driverRequest::where('driver_id', $this->user->id)
            ->whereIn('status', ['pending', 'completed'])
            ->first();

        // If status is completed or no request exists, create a new driver request
        if (!$rideRequest || $rideRequest->status === 'completed') {
            driverRequest::create([
                'driver_id' => $this->user->id,
                'longitude' => $validated['longitude'],
                'latitude'  => $validated['latitude'],
                'car_type'  => $this->user->car_type,
                'status'    => 'pending',
            ]);
        }

        // Long polling logic
        while ( $timeout) {
            $rideRequest = DriverRequest::where('driver_id', $this->user->id)
                ->where('status', 'pending')
                ->first();

            if ($rideRequest) {
                return response()->json([$rideRequest,'message' => 'serching for the client']);
            }

            $timeout--;
            usleep(500000);  // Sleep 500ms to reduce server load
        }

        return response()->json(['message' => 'No new requests'],201);
    }

    // Long polling to get confirmation updates
    public function getConfirmation()
    {
        $timeout =  env("Timeout");


        while ($timeout) {
            $rideRequest = driverRequest::where('driver_id', $this->user->id)
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

        $driverRequest = driverRequest::where('driver_id', $this->user->id)
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
            if ($driver['driver_id'] == $this->user->id) {
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

        $rideRequest = driverRequest::where('uid', $this->user->id)->first();
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
        $driverRequest = driverRequest::where('driver_id', $this->user->id)
            ->where('status', 'pending')
            ->first();
    
        if (!$driverRequest) {
            return response()->json(['message' => 'No pending request found for this driver'], Response::HTTP_NOT_FOUND);
        }
    
        // Fetch the rider's request entry based on the user accepted by the driver
        $rideRequest = user_Request::whereJsonContains('accepted_driver_ids', ['driver_id' => $this->user->id])
            ->where('status', 'pending')
            ->first();
    
        if (!$rideRequest) {
            return response()->json(['message' => 'No matching ride request found for the user'], Response::HTTP_NOT_FOUND);
        }
    
        // Remove the user from the driver's accepted_user_ids list
        $existingAcceptedUsers = json_decode($driverRequest->accepted_user_ids ?? '[]', true);
        $updatedAcceptedUsers = array_filter($existingAcceptedUsers, function ($user) {
            return $user['user_id'] !== $this->user->id;
        });
    
        $driverRequest->update([
            'accepted_user_ids' => json_encode(array_values($updatedAcceptedUsers))
        ]);
    
        // Remove the driver from the rider's accepted_driver_ids list
        $existingAcceptedDrivers = json_decode($rideRequest->accepted_driver_ids ?? '[]', true);
        $updatedAcceptedDrivers = array_filter($existingAcceptedDrivers, function ($driver) {
            return $driver['driver_id'] !== $this->user->id;
        });
    
        $rideRequest->update([
            'accepted_driver_ids' => json_encode(array_values($updatedAcceptedDrivers))
        ]);
    
        return response()->json(['message' => 'Acceptance cancelled successfully']);
    }
    


}
