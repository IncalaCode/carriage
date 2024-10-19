<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Carbon\Carbon;

require "otp.php";


class DriverController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone_number' =>'required|string|min:1|max:15|unique:drivers,phone_number',
            'driver_id' => 'required|string|max:255',
            'id_card_image' => 'required|image|max:2048',
            'password' => 'required|string|min:8|confirmed',
            'car_type' => 'required|string|max:255',
            'driver_license_photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            'car_plate_photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
            'user_photo' => 'required|image|mimes:jpeg,png,jpg|max:2048',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Handle file upload for ID card
        $idCardPath = $request->file('id_card_image')->store('id_cards', 'public');
        $driver_license_photo = $request->file('driver_license_photo')->store('driver_photos', 'public');
        $car_plate_photo = $request->file('car_plate_photo')->store('driver_photos', 'public');
        $user_photo = $request->file('user_photo')->store('driver_photos', 'public');

        $driver = Driver::create([
            'first_name' => $request->first_name,
            'last_name' => $request->last_name,
            'email' => $request->email,
            'phone_number' => $request->phone_number,
            'driver_id' => $request->driver_id,
            'password' => Hash::make($request->password),
            'id_card_image_path' => $idCardPath,
            'car_type' => $request->car_type,
            'driver_license_photo' => $driver_license_photo,
            'car_plate_photo' => $car_plate_photo,
            'user_photo' => $user_photo,
            'verified' => false, // Initially set verified to false
            'otp' => rand(1000, 9999), // Store the OTP
        ]);

        // Call the otpSend function
        $response = otpSend($driver->phone, $driver->otp, "example.com", $driver->id);

        // Return success response
        return response()->json([
            'message' => 'OTP sent successfully!',
            'otp_response' => json_decode($response, true),
        ], 200);
    }

    // New login method that sends OTP
    // use Illuminate\Support\Facades\Hash; // Make sure to import Hash facade
    // use Illuminate\Http\Request;

    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|digits_between:1,14', // Adjust the digits as per your requirements
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()], 422);
        }

        // Find the driver by phone number
        $driver = Driver::where('phone_number', $request->phone_number)->first();

        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }

        // Generate and send OTP
        $otp = rand(1000, 9999); // 4-digit OTP
        $driver->otp = $otp;
        $driver->save();

        // Send OTP using the same otpSend function as for users
        $response = otpSend($driver->phone_number, "Your OTP is: ", $otp, $driver->id);

        return response()->json([
            'message' => 'OTP sent successfully!',
            'otp_response' => $response,
        ], 200);
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
    public function driverResendOtp(Request $request)
    {
        // Validate the phone number
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|digits_between:1,14',
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()], 422);
        }

        // Find the driver by phone number
        $driver = Driver::where('phone_number', $request->phone_number)->first();

        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }

        // Check if we can send a new OTP (you can add a throttling mechanism)
        $lastOtpSent = Carbon::parse($driver->updated_at); // Assuming `updated_at` changes after OTP is sent
        $now = Carbon::now();
        $resendDelay = 60; // Set the delay in seconds before allowing another OTP to be sent

        if ($lastOtpSent->diffInSeconds($now) < $resendDelay) {
            return response()->json([
                'error' => 'Please wait before resending OTP.',
            ], 429); // Too Many Requests status
        }

        // Generate a new OTP
        $otp = rand(1000, 9999); // 4-digit OTP
        $driver->otp = $otp;
        $driver->save();

        // Send the new OTP
        $response = otpSend($driver->phone_number, "Your new OTP is: ", $otp, $driver->id);

        return response()->json([
            'message' => 'OTP resent successfully!',
            'otp_response' => $response,
        ], 200);
    }
}
