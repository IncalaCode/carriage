<?php

namespace App\Http\Controllers;

use App\Models\Wallet;
use App\Models\Transaction;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

class WalletController extends Controller
{
    public function usergetBalance(Request $request)
    {
        $wallet = Wallet::where('uid', $request->input('token'))->first();

        if($wallet){
            return response()->json(['balance' => $wallet->balance]);
        }else{
            return response()->json(['error' => 'Wallet not found'], 404);
        }
    }
    public function drivergetBalance(Request $request)
    {
        $wallet = Wallet::where('uid', $request->input('token'))->first();
        if($wallet){
            return response()->json(['balance' => $wallet->balance]);
        }else{
            return response()->json(['error' => 'Wallet not found'], 303);
        }
    }

    public function deposit(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
        ]);

        $wallet = Wallet::firstOrCreate(['user_id' => $request->user()->id]);

        $amount = $request->input('amount');
        DB::transaction(function () use ($wallet, $amount) {
            $wallet->increment('balance', $amount);

            Transaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'deposit',
                'amount' => $amount,
                'description' => 'User deposit',
            ]);
        });

        return response()->json(['message' => 'Deposit successful']);
    }


    public function withdraw(Request $request)
    {
        $request->validate([
            'amount' => 'required|numeric|min:1',
        ]);

        $wallet = Wallet::where('user_id', $request->user()->id)->firstOrFail();
        $amount = $request->input('amount');

        if ($wallet->balance < $amount) {
            return response()->json(['error' => 'Insufficient balance'], 400);
        }

        DB::transaction(function () use ($wallet, $amount) {
            $wallet->decrement('balance', $amount);

            Transaction::create([
                'wallet_id' => $wallet->id,
                'type' => 'withdrawal',
                'amount' => $amount,
                'description' => 'User withdrawal',
            ]);
        });

        return response()->json(['message' => 'Withdrawal successful']);
    }


    public function transactionHistory(Request $request)
    {
        $wallet = Wallet::where('user_id', $request->user()->id)->firstOrFail();
        $transactions = $wallet->transactions()->latest()->get();

        return response()->json($transactions);
    }
    // public function deposit(Request $request)
    // {
    //     $request->validate([
    //         'amount' => 'required|numeric|min:1',
    //     ]);

    //     $wallet = Wallet::firstOrCreate(['user_id' => $request->user()->id]);

    //     $amount = $request->input('amount');
    //     try {
    //         DB::transaction(function () use ($wallet, $amount) {
    //             $wallet->increment('balance', $amount);

    //             Transaction::create([
    //                 'wallet_id' => $wallet->id,
    //                 'type' => 'deposit',
    //                 'amount' => $amount,
    //                 'description' => 'User deposit',
    //             ]);
    //         });
    //     } catch (\Exception $e) {
    //         // You may want to log the error for debugging purposes
    //         \Log::error('Transaction failed: ' . $e->getMessage());
    //         return response()->json(['error' => 'Transaction failed'], 500);
    //     }

    //     return response()->json(['message' => 'Deposit successful']);
    // }
}
