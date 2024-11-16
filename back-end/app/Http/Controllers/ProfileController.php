<?php

namespace App\Http\Controllers;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Hash;

class ProfileController extends Controller
{
    // Method to show the user profile
    public function show(Request $request)
    {
        $value = $request->input("token");

        $user = User::where('uid', $value)->first();
        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        return response()->json([
            'first_name' => $user->first_name,
            'last_name' => $user->last_name,
            'phone_number' => $user->phone_number,
            'status' => $user->status,
            'profile_picture' => $user->profile_picture,
        ]);
    }

     // Method to update user profile information
     public function update(Request $request)
{
    $validator = Validator::make($request->all(), [
        'user_id' => 'required|exists:users,id',
        'first_name' => 'sometimes|string|max:255',
        'last_name' => 'sometimes|string|max:255',
        'phone_number' => 'sometimes|string|max:15',
        'profile_picture' => 'nullable|image|mimes:jpeg,png,jpg|max:2048',
    ]);

    if ($validator->fails()) {
        return response()->json(['errors' => $validator->errors()], 422);
    }

    $user = User::find($request->user_id);

    if (!$user) {
        return response()->json(['error' => 'User not found'], 404);
    }

    // Update name fields directly if they are present
    if ($request->has('first_name')) {
        $user->first_name = $request->first_name;
    }
    if ($request->has('last_name')) {
        $user->last_name = $request->last_name;
    }

    // Check if the phone number is being changed
    if ($request->has('phone_number') && $request->phone_number !== $user->phone_number) {
        // Generate OTP for phone number verification
        $otp = rand(100000, 999999);
        $user->otp_code = Hash::make($otp);
        $user->otp_expires_at = now()->addMinutes(5);
        $user->save();

        // Send OTP to the user's new phone number
        // Return OTP in response for testing; use SMS API in production
        return response()->json([
            'message' => 'Phone number change detected. OTP sent for verification.',
            'otp' => $otp
        ]);
    }

    // Update profile picture if uploaded
    if ($request->hasFile('profile_picture')) {
        $file = $request->file('profile_picture');
        $path = $file->store('profile_pictures', 'public');
        $user->profile_picture = $path;
    }

    $user->save();

    return response()->json(['message' => 'Profile updated successfully']);
}

      // Method to send OTP to the user's phone number
    public function sendOtp(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'phone_number' => 'required|string|max:15',
        ]);

        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }

        $user = User::where('phone_number', $request->phone_number)->first();

        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }

        // Generate OTP
        $otp = rand(100000, 999999);
        $user->otp = Hash::make($otp);
        $user->save();

        // Send OTP via SMS or other services (e.g., Twilio)
        // For this example, we’ll just return it in the response (not secure in production)
        return response()->json(['message' => 'OTP sent successfully', 'otp' => $otp]);
    }

    public function verifyPhoneNumberChange(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'otp' => 'required|numeric',
            'new_phone_number' => 'required|string|max:15',  // Add this to indicate the new phone number
        ]);
    
        if ($validator->fails()) {
            return response()->json(['errors' => $validator->errors()], 422);
        }
    
        $user = User::find($request->user_id);
    
        if (!$user) {
            return response()->json(['error' => 'User not found'], 404);
        }
    
        // if (now()->greaterThan($user->otp_expires_at)) {
        //     return response()->json(['error' => 'OTP expired'], 403);
        // }
    
        if (!Hash::check($request->otp, $user->otp)) {
            return response()->json(['error' => 'Invalid OTP'], 403);
        }
    
        // OTP verified successfully; update phone number
        $user->phone_number = $request->new_phone_number;
        $user->otp = null;
        // $user->otp_expires_at = null;
        $user->save();
    
        return response()->json(['message' => 'Phone number updated successfully']);
    }
    
}
