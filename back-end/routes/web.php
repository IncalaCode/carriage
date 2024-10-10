<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;


Route::get('/admin/dashboard', function () {
    return view('admin.dashboard');
});

// Define the admin login form route and name it 'admin.login'
Route::get('', function () {
    return view('admin.login');
})->name('admin.login');

// Handle admin login form submission
Route::post('admin/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
Route::post('admin/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');