<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;

// Route to display the admin dashboard
Route::get('/admin/dashboard', function () {
    return check('admin.login', 'dashboard') ?: view('admin.dashboard', ['adminId' => session('admin_id')]);
});

Route::get('', function () {
    return view('admin.login');
})->name('admin.login');

// Handle admin login form submission
Route::post('admin/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
Route::post('admin/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');
Route::post('/admin/update', [AdminAuthController::class, 'updateAdmin'])->name('admin.update');

// Check function to determine if the admin is logged in
function check($route, $filed = "page") {
    if (!session()->has('admin_id')) {
        return redirect()->route($route)->with('message', "Please log in to access the $filed.");
    }
    return false;
}