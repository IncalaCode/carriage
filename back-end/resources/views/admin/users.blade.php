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
                        <h4 class="card-title">Registered users</h4>
                        <p class="category">Manage all registered users</p>
                    </div>
                    <form class="d-flex">
                        <div class="input-group no-border">
                            <input type="text" class="form-control border-dark rounded-pill" placeholder="Search..."
                                id="searchInput">
                            <span class="input-group-addon bg-transparent border-0">
                                <i class="now-ui-icons ui-1_zoom-bold"></i>
                            </span>
                        </div>
                    </form>
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
                                    <th>verification</th>
                                    <th>Status</th>
                                    <th class="text-right">Action</th>
                                </tr>
                            </thead>
                            <tbody id="driversTableBody">
                                @foreach ($users as $user)
                                <tr>
                                    <td>{{ $user->first_name }} {{ $user->last_name }}</td>
                                    <td>{{ $user->phone_number }}</td>
                                    <td><span class="badge {{ $user->verified ? 'bg-success' : 'bg-danger' }}">
                                            {{ $user->verified ? 'verified' : 'unverified' }}
                                        </span>
                                    </td>
                                    <td>
                                        <span class="badge {{ $user->status ? 'bg-success' : 'bg-danger' }}">
                                            {{ $user->status ? 'Active' : 'Inactive' }}
                                        </span>
                                    </td>
                                    <td class="text-right">
                                        <button class="btn btn-sm {{ $user->status ? 'btn-danger' : 'btn-success' }}"
                                            onclick="toggleStatus({{ $user->id }}, {{ $user->status ? 0 : 1 }})">
                                            {{ $user->status ? 'Deactivate' : 'Activate' }}
                                        </button>
                                    </td>
                                </tr>
                                @endforeach
                            </tbody>
                        </table>
                    </div>
                </div>

                <!-- Pagination links -->
                <div class="d-flex justify-content-center mt-3">
                    @if ($users->hasPages())
                    <nav id="paginationLinks" aria-label="Page navigation">
                        <ul class="pagination">
                            {{-- Previous Page Link --}}
                            @if ($users->onFirstPage())
                            <li class="page-item disabled">
                                <a class="page-link" href="#" tabindex="-1" aria-disabled="true">Previous</a>
                            </li>
                            @else
                            <li class="page-item">
                                <a class="page-link" href="{{ $users->previousPageUrl() }}">Previous</a>
                            </li>
                            @endif

                            {{-- Pagination Elements --}}
                            @foreach ($users->links()->elements as $element)
                            @if (is_string($element))
                            <li class="page-item disabled"><a class="page-link" href="#">{{ $element }}</a></li>
                            @endif

                            @if (is_array($element))
                            @foreach ($element as $page => $url)
                            @if ($page == $users->currentPage())
                            <li class="page-item active">
                                <a class="page-link" href="#">{{ $page }}</a>
                            </li>
                            @else
                            <li class="page-item">
                                <a class="page-link" href="{{ $url }}">{{ $page }}</a>
                            </li>
                            @endif
                            @endforeach
                            @endif
                            @endforeach

                            {{-- Next Page Link --}}
                            @if ($users->hasMorePages())
                            <li class="page-item">
                                <a class="page-link" href="{{ $users->nextPageUrl() }}">Next</a>
                            </li>
                            @else
                            <li class="page-item disabled">
                                <a class="page-link" href="#" tabindex="-1" aria-disabled="true">Next</a>
                            </li>
                            @endif
                        </ul>
                    </nav>
                    @else
                    <!-- <div>No results found.</div> -->
                    @endif
                </div>

            </div>
        </div>
    </div>
</div>

@endsection
@section('scripts')
<script>
    document.addEventListener('DOMContentLoaded', function() {


        // Search functionality
        document.getElementById('searchInput').addEventListener('keyup', function() {
            if (this.value == "") {
                hidePentgation("block")
            } else {
                hidePentgation("none")
            }

            fetchDrivers(this.value);


        });
    });

    function hidePentgation(value) {
        document.getElementById("paginationLinks").style.display = value;
    }
    // Fetch drivers using fetch API
    function fetchDrivers(searchQuery = '') {
        fetch(`/admin/users?search=${encodeURIComponent(searchQuery)}`, {
                headers: {
                    'X-Requested-With': 'XMLHttpRequest',
                }
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error(`HTTP error! Status: ${response.status}`);
                }
                return response.json();
            })
            .then(data => {
                // Clear the table and pagination links
                document.getElementById('driversTableBody').innerHTML = '';


                // Loop through the drivers and populate the table
                data.data.forEach(user => {
                    const row = document.createElement('tr');
                    row.innerHTML = `
                    <td>${user.first_name} ${user.last_name}</td>
                    <td>${user.phone}</td>
                    <td>
                        <span class="badge ${user.verified ? 'bg-success' : 'bg-danger'}">
                            ${user.verified ? 'verified' : 'unverified'}
                        </span>
                    </td>
                    <td>
                        <span class="badge ${user.status ? 'bg-success' : 'bg-danger'}">
                            ${user.status ? 'Active' : 'Inactive'}
                        </span>
                    </td>
                    <td class="text-right">
                        <button class="btn btn-sm ${user.status ? 'btn-danger' : 'btn-success'}"
                            onclick="toggleStatus(${user.id}, ${user.status ? 0 : 1})">
                            ${user.status ? 'Deactivate' : 'Activate'}
                        </button>
                    </td>
                `;
                    document.getElementById('driversTableBody').appendChild(row);
                });

            })
            .catch(error => {
                console.error('Error fetching drivers:', error);
            });
    }

    // Function to toggle the driver's status
    function toggleStatus(driverId, newStatus) {
        fetch(`/admin/users/${driverId}/toggle-status`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                    'X-CSRF-TOKEN': '{{ csrf_token() }}'
                },
                body: JSON.stringify({
                    status: newStatus
                })
            })
            .then(response => response.json())
            .then(data => {
                if (data.success) {
                    fetchDrivers(); // Refresh the driver list after toggling status
                    showToast(`User ${newStatus ? 'activated' : 'deactivated'} successfully!`, newStatus ? "#28a745" :
                        "#dc3545");
                } else {
                    throw new Error('Failed to update status');
                }
            })
            .catch(error => {
                console.error('Error toggling status:', error);
                showToast("An error occurred. Please try again.", "#ff4d4d");
            });
    }

    // Helper function: Show custom toast notification
    function showToast(message, bgColor) {
        const toast = document.createElement('div');

        // Set styles and properties
        toast.className = 'toast toast-slide-in';
        toast.style.backgroundColor = bgColor;
        toast.style.padding = '20px 30px';
        toast.style.borderRadius = '10px';
        toast.style.opacity = '0';
        toast.style.transform = 'translateY(-20px)';
        toast.style.transition = 'opacity 0.5s ease, transform 0.5s ease';
        toast.style.position = 'relative';
        toast.style.marginTop = '10px';
        toast.style.zIndex = '99999';

        // Set text
        toast.innerText = message;

        // Append toast to the container
        const toastContainer = document.getElementById('toast-container');
        toastContainer.appendChild(toast);

        // Show the toast
        setTimeout(() => {
            toast.classList.add('show');
            toast.style.opacity = '1';
            toast.style.transform = 'translateY(0)';
        }, 100);

        // Hide the toast after 3 seconds
        setTimeout(() => {
            toast.classList.remove('show');
            toastContainer.removeChild(toast);
        }, 3000);
    }

    const restore = document.getElementById("driversTableBody").innerHTML;
</script>
@endsection