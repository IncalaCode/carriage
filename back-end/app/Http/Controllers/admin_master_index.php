<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;

class admin_master_index extends Controller
{
    public function driverPage()
    {
        // Fetch drivers with pagination
        $drivers = Driver::paginate(10);

        // Return the admin.drivers view with the data
        return view('admin.drivers', compact('drivers'));
    }

    public function settingsPage()
    {
        return view('admin.settings');
    }
    public function userpage()
    {
        return view("admin.user");
    }


    // for the activate and disactive 
    public function toggleStatus($id, Request $request)
{
    $driver = Driver::findOrFail($id);
    $driver->status = $request->status;
    if ($driver->save()) {
        return response()->json(['success' => true]);
    }
    return response()->json(['success' => false], 500);
}

}