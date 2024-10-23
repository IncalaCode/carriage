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
            'currentEmail' => 'required|email',
            'currentpassword' => 'required|string|min:8',
            'newEmail' => 'required|email',
            'newpassword' => 'required|string|min:8|confirmed', // confirmed checks for password_confirmation field
        ]);

        if ($validator->fails()) {
            return redirect()->back()->withErrors($validator)->withInput();
        }

        // Get the current admin from the session
        $admin = Admin::find(session('admin_id'));

        if (!$admin) {
            return redirect()->back()->with('message', 'Admin not found');
        }

        // Update the email and password
        $admin->email = $request->newEmail;
        $admin->password = Hash::make($request->newpassword);
        $admin->save();

        return redirect()->back()->with('message', 'Admin updated successfully');
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
}
