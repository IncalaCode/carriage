<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\DriverController;
use App\Http\Controllers\admin_master_index;

// Define the admin dashboard route and name it 'admin.dashboard'
Route::get('/admin/dashboard', function () {
    return view('admin.dashboard');
})->name('admin.dashboard');

// Define the admin drivers page and name it 'admin.drivers'
Route::get('/admin/drivers', [admin_master_index::class, 'driverPage'])->name('admin.drivers');

// Define the admin settings page and name it 'admin.settings'
Route::get('/admin/settings', [admin_master_index::class, 'settingsPage'])->name('admin.settings');

// Define the admin users page and name it 'admin.user'
Route::get('/admin/users', [admin_master_index::class, 'userPage'])->name('admin.user');

// Define the admin login form route and name it 'admin.login'
Route::get('', function () {
    return view('admin.login');
})->name('admin.login');

// Handle admin login form submission
Route::post('admin/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
Route::post('admin/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');
