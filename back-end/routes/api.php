<?php


use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\DriverController;

use App\Http\Controllers\driver_request;
use App\Http\Controllers\client_request;
use App\Http\Controllers\PaymentController;
use App\Http\Controllers\ClientOrderController;
use App\Http\Controllers\DriverRequestController;
use App\Http\Controllers\WalletController;





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

<<<<<<< HEAD
Route::post('/client/handle-request', [client_request::class, 'handleRequest']);
=======
Route::post('/client/request/send', [client_request::class, 'sendRequest']); // Send a ride request
Route::post('/client/request/drivers', [client_request::class, 'getDriverResponses']); // View driver responses
Route::post('/client/request/confirm', [client_request::class, 'confirmDriver']); // Confirm driver selection
Route::post('/client/request/cancel', [client_request::class, 'cancelRequest']); // Cancel pending ride request
Route::post('/client/request/cancel-locked', [client_request::class, 'cancelLockedRequest']); // Cancel locked ride request
Route::post('/client/request/track', [client_request::class, 'trackDriverLocation']); // Track driver's location
Route::post('/client/request/complete', [client_request::class, 'completeRide']); // Mark the ride as completed

Route::post('/payment/initiate', [PaymentController::class, 'initiatePayment']);
Route::get('/payment/callback', [PaymentController::class, 'paymentCallback'])->name('payment.callback');
Route::post('/driver/withdraw', [PaymentController::class, 'withdrawFunds']);

Route::post('/client/order/initiate-payment', [ClientOrderController::class, 'initiateOrderPayment']);
Route::get('/client/order/confirm-payment', [ClientOrderController::class, 'confirmOrderPayment']);

Route::post('/driver/request/initiate-payment', [DriverRequestController::class, 'initiateRequestPayment']);
Route::get('/driver/request/confirm-payment', [DriverRequestController::class, 'confirmRequestPayment']);


Route::middleware('auth:sanctum')->group(function () {
    Route::get('/wallet/balance', [WalletController::class, 'getBalance']);
    Route::post('/wallet/deposit', [WalletController::class, 'deposit']);
    Route::post('/wallet/withdraw', [WalletController::class, 'withdraw']);
    Route::get('/wallet/transactions', [WalletController::class, 'transactionHistory']);
});
>>>>>>> 498c9d7c747b8880d1fc3d70490282e1af85f465
