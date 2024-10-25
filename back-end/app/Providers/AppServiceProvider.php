<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;
use App\Models\Driver;
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
    }
}
