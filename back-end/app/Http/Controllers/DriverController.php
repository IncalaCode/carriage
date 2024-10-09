<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;

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
        ]);

        $token = $driver->createToken('auth_token')->plainTextToken;

        // Generate OTP
        $otp = rand(1000, 9999);
        $domain = "example.com"; // Replace with your domain
        $driverId = $driver->id;

        // Call the otpSend function
        [$status, $response] = otpSend($driver->phone, $otp, $domain, $driverId);

        if ($status === 200) {
            // OTP sent successfully
            return response()->json([
                'message' => 'User registered successfully, OTP sent!',
                'token' => $token,
                'user' => $driver,
                'otp_response' => json_decode($response, true),
            ], status: 201);
        } else {
            // OTP sending failed
            return response()->json([
                'message' => 'User registered, but OTP sending failed',
                'token' => $token,
                'user' => $driver,
                'otp_response' => json_decode($response, true),
            ], 201);
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
 
         // Generate OTP
         $otp = rand(1000, 9999);
         $domain = "example.com"; // Replace with your domain
         $driverId = $driver->id;
 
         // Send OTP using otpSend
         [$status, $response] = otpSend($driver->phone, $otp, $domain, $driverId);
 
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