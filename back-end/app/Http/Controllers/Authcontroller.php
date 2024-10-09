<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

class AuthController extends Controller
{
    // Handle registration logic
    public function register(Request $request)
    {
        // Validate the request data
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone_number' => 'required|digits:10|unique:users,phone_number',
            'password' => 'required|string|min:8|confirmed', // password_confirmation field should be present
        ]);

        // Return validation errors if any
        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Create new user if validation passes
        $user = User::create([
            'first_name' => $request->first_name,
            'last_name' => $request->last_name,
            'phone_number' => $request->phone_number,
            'password' => Hash::make($request->password),
        ]);

        // Generate an auth token for the user
        $token = $user->createToken('auth_token')->plainTextToken;

        // Return success response
        return response()->json([
            'message' => 'User registered successfully',
            'token' => $token,
            'user' => $user,
        ], 201);
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
             $user = User::where('phone', $request->phone)->first();
     
             if (!$user) {
                 return response()->json([
                     'message' => 'User not found',
                 ], 404);
             }
     
             // Generate OTP
             $otp = rand(1000, 9999);
             $domain = "example.com"; // Replace with your domain
             $driverId = $user->id;
     
             // Send OTP using otpSend
             [$status, $response] = otpSend($user->phone, $otp, $domain, $driverId);
     
             if ($status === 200) {
                 // OTP sent successfully
                 return response()->json([
                     'message' => 'OTP sent successfully!',
                     'otp_response' => json_decode($response, true),
                 ], 200);
             } else {
                 // OTP sending failed
                 return response()->json([
                     'message' => 'Failed to send OTP',
                     'otp_response' => json_decode($response, true),
                 ], 500);
             }
         }
}