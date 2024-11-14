<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;
use Illuminate\Support\Facades\Storage; 


class DriverProfileController extends Controller
{
    public function getProfile(Request $request)
     {
       
        $value = $request->input("token");

        $driver = Driver::where('uid', $value)->first();
        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }
    
        // Generate custom referral names
        $referrals = $driver->referrals->map(function ($referral) {
            $randomNumber = rand(10000, 99999); // Generate a random number
            $referral->display_name = "user_{$randomNumber}"; // Add the custom name
            return [
                'display_name' => $referral->display_name,
                'phone_number' => $referral->phone_number,
            ];
        });

        return response()->json([
            'first_name' => $driver->first_name,
            'last_name' => $driver->last_name,
            'phone_number' => $driver->phone_number,
            'status' => $driver->verified ? 'Verified' : 'Unverified',
            'referral_code' => $this->generateReferralLink($driver->uid),
            'my_referrals_count' => $driver->referral_count,
            'my_referrals' => $referrals, // Return referrals with custom display names
        ]);
    }

    public function updateProfile(Request $request)
    {
        $request->validate([
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'phone_number' => 'required|string|max:15',
            "image" =>  'required|image|mimes:jpeg,png,jpg,gif,svg|max:2048',
        ]);

        $driver =  Driver::where('phone_number', $request->phone_number)->first();
        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }
     // If the phone number hasn't changed, update only the name fields
            $driver->first_name = $request->first_name;
            $driver->last_name = $request->last_name;

            // Handle image upload
            if ($request->hasFile('image')) {
                // Delete old image if exists
                if ($driver->image) {
                    Storage::disk('user_photo')->delete($driver->image);
                }
                
                // Store the new image
                $imagePath = $request->file('image')->store('user_photo', 'public');
                $driver->user_photo = $imagePath;
            }

            $driver->save();
        

        return response()->json([
            'status' => 'success',
            'message' => 'Profile updated successfully',
            
        ]);
    }

    public function sendOtp(Request $request)
    {
        $request->validate(['oldphone_number' => 'required', 'newphone_number' => 'required']);

        $driver = Driver::where('phone_number', $request->oldphone_number)->first();
        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }



        $otp = rand(1000, 9999);
        $driver->otp = $otp;
        $driver->phone_number = $request->newphone_number;
        $driver->verified = false;
        $driver->save();

        $response  = otpSend($driver->phone_number, "Your OTP is: " . $driver->otp);





        if ($driver->otp) {
            return response()->json([
                'status' => 'success',
                'message' => 'OTP sent successfully',
                'otp' => $response, // Only for testing; replace with SMS service in production
            ]);
        } else {
            return response()->json([
                'status' => 'error',
                'message' => 'No OTP generated for this driver',
            ], 400);
        }
    }

    public function verifyOtp(Request $request)
    {
        $request->validate(['otp' => 'required', 'newphone_number' => 'required']); // Fixed extra space after comma

        $driver = Driver::where('phone_number', $request->newphone_number)->first();
        if (!$driver) {
            return response()->json(['error' => 'Driver not found'], 404);
        }

        // Convert both to strings and trim for comparison
        $requestOtp = trim((string)$request->otp); 
        $driverOtp = trim((string)$driver->otp);

        if ($requestOtp === $driverOtp) {
            // OTP is correct; set verified to true and clear OTP
            $driver->otp = null; // Clear OTP after successful verification
            $driver->verified = true;
            $driver->save();

            return response()->json([
                'status' => 'success',
                'message' => 'OTP verified successfully'
            ]);
        }

        return response()->json([
            'status' => 'error', 
            'message' => 'Invalid OTP'
        ], 400);
    }

    public function generateReferralLink($driverId)
    {
        $driver = Driver::where("uid",$driverId);
        $referralLink = url('/referral?ref=' . $driverId);

        return  $referralLink;
    }

}
