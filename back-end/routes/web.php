<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AdminAuthController;
use App\Http\Controllers\DriverController;
use App\Http\Controllers\admin_master_index;





Route::get('', function () {
    return view('admin.login');
})->name('admin.login');

Route::get('/admin/dashboard', function () {
    return check('admin.login', 'dashboard') ?: view('admin.dashboard', ['adminId' => session('admin_id')]);
})->name('admin.dashboard');


Route::get('/admin/drivers', [admin_master_index::class, 'driverPage'])->name('admin.drivers');

Route::get('/admin/settings', [admin_master_index::class, 'settingsPage'])->name('admin.settings');

Route::get('/admin/users', [admin_master_index::class, 'userPage'])->name('admin.user');

Route::post('admin/login', [AdminAuthController::class, 'login'])->name('admin.login.submit');
Route::post('admin/logout', [AdminAuthController::class, 'logout'])->name('admin.logout');

Route::post('/admin/update', [AdminAuthController::class, 'updateAdmin'])->name('admin.update');

Route::post('/admin/drivers/{id}/toggle-status', [admin_master_index::class, 'toggleStatus']);


function check($route, $filed = "page")
{
    if (!session()->has('admin_id')) {
        return redirect()->route($route)->with('message', "Please log in to access the $filed.");
    }
    return false;
}