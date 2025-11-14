<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use App\Models\Driver;


class AdminAuthController extends Controller
{
    // Admin Login
    public function login(Request $request)
    {
        // Validate the request data
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string|min:8',
        ]);

        if ($validator->fails()) {
            return redirect()->route('admin.login')->withErrors($validator)->withInput();
        }

        $admin = Admin::where('email', $request->email)->first();

        if (!$admin || !Hash::check($request->password, $admin->password)) {
            return redirect()->route('admin.login')->withErrors(['email' => 'Invalid credentials'])->withInput();
        }

        session(['admin_id' => $admin->id]);

        // Redirect to admin dashboard upon successful login
        return redirect('/admin/dashboard')->with('id', $admin->id);
    }

    // Admin Logout
    public function logout()
    {
        session()->forget('admin_id');

        return redirect()->route('admin.login')->with('message', 'Logged out successfully');
    }

    public function updateAdmin(Request $request)
    {
        // Validate the form input
        $validator = Validator::make($request->all(), [
            'currentPassword' => 'required|string|min:8',
            'email' => 'required|email',
            'newPassword' => 'required|string|min:8', // confirmed checks for password_confirmation field
        ]);
    
        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }
    
        // Get the current admin from the session
        $admin = Admin::find(session('admin_id'));
    
        if (!$admin) {
            return response()->json(['message' => "Admin not found"], 400);
        }
    
        // Verify the current password
        if (!Hash::check($request->currentPassword, $admin->password)) {
            return response()->json([
                'message' => "Current password is incorrect",
            ], 401);
        }
    
        // Update the admin's password and email
        $admin->update([
            'password' => Hash::make($request->newPassword),
            'email' => $request->email,
        ]);
    
        return response()->json(['message' => "Admin updated successfully", "success" => true], 200);
    }
    

    public function showUnapprovedDrivers()
    {
        // Get drivers who are not approved
        $unapprovedDrivers = Driver::where('approved', false)->get();

        return view('admin.unapproved_drivers', compact('unapprovedDrivers'));
    }

    public function approveDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $driver->approved = true;
        $driver->save();

        return redirect()->route('admin.drivers')->with('success', 'Driver approved successfully!');
    }


    public function rejectDriver($id)
    {
        $driver = Driver::findOrFail($id);
        $driver->delete(); // or handle rejection logic as you see fit

        return redirect()->back()->with('message', 'Driver rejected successfully!');
    }
    public function showDriverDetails($id)
    {
        $driver = Driver::findOrFail($id);
        return view('admin.driver_details', compact('driver'));
    }

    public function getDashboardData()
    {
        // Count unapproved drivers
        $unapprovedDriversCount = Driver::where('approved', 0)->count();

        // Pass this count to the view
        return view('admin.dashboard', compact('unapprovedDriversCount'));
    }
}
