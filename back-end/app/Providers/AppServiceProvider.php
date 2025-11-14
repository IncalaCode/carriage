<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Models\Driver;
use App\Models\User;
use Illuminate\Support\Facades\View;

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
    public function boot(): void
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
    }
}
