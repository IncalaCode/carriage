<!-- resources/views/admin/drivers.blade.php -->

@extends('admin.dashboard')
<!-- Extend the dashboard layout -->

@section('content')
<!-- Define content for the section -->
<!-- Add your table for listing drivers here -->
<div class="row">
    <div class="col-md-12">
        <div class="card">

        </div>
    </div>
    <div class="col-md-12">
        <div class="card card-plain">
            <div class="card-header">
                <h4 class="card-title"> Registered Drivers</h4>
            </div>
            <div class="card-body">
                <div class="table-responsive">
                    <table class="table">
                        <thead class=" text-primary">
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
                </div>
            </div>
        </div>
    </div>
</div>


<!-- Pagination links -->
{{ $drivers->links() }}
@endsection