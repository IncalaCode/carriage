<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wallet;
use App\Models\Driver;
use App\Models\DriverRequest;
use App\Models\Transaction;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;
use Illuminate\Support\Facades\Log;
use App\Models\DriverTransactionRequest;
use App\Models\DriverWallet;


class DriverRequestController extends Controller
{
    private $user;

    public function __construct(Request $request)
    {
        // Check for the Authorization header
        $token = $request->input('token');

        // Look for the user by their token (e.g., assuming `uid` corresponds to the token)
        $this->user = Driver::where('uid', $token)->first();

        if (!$this->user) {
            abort(Response::HTTP_UNAUTHORIZED, 'Unauthorized');
        }
    }

    public function initiateRequestPayment(Request $request)
    {
        Log::info('Chapa API Key:', ['key' => env('CHAPA_SECRET_KEY')]);

        $amount = 1500; // ETB
        $txRef = uniqid('request_');
        $driverId = $this->user->uid;
        $wallet = DriverWallet::where('driver_id', $this->user->uid)->first();

        if (!$wallet) {
            return response()->json(['error' => 'Wallet not found for the driver.'], 404);
        }


        $data = [
            'amount' => $amount,
            'currency' => 'ETB',
            'tx_ref' => $txRef,
            'callback_url' => route('payment.callback', ['tx_ref' => $txRef]),
            'customization' => [
                'title' => 'Request Payment',
            ],
        ];

        $response = Http::withToken(env('CHAPA_SECRET_KEY'))
            ->timeout(60)
            ->post('https://api.chapa.co/v1/transaction/initialize', $data);

        if ($response->successful()) {
            // Save transaction in the database
            Transaction::create([
                'wallet_id' => $wallet->driver_id,
                'amount' => $amount,
                'type' => 'deposit',  // Set the type to pending
                'tx_ref' => $txRef,  // Save tx_ref here
                'description' => 'Driver request payment',
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

    public function confirmRequestPayment(Request $request)
    {
        $txRef = $request->input('tx_ref');

        // Ensure txRef is provided
        if (!$txRef) {
            return response()->json(['error' => 'Transaction reference is required.'], 400);
        }

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . env('CHAPA_SECRET_KEY')
        ])->timeout(120)->get("https://api.chapa.co/v1/transaction/verify/$txRef");

        if ($response->successful() && isset($response['data']['status']) && $response['data']['status'] === 'success') {
            $txRef_data = Transaction::where('tx_ref', $txRef)->first();
            $txRef_data->update(['status' => 'completed']);

            $wallet = DriverWallet::where('driver_id', $this->user->uid)->first();
            $wallet->update(['balance' => $wallet->balance + $txRef_data->amount]);
            return response()->json(['message' => 'Payment verification successful.' . $txRef_data->amount], 200);
        } else {
            // Log the exact error response for easier debugging
            Log::error('Payment verification failed:', ['response' => $response->json()]);
            return response()->json(['error' => 'Payment verification failed.'], 500);
        }
    }


    public function withdraw(Request $request)
    {
        $wallet = DriverWallet::where('driver_id', $this->user->uid)->first();
    
        if (!$wallet) {
            return response()->json(['error' => 'Wallet not found'], 404);
        }
    
        $withdrawAmount = $request->input('amount');
        $minimumBalance = 1500;
    
        if (($wallet->balance - $minimumBalance) >= $withdrawAmount) {
            // Log the withdrawal transaction
            $txRef = uniqid('_transfers');
            Transaction::create([
                'wallet_id'   => $wallet->driver_id,  // Ensure this references the correct wallet ID
                'amount'      => $withdrawAmount,
                'type'        => 'pending',  
                'tx_ref' => $txRef,
                'description' => 'Driver withdrawal',
            ]);

          
    
            // Prepare payload for Chapa transfer
            $payload = [
                "account_name"   => $request->account_name, // Replace with dynamic data if needed
                "account_number" => $request->account_number,
                "amount"         => $withdrawAmount,
                "currency"       => "ETB",
                "reference"      => $txRef, // Generate unique reference dynamically
                "bank_code"      => 946,
            ];
    
            try {
                // Make the API request
                $response = Http::withHeaders([
                    'Authorization' => 'Bearer ' . env('CHAPA_SECRET_KEY')
                ])->timeout(120)->post("https://api.chapa.co/v1/transfers", $payload);

                $txRef_data = Transaction::where('tx_ref', $txRef)->first();
                // Validate response
                if ($response->successful() && $response->json('status') === 'success') {
                 
                    $txRef_data->update(['status' => 'completed']);

                    return response()->json([
                        'reference' => $response->json('data'), 
                        'message' => $response->json('message'),
                    ]);
                } else {
                    Transaction::where('tx_ref', $txRef)->delete();
                    return response()->json([
                        'error' => 'Failed to process withdrawal',
                        'details' => $response->json(),
                    ], 400);
                }
            } catch (\Exception $e) {
                // Handle errors during the API request
                return response()->json([
                    'error' => 'Error processing withdrawal',
                    'details' => $e->getMessage(),
                ], 500);
            }
        } else {
            return response()->json(['error' => 'Insufficient balance for withdrawal'], 403);
        }
    }
    
}
