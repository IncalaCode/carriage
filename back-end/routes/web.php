<?php

use Illuminate\Support\Facades\Route;



Route::get('/', function () {
    return view('welcome');
});

Route::get('/admin', function () {
    return view('admin.dashboard');
});
use App\Http\Controllers\DriverController;

Route::post('api/drivers/register', [DriverController::class, 'register']);

