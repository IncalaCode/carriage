<?php

use Illuminate\Support\Facades\Route;


use App\Http\Controllers\DriverController;

Route::post('api/drivers/register', [DriverController::class, 'register']);