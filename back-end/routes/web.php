<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\admin_master_index;
use App\Http\Controllers\DriverController;
use App\Http\Controllers\ClientOrderController;
use App\Http\Controllers\DriverRequestController;


// Public Routes
Route::get('', function () {
    return view('admin.login');
})->name('admin.login');

Route::post('admin/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
Route::post('admin/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');
Route::get('/admin/drivers', [Admin_Master_Index::class, 'driverPage'])->name('admin.drivers');


// Show unapproved drivers

Route::get('/admin/unapproved-drivers', [AdminAuthController::class, 'showUnapprovedDrivers'])->name('admin.unapproved_drivers');
// Approve driver
Route::put('/admin/approve-driver/{id}', [AdminAuthController::class, 'approveDriver'])->name('admin.approve_driver');
// Optional: Reject driver
Route::put('/admin/reject-driver/{id}', [AdminAuthController::class, 'rejectDriver'])->name('admin.reject_driver');
Route::get('/admin/drivers/{driver}/details', [AdminAuthController::class, 'showDriverDetails'])->name('admin.driver_details');



// Protected Routes Using Controller Constructor Logic
Route::get('/admin/dashboard', function () {
    return view('admin.dashboard', ['adminId' => session('admin_id')]);
})->name('admin.dashboard');

Route::get('/admin/drivers', [admin_master_index::class, 'driverPage'])->name('admin.drivers');

Route::get('/admin/settings', [admin_master_index::class, 'settingsPage'])->name('admin.settings');
Route::get('/admin/users', [admin_master_index::class, 'userPage'])->name('admin.user');
Route::post('/admin/update', [AdminAuthController::class, 'updateAdmin'])->name('admin.update');
Route::post('/admin/drivers/{id}/toggle-status', [admin_master_index::class, 'toggleStatus']);
Route::post('/admin/drivers/{id}/toggle-status', [admin_master_index::class, 'toggleStatus']);

Route::get('/admin/users', [admin_master_index::class, 'userPage'])->name('admin.users');
Route::post('/admin/users/{id}/toggle-status', [admin_master_index::class, 'toggleUserStatus']);

Route::post('/order/deposit', [ClientOrderController::class, 'makeOrderDeposit'])->name('order.deposit');
Route::get('/order/deposit/callback/{id}', [ClientOrderController::class, 'handleDepositCallback'])->name('order.deposit.callback');

Route::post('/request/deposit', [DriverRequestController::class, 'acceptRequestDeposit'])->name('request.deposit');
Route::get('/request/deposit/callback/{id}', [DriverRequestController::class, 'handleDriverDepositCallback'])->name('request.deposit.callback');