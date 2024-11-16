@extends('layouts.master')

@section('content')
<div class="container" style="margin-top: 40px;">
    <div class="row">
        <!-- Total Users -->
        <div class="col-md-3 mb-3">
            <div class="card text-white bg-primary equal-card">
                <div class="card-body text-center">
                    <h5 class="card-title">Total Users</h5>
                    <p class="card-text display-4">{{ $totalUsers }}</p>
                </div>
            </div>
        </div>
        <!-- Total Drivers -->
        <div class="col-md-3 mb-3">
            <div class="card text-white bg-success equal-card">
                <div class="card-body text-center">
                    <h5 class="card-title">Total Drivers</h5>
                    <p class="card-text display-4">{{ $totalDrivers }}</p>
                </div>
            </div>
        </div>
        <!-- Total Transactions -->
        <div class="col-md-3 mb-3">
            <div class="card text-white bg-warning equal-card">
                <div class="card-body text-center">
                    <h5 class="card-title">Total Transactions</h5>
                    <p class="card-text display-4">{{ $totalTransactions }}</p>
                </div>
            </div>
        </div>
        <!-- Another metric, e.g., Revenue -->
        <div class="col-md-3 mb-3">
            <div class="card text-white bg-danger equal-card">
                <div class="card-body text-center">
                    <h5 class="card-title">Total Referrals</h5>
                    <p class="card-text display-4">{{ $referralDrivers }}</p>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
