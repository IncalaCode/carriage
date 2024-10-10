<?php
namespace App\Http\Controllers;

use App\Models\Admin;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class AdminAuthController extends Controller
{
    // Admin Login
    public function adminLogin(Request $request)
    {
        // Validate the request data
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'required|string',
        ]);

        // Return validation errors if any
        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        // Find the admin by email
        $admin = Admin::where('email', $request->email)->first();

        // Check if admin exists and password is correct
        if (!$admin || !Hash::check($request->password, $admin->password)) {
            return response()->json([
                'message' => 'Invalid credentials',
            ], 401);
        }

        // Store admin ID in session
        session(['admin_id' => $admin->id]);

        return response()->json([
            'message' => 'Admin logged in successfully',
            'admin' => $admin,
        ], 200);
    }

    // Admin Logout
    public function adminLogout()
    {
        session()->forget('admin_id');

        return response()->json([
            'message' => 'Admin logged out successfully',
        ], 200);
    }

    // Update Admin Details
    public function updateAdmin(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'email' => 'required|email',
            'password' => 'sometimes|required|string|min:8|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'errors' => $validator->errors(),
            ], 422);
        }

        $admin = Admin::find(session('admin_id'));

        if (!$admin) {
            return response()->json([
                'message' => 'Admin not found',
            ], 404);
        }

        // Update email
        $admin->email = $request->email;

        // Update password if provided
        if ($request->filled('password')) {
            $admin->password = Hash::make($request->password);
        }

        $admin->save();

        return response()->json([
            'message' => 'Admin updated successfully',
            'admin' => $admin,
        ], 200);
    }
}