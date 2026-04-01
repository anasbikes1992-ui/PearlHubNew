<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\PearlPoint;
use App\Models\WalletTransaction;
use Illuminate\Http\Request;

class WalletController extends Controller
{
    public function balance(Request $request)
    {
        $userId = $request->user()->id;

        $deposits = WalletTransaction::where('user_id', $userId)
            ->where('status', 'completed')
            ->whereIn('type', ['deposit', 'commission', 'refund'])
            ->sum('amount');

        $withdrawals = WalletTransaction::where('user_id', $userId)
            ->where('status', 'completed')
            ->where('type', 'withdrawal')
            ->sum('amount');

        $pearlPoints = PearlPoint::firstOrCreate(
            ['user_id' => $userId],
            ['points' => 0, 'tier' => 'bronze']
        );

        return response()->json([
            'balance' => round($deposits - $withdrawals, 2),
            'pearl_points' => $pearlPoints,
        ]);
    }

    public function transactions(Request $request)
    {
        return response()->json(
            WalletTransaction::where('user_id', $request->user()->id)
                ->latest()
                ->paginate(20)
        );
    }

    public function deposit(Request $request)
    {
        $data = $request->validate([
            'amount' => 'required|numeric|min:1',
            'description' => 'nullable|string',
            'ref' => 'nullable|string',
        ]);

        $txn = WalletTransaction::create([
            'user_id' => $request->user()->id,
            'type' => 'deposit',
            'amount' => $data['amount'],
            'description' => $data['description'] ?? 'Wallet deposit',
            'status' => 'completed',
            'ref' => $data['ref'] ?? null,
        ]);

        return response()->json($txn, 201);
    }

    public function withdraw(Request $request)
    {
        $data = $request->validate([
            'amount' => 'required|numeric|min:1',
            'description' => 'nullable|string',
        ]);

        $txn = WalletTransaction::create([
            'user_id' => $request->user()->id,
            'type' => 'withdrawal',
            'amount' => $data['amount'],
            'description' => $data['description'] ?? 'Wallet withdrawal',
            'status' => 'pending',
        ]);

        return response()->json($txn, 201);
    }
}
