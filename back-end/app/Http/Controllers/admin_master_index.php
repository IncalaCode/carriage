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
}