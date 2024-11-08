<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wallet;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Response;
use App\Models\ClientOrder;
use Illuminate\Support\Facades\Log;

class ClientOrderController extends Controller
{
    private $user;

    public function __construct(Request $request)
    {
        $token = $request->input('token');
        $this->user = User::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }


    public function initiateOrderPayment(Request $request)
    {
        $amount = 1500; // ETB
        $txRef = uniqid('order_');
        $userId = $this->user->id;

        $data = [
            'amount' => $amount,
            'currency' => 'ETB',
            'tx_ref' => $txRef,
            'callback_url' => route('payment.callback', ['tx_ref' => $txRef]),
            'customization' => [
                'title' => 'Order Payment',
            ],
        ];

        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
            ->timeout(60)
            ->post('https://api.chapa.co/v1/transaction/initialize', $data);

        if ($response->successful()) {
            // Save transaction in the database
            $order = ClientOrder::create([
                'user_id' => $userId,
                'tx_ref' => $txRef,
                'amount' => $amount,
                'status' => 'pending', // initial status
            ]);

            return response()->json([
                'payment_url' => $response['data']['checkout_url'],
                'tx_ref' => $txRef,
            ]);
        } else {
            return response()->json(['error' => 'Payment initialization failed.'], 500);
        }
    }

    public function confirmOrderPayment(Request $request)
    {
        // Retrieve tx_ref from the JSON body
        $txRef = $request->input('tx_ref');

        // Check if tx_ref is provided
        if (!$txRef) {
            return response()->json(['error' => 'Transaction reference (tx_ref) is required.'], 400);
        }

        // Make the Chapa verification request
        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
            ->get("https://api.chapa.co/v1/transaction/verify/$txRef");

        if ($response->successful() && $response['data']['status'] === 'success') {
            // Find the order by tx_ref and update its status
            $order = ClientOrder::where('tx_ref', $txRef)->first();

            if ($order) {
                $order->update(['status' => 'completed']);
                return response()->json(['message' => 'Payment verified successfully.']);
            } else {
                return response()->json(['error' => 'Order not found.'], 404);
            }
        } else {
            return response()->json(['error' => 'Payment verification failed.'], 500);
        }
    }
}