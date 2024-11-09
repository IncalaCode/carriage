<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Auth;
use Carbon\Carbon;
use App\Models\Wallet;

require_once "otp.php";


class AuthController extends Controller
{
    // Handle registration logic
    public function register(Request $request)
    {
        // Validate the request data
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone_number' => 'required|string|regex:/^\+251[0-9]{9}$/|unique:users,phone_number',
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

        $user = User::where('phone_number', $request->phone_number)->first();

        Wallet::create([
            'user_id' => $user->uid,
            'balance' => 0.00, // Initial balance
        ]);

        // Send OTP using otpSend
        $response  = otpSend($user->phone_number, "Your OTP is: " .  $otp);


        return response()->json([
            'message' => 'OTP sent successfully!',
            'otp_response' => $response,
        ], 200);
    }

    // New login method that sends OTP
    public function login(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' =>  'required|string|regex:/^\+251[0-9]{9}$/', // Adjust the digits as per your requirements
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()], 422);
        }

        // Find the driver by phone number
        $user = User::where('phone_number', $request->phone_number)->first();

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Generate and send OTP
        $otp = rand(1000, 9999); // 4-digit OTP
        $user->otp = $otp;
        $user->save();

        // Send OTP using the same otpSend function as for users
        $response = otpSend($user->phone_number, "Your OTP is: " . $otp);

        return response()->json([
            'message' => 'OTP sent successfully!',
            'otp_response' => $response,
        ], 200);
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

        $otp = $request->otp;

        // Check if the provided OTP matches the stored OTP
        if ($user->otp !==  $otp) {
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
    public function userResendOtp(Request $request)
    {
        // Validate the phone number
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|digits_between:1,14',
        ]);

        if ($validator->fails()) {
            return response()->json(['error' => $validator->errors()], 422);
        }

        // Find the user by phone number
        $user = User::where('phone_number', $request->phone_number)->first();

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Throttling: Check the last OTP sent time
        $lastOtpSent = Carbon::parse($user->updated_at);
        $now = Carbon::now();
        $resendDelay = 60; // Set the delay in seconds before allowing another OTP to be sent

        if ($lastOtpSent->diffInSeconds($now) < $resendDelay) {
            return response()->json([
                'error' => 'Please wait before resending OTP.',
            ], 429); // Too Many Requests status
        }

        // Generate a new OTP
        $otp = rand(1000, 9999); // 4-digit OTP
        $user->otp = $otp;
        $user->save();

        // Send the new OTP
        $response = otpSend($user->phone_number, "Your new OTP is: " . $otp);

        return response()->json([
            'message' => 'OTP resent successfully!',
            'otp_response' => $response,
        ], 200);
    }
}
