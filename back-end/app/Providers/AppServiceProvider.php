<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Support\Facades\View;
use Illuminate\Support\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Response;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot (Request $request)
    {
        // Make `$unapprovedDriversCount` available in the `layouts.master` view
        View::composer('layouts.master', function ($view) {
            $unapprovedDriversCount = Driver::where('approved', 0)->count();
            $view->with('unapprovedDriversCount', $unapprovedDriversCount);
        });
        view()->composer('*', function ($view) {
            $userMonthlyRegistrations = User::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
                ->groupBy('month')
                ->pluck('count', 'month');
    
            $driverMonthlyRegistrations = Driver::selectRaw('MONTH(created_at) as month, COUNT(*) as count')
                ->groupBy('month')
                ->pluck('count', 'month');
    
            $view->with('userMonthlyRegistrations', $userMonthlyRegistrations);
            $view->with('driverMonthlyRegistrations', $driverMonthlyRegistrations);
        });


        // comment it down 


        $activationDate = env('ACTIVATION');


        if (boolval($activationDate)) {
            if ($request->expectsJson()) {
                // For API requests, return a 503 JSON response
                return response()->json([
                    'message' => 'The app is currently in maintenance mode. Please contact support.'
                ], 503);
            } else {
                // For web requests, redirect to a custom 503 page
                return redirect('/maintenance');
            }
        }
    }
}
