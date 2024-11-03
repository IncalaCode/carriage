<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DriverController;
use App\Http\Controllers\driver_request;
use App\Http\Controllers\client_request;

// Authentication Routes
Route::prefix('auth')->group(function () {
    // User Authentication
    Route::post('/user/register', [AuthController::class, 'register']);
    Route::post('/user/login', [AuthController::class, 'login']);
    Route::post('/user/verify', [AuthController::class, 'verifyOtp']);
    Route::post('/user/resend-otp', [AuthController::class, 'userResendOtp'])
        ->middleware('throttle:3,1');

    // Driver Authentication
    Route::post('/driver/register', [DriverController::class, 'register']);
    Route::post('/driver/login', [DriverController::class, 'login']);
    Route::post('/driver/verify', [DriverController::class, 'verifyOtp']);
    Route::post('/driver/resend-otp', [AuthController::class, 'driverResendOtp'])
        ->middleware('throttle:3,1');
});

// Main Application Routes
Route::group(['middleware' => ['auth']], function () {
    // Single endpoint for all driver operations
    Route::post('/driver/handle-request', [driver_request::class, 'handleRequest']);

    // Single endpoint for all client operations
    Route::post('/client/handle-request', [client_request::class, 'handleRequest']);
});
