<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;
use App\Models\User;
use App\Models\CacheReferral;
use App\Models\UserDeposit;
use Illuminate\Support\Facades\Cache;


class ReferralController extends Controller
{
    public function generateReferralLink($driverId)
    {
        $driver = Driver::findOrFail($driverId);
        $referralLink = url('/referral?ref=' . $driver->id);

        return response()->json(['referral_link' => $referralLink]);
    }
    public function referralLandingPage(Request $request)
    {
        $driverId = $request->query('ref');
        return view('referral_landing', compact('driverId'));
    }

    // Store cached referral in controller
    public function cacheReferral(Request $request)
    {
        $validated = $request->validate([
            'phone' => 'required|numeric|unique:users,phone',
            'referrer_id' => 'required|exists:drivers,id'
        ]);

        // Check if phone is already registered
        if (User::where('phone', $validated['phone'])->exists()) {
            return response()->json(['message' => 'Phone number already registered'], 400);
        }

        // Store the referral in cache for 1 day
        Cache::put("referral_{$validated['phone']}", $validated['referrer_id'], now()->addDay());


        // Redirect to Play Store
        return response()->json(['redirect_url' => 'https://play.google.com/store/apps/details?id=com.yourapp']);
    }



    public function lockRequest($driverId, $userId)
    {
        $driver = Driver::findOrFail($driverId);
        $userDepositAmount = 1500;

        // Check if the driver is eligible for the referral reward
        if ($driver->referral_count >= 10 && $driver->referral_jobs_remaining > 0) {
            // Reward: Give 50% of the user's payment (750 ETB) to the driver
            $driverReward = 750;
            $appOwnerShare = $userDepositAmount - $driverReward; // Remaining 750 ETB to app owners

            // Record the driver’s reward
            UserDeposit::create([
                'user_id' => $driverId, // Assuming UserDeposit can also log driver earnings
                'amount' => $driverReward,
                'status' => 'completed',
                'transaction_type' => 'reward' // Use 'reward' to indicate a referral reward
            ]);

            // Record app owner's share, if needed
            UserDeposit::create([
                'user_id' => null, // or use a specific app owner ID if applicable
                'amount' => $appOwnerShare,
                'status' => 'completed',
                'transaction_type' => 'app_income'
            ]);

            // Decrease the driver’s remaining referral reward count
            $driver->decrement('referral_jobs_remaining');
        } else {
            // If the driver is not eligible, all goes to app owner
            UserDeposit::create([
                'user_id' => null, // or app owner's ID if needed
                'amount' => $userDepositAmount,
                'status' => 'completed',
                'transaction_type' => 'app_income'
            ]);
        }
    }
}
