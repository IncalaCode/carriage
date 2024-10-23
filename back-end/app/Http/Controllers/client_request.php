<?php

namespace App\Http\Controllers;

use App\Models\user_Request;
use App\Models\Driver;
use App\Models\User;
use App\Models\driverRequest;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;
use Carbon\Carbon;

class client_request extends Controller
{
    protected $user;

    // Authenticate the client (user) via token from the request
    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->user = User::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    // Send a ride request
    public function sendRequest(Request $request)
    {
        $validated = $request->validate([
            'from' => 'required|string',
            'destination' => 'required|string',
            'material_type' => 'required|string',
            'car_type' => 'required|string',
            'latitude' => 'required|string',
            'longitude' => 'required|string',
        ]);

        // Check for existing pending requests
        $existingRequest = user_Request::where('user_id', $this->user->id)
            ->where('status', 'pending')
            ->where('from', $validated['from'])
            ->where('destination', $validated['destination'])
            ->where('material_type', $validated['material_type'])
            ->where('car_type', $validated['car_type'])
            ->first();

        if ($existingRequest) {
            return response()->json([
                'message' => 'You already have a pending request with the same details.'
            ], Response::HTTP_BAD_REQUEST);
        }

        // Create new ride request
        $rideRequest = user_Request::create([
            'user_id' => $this->user->id,
            'from' => $validated['from'],
            'destination' => $validated['destination'],
            'material_type' => $validated['material_type'],
            'car_type' => $validated['car_type'],
            'status' => 'pending',
            'accepted_driver_ids' => json_encode([]) 
        ]);

        // Fetch matching drivers
        $matchingDrivers = driverRequest::where('car_type', $validated['car_type'])
            ->where('status', 'pending')
            ->get();

        if ($matchingDrivers->isEmpty()) {
            return response()->json([
                'message' => 'No matching drivers found. Please wait for a response.'
            ], Response::HTTP_CREATED);
        }

        // Process accepted drivers
        $acceptedDriverDetails =  $this->processAcceptedDrivers($matchingDrivers, $validated);

        // Update the ride request with accepted driver details
        if ($acceptedDriverDetails) {
            $rideRequest->update([
                'accepted_driver_ids' => json_encode(array_merge($acceptedDriverDetails,$rideRequest->accepted_user_ids ?? [] ))
            ]);
        }


        return response()->json([
            'ride_request' => $rideRequest,
            'message' => 'Please wait for drivers to respond'
        ], Response::HTTP_CREATED);
    }

    // Process accepted drivers and handle duplicates
  private function processAcceptedDrivers($matchingDrivers, $validated)
{
    $acceptedDriverDetails = [];

    foreach ($matchingDrivers as $driverRequest) {
        // Decode accepted users from driver request
        $existingAcceptedUsers = json_decode($driverRequest->accepted_user_ids ?? '[]', true);

        // Check if the user is already accepted by this driver
        $userAlreadyAccepted = array_filter($existingAcceptedUsers, function ($user) {
            return $user['user_id'] === $this->user->id;
        });

        if (empty($userAlreadyAccepted)) {
            // Add driver details to the accepted list (using driver_id as key)
            $acceptedDriverDetails[$driverRequest->driver_id] = [
                'driver_id' => $driverRequest->driver_id,
                'longitude' => $driverRequest->longitude,
                'latitude' => $driverRequest->latitude,
                'car_type' => $driverRequest->car_type,
                'status' => $driverRequest->status,
                'price' => null
            ];

            // Add user details to the driver's accepted user list
            $existingAcceptedUsers[] = [
                'user_id' => $this->user->id,
                'longitude' => $validated['longitude'],
                'latitude' => $validated['latitude'],
                'status' => 'pending'
            ];


            // Update the driver request with new accepted users
            $driverRequest->update([
                'accepted_user_ids' => json_encode($existingAcceptedUsers)
            ]);
        } else{
            
        }
    }



    return $acceptedDriverDetails;
}

    // Long polling to view driver responses
    public function getDriverResponses()
    {
        $timeout =  env("Timeout"); 
    
        $rideRequest = user_Request::where('user_id', $this->user->id)
            ->where('status', 'pending')
            ->first();
    
        if (!$rideRequest) {
            return response()->json(['message' => 'No pending ride request found'], Response::HTTP_NOT_FOUND);
        }
    
        $matchingDrivers = driverRequest::where('car_type', $rideRequest->car_type)
            ->where('status', 'pending')
            ->get();
    
        // Process accepted drivers again to check for any late responses
        $acceptedDriverDetails = $this->processAcceptedDrivers($matchingDrivers, $rideRequest);
    
        if ($acceptedDriverDetails) {
            $rideRequest->update([
                'accepted_driver_ids' => json_encode(array_merge($acceptedDriverDetails,$rideRequest->accepted_user_ids ?? [] ))
            ]);
        }
    
        while ($timeout) {
            $acceptedDrivers = json_decode($rideRequest->accepted_driver_ids, true) ?? [];
    
            $driversWithPrice = array_filter($acceptedDrivers, fn($driver) => isset($driver['price']));
    
            if (!empty($driversWithPrice)) {
                return response()->json([
                    'accepted_drivers' => $driversWithPrice,
                    'message' => 'You have received responses from drivers.'
                ]);
            }

            $timeout --;
            usleep(500000); // Sleep for 0.5 seconds to reduce CPU usage
        }
    
        return response()->json(['message' => 'No responses yet from the drivers'], 201);
    }
    
    // Confirm driver selection and lock the driver
    public function confirmDriver(Request $request)
{
    $validated = $request->validate([
        'driver_id' => 'required|integer'
    ]);

    // Fetch the ride request for the current user
    $rideRequest = user_Request::where('user_id', $this->user->id)
        ->where('status', 'pending')
        ->first();

    if (!$rideRequest) {
        return response()->json(['error' => 'No pending request found'], 400);
    }

    // Fetch the driver's request entry
    $driverRequest = driverRequest::where('driver_id', $validated['driver_id'])
        ->where('status', 'pending')
        ->first();

    if (!$driverRequest) {
        return response()->json(['error' => 'No matching driver found'], Response::HTTP_NOT_FOUND);
    }

    // Update the status to 'locked' in user's accepted_driver_ids
    $acceptedDrivers = json_decode($rideRequest->accepted_driver_ids, true) ?? [];
    foreach ($acceptedDrivers as &$driver) {
        if ($driver['driver_id'] == $validated['driver_id']) {
            $driver['status'] = 'locked';
        }
    }

    $rideRequest->update([
        'locked_driver_id' => $validated['driver_id'],
        'status' => 'locked',
        'accepted_driver_ids' => json_encode($acceptedDrivers)
    ]);

    // Update the status to 'locked' in driver's accepted_user_ids
    $acceptedUsers = json_decode($driverRequest->accepted_user_ids, true) ?? [];
    foreach ($acceptedUsers as &$user) {
        if ($user['user_id'] == $this->user->id) {
            $user['status'] = 'locked';
        }
    }

    $driverRequest->update([
        'accepted_user_ids' => json_encode($acceptedUsers)
    ]);

    return response()->json(['message' => 'Driver confirmed and status locked successfully']);
}


    // Track driver's location
    public function trackDriverLocation()
    {
        $rideRequest = user_Request::where('user_id', $this->user->id)
            ->where('status', 'locked')
            ->first();

        if (!$rideRequest) {
            return response()->json(['message' => 'No locked ride found'], Response::HTTP_NOT_FOUND);
        }

        $driverRequest = driverRequest::where('driver_id', $rideRequest->locked_driver_id)->first();

        if ($driverRequest && $driverRequest->longitude && $driverRequest->latitude) {
            return response()->json([
                'latitude' => $driverRequest->latitude,
                'longitude' => $driverRequest->longitude
            ]);
        }

        return response()->json(["status" => false],200);
    }

    // Mark the ride as completed
    public function completeRide()
    {
        $rideRequest = user_Request::where('user_id', $this->user->id)
            ->where('status', 'locked')
            ->first();

        if (!$rideRequest) {
            return response()->json(['message' => 'No locked ride found'], Response::HTTP_NOT_FOUND);
        }

        $rideRequest->update(['status' => 'completed']);

        return response()->json(['message' => 'Ride completed successfully']);
    }



    // canleation place 
    public function cancelRequest()
    {
        $rideRequest = user_Request::where('user_id', $this->user->id)
            ->where('status', 'pending')
            ->first();
    
        if (!$rideRequest) {
            return response()->json(['message' => 'No pending ride request found'], Response::HTTP_NOT_FOUND);
        }
    
        // Mark ride request as cancelled
        $rideRequest->update(['status' => 'cancelled']);
    
        // Update status in accepted_driver_ids to 'cancelled'
        $this->updateDriverStatusInUserRequest($rideRequest, 'cancelled');
    
        return response()->json(['message' => 'Ride request cancelled successfully']);
    }
    
    public function cancelLockedRequest()
    {
        $rideRequest = user_Request::where('user_id', $this->user->id)
            ->where('status', 'locked')
            ->first();
    
        if (!$rideRequest) {
            return response()->json(['message' => 'No locked ride found'], Response::HTTP_NOT_FOUND);
        }
    
        // Mark ride request as cancelled
        $rideRequest->update(['status' => 'cancelled']);
    
        // Update status in accepted_driver_ids to 'cancelled'
        $this->updateDriverStatusInUserRequest($rideRequest, 'cancelled');
    
        return response()->json(['message' => 'Locked ride cancelled successfully']);
    }
    
    // Helper function to update driver status in user request
    private function updateDriverStatusInUserRequest($rideRequest, $newStatus)
    {
        $acceptedDrivers = json_decode($rideRequest->accepted_driver_ids ?? '[]', true);
    
        // Update the status of all accepted drivers to the new status
        foreach ($acceptedDrivers as &$driver) {
            $driver['status'] = $newStatus;
    
            // Also update the driver's request status if it exists
            $this->updateUserStatusInDriverRequest($driver['driver_id'], $this->user->id, $newStatus);
        }
    
        $rideRequest->update([
            'accepted_driver_ids' => json_encode($acceptedDrivers)
        ]);
    }
    
    // Helper function to update user status in driver's request
    private function updateUserStatusInDriverRequest($driverId, $userId, $newStatus)
    {
        $driverRequest = driverRequest::where('driver_id', $driverId)
            ->where('status', 'pending')
            ->first();
    
        if ($driverRequest) {
            $acceptedUsers = json_decode($driverRequest->accepted_user_ids ?? '[]', true);
    
            // Update the status of the specific user
            foreach ($acceptedUsers as &$user) {
                if ($user['user_id'] === $userId) {
                    $user['status'] = $newStatus;
                }
            }
    
            $driverRequest->update([
                'accepted_user_ids' => json_encode($acceptedUsers)
            ]);
        }
    }
    



}


// canleation place 
