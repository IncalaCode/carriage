<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;

class admin_master_index extends Controller
{
    /**
     * Constructor: Apply session check for all methods in this controller.
     */
    public function __construct()
    {
        if (!session()->has('admin_id')) {
            // Redirect to login if admin is not authenticated
            redirect()->route('admin.login')->with('message', 'Please log in first.')->send();
            exit;  // Stop further execution
        }
    }

    public function driverPage()
    {
        $drivers = Driver::paginate(10);
        return view('admin.drivers', compact('drivers'));
    }

    public function settingsPage()
    {
        return view('admin.settings');
    }

    public function userPage()
    {
        return view('admin.user');
    }

    public function toggleStatus($id, Request $request)
    {
        $request->validate(['status' => 'required|boolean']);
        $driver = Driver::findOrFail($id);
        $driver->verified = $request->status;

        if ($driver->save()) {
            return response()->json(['success' => true]);
        }

        return response()->json(['success' => false], 500);
    }
}