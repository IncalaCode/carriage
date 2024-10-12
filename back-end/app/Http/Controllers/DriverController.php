<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class DriverController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:drivers',
            'phone' => 'required',
            'driver_id' => 'required|string|max:255',
            'id_card_image' => 'required|image|max:2048',
            'password' => 'required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Handle file upload for ID card
        $idCardPath = $request->file('id_card_image')->store('id_cards', 'public');

        $driver = Driver::create([
            'first_name' => $request->first_name,
            'last_name' => $request->last_name,
            'email' => $request->email,
            'phone' => $request->phone,
            'driver_id' => $request->driver_id,
            'password' => Hash::make($request->password),
            'id_card_image_path' => $idCardPath,
            'verified' => false, // Initially set verified to false
            'otp' => rand(1000, 9999), // Store the OTP
        ]);

        // Call the otpSend function
         $response = otpSend($driver->phone, $driver->otp, "example.com", $driver->id);

        // Return success response
        if ($response['status']  === 'success') {
            return response()->json([
                'message' => 'OTP sent successfully!',
                'otp_response' => json_decode($response, true),
            ], 200);
        } else {
            return response()->json([
                'message' => 'Failed to send OTP',
                'otp_response' => json_decode($response, true),
            ], 500);
        }
    }

    // New login method that sends OTP
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone' => 'required|exists:drivers,phone',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get the driver using the provided phone number
        $driver = Driver::where('phone', $request->phone)->first();

        if (!$driver) {
            return response()->json([
                'message' => 'User not found',
            ], 404);
        }

        // Generate a new OTP
        $otp = rand(1000, 9999);
        $driver->otp = $otp; // Update the OTP in the driver record
        $driver->save();

        // Send OTP using otpSend
        [$status, $response] = otpSend($driver->phone, $otp, "example.com", $driver->id);

        if ($status === 200) {
            return response()->json([
                'message' => 'OTP sent successfully!',
                'otp_response' => json_decode($response, true),
            ], 200);
        } else {
            return response()->json([
                'message' => 'Failed to send OTP',
                'otp_response' => json_decode($response, true),
            ], 500);
        }
    }

    // Verify OTP and update the driver's verified status
    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|exists:drivers,phone',
            'otp' => 'required|digits:4',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get the driver using the provided phone number
        $driver = Driver::where('phone', $request->phone)->first();

        // Check if the provided OTP matches the stored OTP
        if ($driver->otp !== $request->otp) {
            return response()->json([
                'message' => 'Invalid OTP',
            ], 401);
        }

        // Update the verified status and clear the OTP
        $driver->verified = true;
        $driver->otp = null; // Clear the OTP after verification
        $driver->save();

        return response()->json([
            'message' => 'OTP verified successfully',
            'user' => $driver,
        ], 200);
    }

    // app/Http/Controllers/DriverController.php
    public function showDrivers()
    {
        $drivers = Driver::paginate(10); // Fetch 10 drivers per page
        return view('admin.drivers', compact('drivers'));
    }

    public function addDriver(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|email|unique:drivers',
            'phone' => 'required',
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator);
        }

        Driver::create($request->all());
        return redirect()->back()->with('success', 'Driver added successfully.');
    }


}