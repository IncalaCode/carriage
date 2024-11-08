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
        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
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
        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
            ->get("https://api.chapa.co/v1/transaction/verify/$txRef");

        if ($response->successful() && $response['data']['status'] == 'success') {
            // Process payment, e.g., update user balance or mark order as paid
            return response()->json(['message' => 'Payment verified successfully.']);
        } else {
            return response()->json(['error' => 'Payment verification failed.' . $response], 500);
        }
    }

    public function withdrawFunds($driverId)
    {
        // Implement withdrawal logic for driver based on confirmation status
    }

    public function validatePayment(Request $request)
    {
        $txRef = $request->input('tx_ref'); // Unique transaction reference

        // Send a GET request to Chapa to verify the transaction
        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
            ->get("https://api.chapa.co/v1/transaction/verify/{$txRef}");

        if ($response->successful() && $response->json('data.status') === 'success') {
            // Payment is successful. You can proceed with post-payment processing.

            // For example:
            // Update order status, credit user's account, etc.
            return response()->json(['message' => 'Payment verified successfully.'], 200);
        } else {
            // Payment verification failed
            return response()->json(['error' => 'Payment verification failed.'], 400);
        }
    }
}
