<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wallet;
use App\Models\Driver;
use App\Models\DriverRequest;
use App\Models\Transaction;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

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
        $amount = 1500; // ETB
        $txRef = uniqid('request_');
        $driverId = $this->user->id;
        $wallet = Wallet::where('driver_id', $driverId)->first();

        // Fetch the driver's wallet
        $wallet = $this->user->wallet; // This will get the related wallet

        if (!$wallet) {
            $wallet = Wallet::create([
                'driver_id' => $driverId,
                'balance' => 0, // Initialize with a default balance if needed
            ]);
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
                'wallet_id' => $wallet->id,  // Ensure the user's wallet ID is used
                'amount' => $amount,
                'type' => 'pending',  // Set the type to pending
                'description' => 'Request payment initialization',  // Optional description
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

        $response = Http::withHeaders([
            'Authorization' => 'Bearer ' . env('CHAPA_SECRET_KEY')
        ])->get("https://api.chapa.co/v1/transaction/verify/$txRef");

        if ($response->successful() && $response['data']['status'] === 'success') {
            // Update the request status to completed
            Transaction::where('tx_ref', $txRef)->update(['status' => 'completed']);
            $driverRequest = DriverRequest::where('tx_ref', $txRef)->first();
            if ($driverRequest) {
                $driverRequest->update(['status' => 'completed']);

                // Create a transaction record for successful payment
                Transaction::create([
                    'wallet_id' => $this->user->wallet_id, // Assuming the user has a wallet
                    'amount' => $driverRequest->amount,  // Amount from the driver request
                    'type' => 'deposit',  // Set type to deposit for completed payments
                    'description' => 'Payment confirmed for request.',  // Optional description
                ]);
            }

            return response()->json(['message' => 'Payment verified successfully.']);
        } else {
            return response()->json(['error' => 'Payment verification failed.' . $response], 500);
        }
    }

    public function withdrawFunds(Request $request)
    {
        $driverId = $this->user->id;
        $driverRequest = DriverRequest::where('driver_id', $driverId)
            ->where('status', 'completed')
            ->first();

        if ($driverRequest) {
            // Transfer funds back to the driver’s wallet or initiate withdrawal process
            // Here we could implement a logic to deduct from the driver’s balance, etc.
            $withdrawalAmount = $driverRequest->amount; // Example: withdrawing the full amount

            // Update the driver request to withdrawn
            $driverRequest->update(['status' => 'withdrawn']);

            // Log the withdrawal transaction
            Transaction::create([
                'wallet_id' => $this->user->wallet_id, // Ensure this is the correct wallet ID
                'amount' => $withdrawalAmount,
                'type' => 'withdrawal',  // Set type to withdrawal
                'description' => 'Driver withdrawal',  // Optional description
            ]);

            return response()->json(['message' => 'Withdrawal successful']);
        } else {
            return response()->json(['error' => 'Withdrawal not allowed'], 403);
        }
    }
}
