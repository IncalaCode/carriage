<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

require "otp.php";

class AuthController extends Controller
{
    // Handle registration logic
    public function register(Request $request)
    {
        // Validate the request data
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone_number' => 'required|digits_between:1,14|unique:users,phone_number',
            'password' => 'required|string|min:8|confirmed', // password_confirmation field should be present
        ]);

        // Return validation errors if any
        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        $otp = rand(1000, 9999); // Adjusted OTP to 4 digits

        // Create new user if validation passes
        $user = User::create([
            'first_name' => $request->first_name,
            'last_name' => $request->last_name,
            'phone_number' => $request->phone_number,
            'password' => Hash::make($request->password),
            'verified' => false, // Set verified to false initially
            'otp' => $otp, // Store the OTP in the user record
        ]);

        // Send OTP using otpSend
        $response = otpSend($user->phone_number, "Your OTP is: ", $otp, $user->id);

        // Return success response
        return response()->json([
            'message' => 'User registered successfully',
            'otp_response' => json_encode($response, true),
        ], 201);
    }
    
    // New login method that sends OTP
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|exists:users,phone_number',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get the user using the provided phone number
        $user = User::where('phone_number', $request->phone_number)->first();

        if (!$user) {
            return response()->json([
                'message' => 'User not found',
            ], 404);
        }

        // Generate OTP
        $otp = rand(1000, 9999); // Adjusted OTP to 4 digits

        // Send OTP using otpSend
        $response = otpSend($user->phone_number, "Your OTP is: ", $otp, $user->id);

        if($response['status'] == "success"){
        $user->otp = $otp; // Update the OTP in the user record
        $user->save();
        }

        return response()->json([
            'message' => 'user found wiating for otp',
            'otp_response' => json_encode($response, true),
        ], 201);
    }

    // Verify OTP and update the user's verified status
    public function verifyOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|exists:users,phone_number',
            'otp' => 'required|digits:4',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Get the user using the provided phone number
        
        $user = User::where('phone_number', $request->phone_number)->first();

        $otp = substr($request->otp, -4);

        // Check if the provided OTP matches the stored OTP
        if ($user->otp !==  $otp ) {
            return response()->json([
                'message' => 'Invalid OTP',
            ], 401);
        }

        // Update the verified status and clear the OTP
        $user->verified = true;
        $user->otp = null; // Clear the OTP after verification
        $user->save();

        return response()->json([
            'message' => 'OTP verified successfully',
            'user' => $user,
        ], 200);
    }
}