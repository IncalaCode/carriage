@extends('layouts.master')

@section('title', 'Dashboard')

@section('content')

<div class="row">
    <div class="col-md-12">
        <div class="card"></div>
        <div id="toast-container"></div>

        <div class="col-md-12">
            <div id="table" class="card card-plain">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div>
                        <h4 class="card-title">unapproved Drivers</h4>
                    </div>
                </div>

                <style>
                #searchInput::placeholder {
                    color: black;
                }

                @media (max-width: 576px) {
                    .input-group {
                        width: 100%;
                    }

                    .d-flex {
                        flex-direction: column;
                        align-items: center;
                    }
                }
                </style>

                <div class="card-body">
                    <div class="table-responsive">
                        <table class="table" id="driversTable">
                        <thead class="text-primary">
                                <tr>
                                    <th>Name</th>
                                    <th>Phone</th>
                                    <th>Actions</th>
                                </tr>
                            </thead>
                            <tbody id="driversTableBody">
                            @foreach($unapprovedDrivers as $driver)
                                <tr>
                                    <td >{{ $driver->first_name }} {{ $driver->last_name }}
                                    <td>{{ $driver->phone_number }}</td>
                                    <td><a href="{{ route('admin.driver_details', $driver->id) }}">Show
                                        Details</a>
                                        <!-- Approval Form -->
                                    <form action="{{ route('admin.approve_driver', $driver->id) }}" method="POST"
                                    style="display:inline;">
                                    @csrf
                                    @method('PUT')
                                    <button type="submit"
                                    style="background-color: green; color: white; border: none; padding: 5px 10px; border-radius: 5px;margin-left: 15px;">Approve</button>
                                    </form>

                    <!-- Optional: Reject Form (if you want rejection feature) -->
                                    <form action="{{ route('admin.reject_driver', $driver->id) }}" method="POST"
                                        style="display:inline;">
                                        @csrf
                                        @method('PUT')
                                        <button type="submit"
                                            style="background-color: red; color: white; border: none; padding: 5px 10px; border-radius: 5px;margin-left: 15px;">Reject</button>
                                    </form>
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Pagination links -->
                

            </div>
        </div>
    </div>
</div>

@endsection
@section('scripts')

@endsection





















