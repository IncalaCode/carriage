@extends('layouts.master')

@section('title')
Dashboard
@endsection

@section('content')

<form method="POST" action="">
    @csrf
    <input type="password" name="current_password" placeholder="Current Password" required>
    <input type="password" name="new_password" placeholder="New Password" required>
    <button type="submit">Change Password</button>
</form>

<form method="POST" action="">
    @csrf
    <input type="email" name="new_email" placeholder="New Email" required>
    <button type="submit">Change Email</button>
</form>

@endsection

@section('scripts')
@endsection