<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;

class PaymentController extends Controller
{
    public function initiatePayment(Request $request)
    {
        $amount = 1500; // ETB
        $txRef = uniqid('order_');
        $userType = $request->user_type; // 'user' or 'driver'

        $data = [
            'amount' => $amount,
            'currency' => 'ETB',
            'tx_ref' => $txRef,
            'callback_url' => route('payment.callback', ['tx_ref' => $txRef]),
            'customization' => [
                'title' => 'Payment for Order',
            ],
        ];

        // Send HTTP request to Chapa API
        $response = Http::withToken(env('CHAPA_API_KEY'))
            ->post('https://api.chapa.co/v1/transaction/initialize', $data);

        if ($response->successful()) {
            return response()->json([
                'payment_url' => $response['data']['checkout_url'],
                'tx_ref' => $txRef
            ]);
        } else {
            return response()->json(['error' => 'Payment initialization failed.'], 500);
        }
    }

    public function paymentCallback(Request $request)
    {
        $txRef = $request->query('tx_ref');
        $response = Http::withToken(env('CHAPA_API_KEY'))
            ->get("https://api.chapa.co/v1/transaction/verify/$txRef");

        if ($response->successful() && $response['data']['status'] == 'success') {
            // Process payment, e.g., update user balance or mark order as paid
            return response()->json(['message' => 'Payment verified successfully.']);
        } else {
            return response()->json(['error' => 'Payment verification failed.'], 500);
        }
    }

    public function withdrawFunds($driverId)
    {
        // Implement withdrawal logic for driver based on confirmation status
    }
}