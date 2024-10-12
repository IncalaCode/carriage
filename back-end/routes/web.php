<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\admin_master_index;

// Public Routes
Route::get('', function () {
    return view('admin.login');
})->name('admin.login');

Route::post('admin/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
Route::post('admin/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');

// Protected Routes Using Controller Constructor Logic
Route::get('/admin/dashboard', function () {
    return view('admin.dashboard', ['adminId' => session('admin_id')]);
})->name('admin.dashboard');

Route::get('/admin/drivers', [admin_master_index::class, 'driverPage'])->name('admin.drivers');
Route::get('/admin/settings', [admin_master_index::class, 'settingsPage'])->name('admin.settings');
Route::get('/admin/users', [admin_master_index::class, 'userPage'])->name('admin.user');
Route::post('/admin/update', [AdminAuthController::class, 'updateAdmin'])->name('admin.update');
Route::post('/admin/drivers/{id}/toggle-status', [admin_master_index::class, 'toggleStatus']);