<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wallet;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Http\Response;
use App\Models\ClientOrder;
use Illuminate\Support\Facades\Log;
use App\Models\Transaction;

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
        $userId = $this->user->uid;
        $wallet = Wallet::where('user_id', $this->user->uid)->first();

        if (!$wallet) {
            return response()->json(['error' => 'Wallet not found for the user.'], 404);
        }


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
            Transaction::create([
                'wallet_id' => $wallet->user_id,
                'amount' => $amount,
                'type' => 'deposit',  // Set the type to pending
                'tx_ref' => $txRef,  // Save tx_ref here
                'description' => 'client order payment',
                'status' => 'pending',
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

        if (!$txRef) {
            return response()->json(['error' => 'Transaction reference (tx_ref) is required.'], 400);
        }

        // Make the Chapa verification request
        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
            ->get("https://api.chapa.co/v1/transaction/verify/$txRef");
                
            
        if ($response->successful() && isset($response['data']['status']) && $response['data']['status'] === 'success') {
                $txRef_data = Transaction::where('tx_ref', $txRef)->first();
                $txRef_data->update(['status' => 'completed']);

            return response()->json(['message' => 'Payment verified successfully.'], 200);
        } else {
            return response()->json(['error' => 'Payment verification failed.'], 500);
        }
    }
}
