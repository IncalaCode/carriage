<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Wallet;
use App\Models\Driver;
use App\Models\DriverRequest;
use Illuminate\Support\Facades\Http;
use Symfony\Component\HttpFoundation\Response;

class DriverRequestController extends Controller
{
    private $user;

    public function __construct(Request $request)
    {
        $token = $request->input('token');
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

        $data = [
            'amount' => $amount,
            'currency' => 'ETB',
            'tx_ref' => $txRef,
            'callback_url' => route('payment.callback', ['tx_ref' => $txRef]),
            'customization' => [
                'title' => 'Request Payment',
            ],
        ];

        $response = Http::withToken(env('CHAPA_API_KEY'))
            ->post('https://api.chapa.co/v1/transaction/initialize', $data);

        if ($response->successful()) {
            // Save transaction in the database
            DriverRequest::create([
                'driver_id' => $driverId,
                'tx_ref' => $txRef,
                'amount' => $amount,
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
        $txRef = $request->query('tx_ref');

        $response = Http::withToken(env('CHAPA_API_KEY'))
            ->get("https://api.chapa.co/v1/transaction/verify/$txRef");

        if ($response->successful() && $response['data']['status'] === 'success') {
            // Update the request status to completed
            $driverRequest = DriverRequest::where('tx_ref', $txRef)->first();
            $driverRequest->update(['status' => 'completed']);

            return response()->json(['message' => 'Payment verified successfully.']);
        } else {
            return response()->json(['error' => 'Payment verification failed.'], 500);
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
            $driverRequest->update(['status' => 'withdrawn']);

            return response()->json(['message' => 'Withdrawal successful']);
        } else {
            return response()->json(['error' => 'Withdrawal not allowed'], 403);
        }
    }
}