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
use App\Http\Controllers\ReferralController;





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



Route::post('/driver/handle-request', [driver_request::class, 'handleRequest']);
Route::post('/client/handle-request', [client_request::class, 'handleRequest']);





Route::post('/client/order/initiate-payment', [ClientOrderController::class, 'initiateOrderPayment']);
Route::post('/client/order/confirm-payment', [ClientOrderController::class, 'confirmOrderPayment']);

Route::post('/driver/request/initiate-payment', [DriverRequestController::class, 'initiateRequestPayment']);
Route::post('/driver/request/confirm-payment', [DriverRequestController::class, 'confirmRequestPayment']);
Route::get('/payment/callback', [PaymentController::class, 'callback'])->name('payment.callback');




Route::post('user/wallet/balance', [WalletController::class, 'usergetBalance']);
Route::post('driver/wallet/balance', [WalletController::class, 'drivergetBalance']);
Route::post('/wallet/deposit', [WalletController::class, 'deposit']);
Route::post('/wallet/withdraw', [WalletController::class, 'withdraw']);
Route::get('/wallet/transactions', [WalletController::class, 'transactionHistory']);


Route::post('/generate-referral-link/{driverId}', [ReferralController::class, 'generateReferralLink']);
Route::post('/driver/cache-phone', [DriverController::class, 'cachePhoneNumber']);
Route::post('/driver/referral-check/{phone}', [DriverController::class, 'referralCheck']);


Route::post('/payment/validate', [PaymentController::class, 'validatePayment']);

Route::post('/payment/validate', [PaymentController::class, 'validatePayment']);

Route::post("/client/getorder", [client_request::class, 'getOrder']);
Route::post("/driver/getorder", [driver_request::class, 'getOrder']);
