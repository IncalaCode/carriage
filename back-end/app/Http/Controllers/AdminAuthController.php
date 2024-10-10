<?php

namespace App\Http\Controllers;

use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;


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
            'email' => 'required|email',
            'password' => 'required|string|min:8|confirmed', // confirmed checks for password_confirmation field
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
        $admin->email = $request->email;
        $admin->password = Hash::make($request->password);
        $admin->save();

        return redirect()->back()->with('message', 'Admin updated successfully');
    }

}