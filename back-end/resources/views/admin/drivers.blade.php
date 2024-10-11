<!-- resources/views/admin/drivers.blade.php -->

@extends('admin.dashboard')
<!-- Extend the dashboard layout -->

@section('content')
<!-- Define content for the section -->
<!-- Add your table for listing drivers here -->
<table class="table">
    <thead>
        <tr>
            <th>Name</th>
            <th>Email</th>
            <th>Phone</th>
            <th>Action</th>
        </tr>
    </thead>
    <tbody>
        @foreach($drivers as $driver)
        <tr>
            <td>{{ $driver->first_name }} {{ $driver->last_name }}</td>
            <td>{{ $driver->email }}</td>
            <td>{{ $driver->phone }}</td>
            <td>
                <!-- Actions like Edit/Delete buttons -->
            </td>
        </tr>
        @endforeach
    </tbody>
</table>

<!-- Pagination links -->
{{ $drivers->links() }}
@endsection