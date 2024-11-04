<?php


use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DriverController;

use App\Http\Controllers\driver_request;
use App\Http\Controllers\client_request;




// Route for user registration
Route::post('/user/register', [AuthController::class, 'register']);
Route::post('/user/login', [AuthController::class, 'login']);
// Route::post('user/send-otp', [AuthController::class, 'sendOtp']);
Route::post('/user/verify', [AuthController::class, 'verifyOtp']);
Route::post('/user/resend-otp', [AuthController::class, 'userResendOtp']);


// Example route to test if it's working
// Route::get('/user/register', function () {
//     return "wow";
// });

// Route for driver registration and login only for dirivers
Route::post('/driver/register', [DriverController::class, 'register']);
Route::post('/driver/login', [DriverController::class, 'login']);
Route::post('/driver/verify', [DriverController::class, 'verifyOtp']);
Route::post('/driver/resend-otp', [AuthController::class, 'driverResendOtp']);
Route::middleware('throttle:3,1')->post('/driver/resend-otp', [AuthController::class, 'driverResendOtp']);


// Route for admin registration and login only for admin


Route::post('/adminLogin', [AuthController::class, 'adminLogin']);
Route::post('/adminLogout', [AuthController::class, 'adminLogout']);
Route::post('/updateAdmin', [AuthController::class, 'updateAdmin']);


Route::middleware('auth:driver')->group(function () {
    Route::get('/driver/requests', [DriverController::class, 'accessRequests']);
});



// Driver Routes

Route::post('/driver/handle-request', [driver_request::class, 'handleRequest']);

// Client (User) Routes

Route::post('/client/handle-request', [client_request::class, 'handleRequest']);
