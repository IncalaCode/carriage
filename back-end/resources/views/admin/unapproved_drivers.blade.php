@extends('layouts.master')

@section('content')

<div style="margin-top: 10%; padding: 20px; max-width: 800px; margin: auto;">
    <h4>Unapproved Drivers</h4>

    <table style="width: 100%; border-collapse: collapse; margin-bottom: 20px;">
        <thead>
            <tr style="background-color: #f2f2f2;">
                <th style="padding: 10px; border: 1px solid #ddd;">Name</th>
                <th style="padding: 10px; border: 1px solid #ddd;">Phone Number</th>
                <th style="padding: 10px; border: 1px solid #ddd;">Actions</th>
            </tr>
        </thead>
        <tbody>
            @foreach($unapprovedDrivers as $driver)
            <tr>
                <td style="padding: 10px; border: 1px solid #ddd;">{{ $driver->first_name }} {{ $driver->last_name }}
                </td>
                <td style="padding: 10px; border: 1px solid #ddd;">{{ $driver->phone_number }}</td>
                <td style="padding: 10px; border: 1px solid #ddd;">
                    <!-- Show Details Button -->
                    <a href="{{ route('admin.driver_details', $driver->id) }}"
                        style="margin-right: 10px; text-decoration: none; color: white; background-color: blue; padding: 5px 10px; border-radius: 5px;">Show
                        Details</a>

                    <!-- Approval Form -->
                    <form action="{{ route('admin.approve_driver', $driver->id) }}" method="POST"
                        style="display:inline;">
                        @csrf
                        @method('PUT')
                        <button type="submit"
                            style="background-color: green; color: white; border: none; padding: 5px 10px; border-radius: 5px;">Approve</button>
                    </form>

                    <!-- Optional: Reject Form (if you want rejection feature) -->
                    <form action="{{ route('admin.reject_driver', $driver->id) }}" method="POST"
                        style="display:inline;">
                        @csrf
                        @method('PUT')
                        <button type="submit"
                            style="background-color: red; color: white; border: none; padding: 5px 10px; border-radius: 5px;">Reject</button>
                    </form>
                </td>
            </tr>
            @endforeach
        </tbody>
    </table>
</div>

@endsection