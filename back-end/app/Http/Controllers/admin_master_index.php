<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Driver;
use App\Models\User;
use App\Models\Transaction;

use function PHPUnit\Framework\isEmpty;

class admin_master_index extends Controller
{
    /**
     * Constructor: Apply session check for all methods in this controller.
     */
    public function __construct()
    {
        if (!session()->has('admin_id')) {
            redirect()->route('admin.login')->with('message', 'Please log in first.')->send();
            exit;
        }
    }

    /**
     * Display drivers page with search and pagination functionality.
     */
    public function dashboardPage()
    {
        // Fetch counts
        $totalUsers = User::count();
        $totalDrivers = Driver::count();
        $totalTransactions = Transaction::count();
        $referralDrivers = Driver::whereNotNull('referral_count')->sum('referral_count');


        // Fetch monthly registrations
        $userMonthlyRegistrations = User::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
            ->groupBy('month')
            ->pluck('count', 'month');
        $driverMonthlyRegistrations = Driver::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
            ->groupBy('month')
            ->pluck('count', 'month');

        return view('admin.dashboard', compact(
            'totalUsers',
            'totalDrivers',
            'totalTransactions',
            'referralDrivers',
            'userMonthlyRegistrations',
            'driverMonthlyRegistrations'
        ));
    }
    public function driverPage(Request $request)
    {
        $query = Driver::query();

        // Search functionality - Trigger search if query length is > 2
        if ($query != "") {
            $search = $request->get('search');
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%$search%")
                    ->orWhere('last_name', 'like', "%$search%")
                    ->orWhere('phone_number', 'like', "%$search%");
            });
        }



        // Paginate the results
        $drivers = $query->paginate(2);

        // Check if request is AJAX for returning JSON
        if ($request->ajax() && $query != "" && isEmpty($query)) {
            return response()->json([
                'data' => $drivers->items(),  // Actual data (drivers)
            ]);
        }


        // For non-AJAX requests, return the view with drivers
        return view('admin.drivers', compact('drivers'));
    }

    public function settingsPage()
    {
        return view('admin.settings');
    }

    public function userPage(Request $request)
    {
        $query = User::query();

        // Search functionality - Trigger search if query length is > 2
        if ($query != "") {
            $search = $request->get('search');
            $query->where(function ($q) use ($search) {
                $q->where('first_name', 'like', "%$search%")
                    ->orWhere('last_name', 'like', "%$search%")
                    ->orWhere('phone_number', 'like', "%$search%");
            });
        }



        // Paginate the results
        $users = $query->paginate(2);

        // Check if request is AJAX for returning JSON
        if ($request->ajax() && $query != "" && isEmpty($query)) {
            return response()->json([
                'data' => $users->items(),  // Actual data (drivers)
            ]);
        }


        // For non-AJAX requests, return the view with drivers
        return view('admin.users', compact('users'));
    }
    /**
     * Toggle the status of a driver (activate/deactivate).
     */
    public function toggleStatus($id, Request $request)
    {
        $request->validate(['status' => 'required|boolean']);
        $driver = Driver::findOrFail($id);
        $driver->status = $request->status;

        if ($driver->save()) {
            return response()->json(['success' => true]);
        }

        return response()->json(['success' => false], 500);
    }


    public function toggleUserStatus($id, Request $request)
    {
        $request->validate(['status' => 'required|boolean']);
        $user = User::findOrFail($id);
        $user->status = $request->status;

        if ($user->save()) {
            return response()->json(['success' => true]);
        }

        return response()->json(['success' => false], 500);
    }
}
