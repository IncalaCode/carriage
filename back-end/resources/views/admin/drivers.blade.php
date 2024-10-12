@extends('layouts.master')

@section('title', 'Dashboard')

@section('link')
<!-- Custom Toast CSS -->
<style>
.toast {
    position: absolute;
    top: 20px;
    /* Positioning to the top-right corner */
    right: 20px;
    /* Adjust for right positioning */
    background-color: #333;
    color: white;
    padding: 15px 25px;
    /* Slightly increased padding for aesthetics */
    border-radius: 15px;
    /* Curved corners */
    box-shadow: 0 4px 20px rgba(0, 0, 0, 0.5);
    z-index: 9999;
    opacity: 0;
    transform: translateY(-20px);
    transition: opacity 0.5s ease, transform 0.5s ease;
}

.toast.show {
    opacity: 1;
    transform: translateY(0);
}

/* Cool animations */
.toast-slide-in {
    animation: slideIn 0.5s forwards;
}

.toast-fade-out {
    animation: fadeOut 0.5s forwards;
}

@keyframes slideIn {
    from {
        transform: translateY(-30px);
        opacity: 0;
    }

    to {
        transform: translateY(0);
        opacity: 1;
    }
}

@keyframes fadeOut {
    from {
        opacity: 1;
    }

    to {
        opacity: 0;
    }
}
</style>
@endsection

@section('content')
<div class="row">
    <div class="col-md-12">
        <div class="card"></div>

        <div class="col-md-12">
            <div class="card card-plain">
                <div class="card-header d-flex justify-content-between align-items-center">
                    <div>
                        <h4 class="card-title">Registered Drivers</h4>
                        <p class="category">Manage all registered drivers</p>
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
                                    <th>Email</th>
                                    <th>Phone</th>
                                    <th>Status</th>
                                    <th class="text-right">Action</th>
                                </tr>
                            </thead>
                            <tbody>
                                @foreach($drivers as $driver)
                                <tr id="driver-{{ $driver->id }}">
                                    <td>{{ $driver->first_name }} {{ $driver->last_name }}</td>
                                    <td>{{ $driver->email }}</td>
                                    <td>{{ $driver->phone }}</td>
                                    <td>
                                        <span class="badge {{ $driver->status ? 'bg-success' : 'bg-danger' }}">
                                            {{ $driver->status ? 'Active' : 'Inactive' }}
                                        </span>
                                    </td>
                                    <td class="text-right">
                                        <button class="btn btn-sm {{ $driver->status ? 'btn-danger' : 'btn-success' }}"
                                            onclick="toggleStatus(this, {{ $driver->id }}, {{ $driver->status ? 00 : 1 }})">
                                            <span class="button-text">
                                                {{ $driver->status ? 'Deactivate' : 'Activate' }}
                                            </span>
                                            <span class="spinner-border spinner-border-sm d-none" role="status"></span>
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
                    {{ $drivers->links() }}
                </div>
            </div>
        </div>
    </div>
</div>

<!-- Toast Container -->
<div id="toast-container"></div>
@endsection

@section('scripts')
<script>
function toggleStatus(button, driverId, newStatus) {
    const spinner = button.querySelector('.spinner-border');
    const buttonText = button.querySelector('.button-text');

    setLoadingState(button, buttonText, spinner, true);

    fetch(`/admin/drivers/${driverId}/toggle-status`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'X-CSRF-TOKEN': '{{ csrf_token() }}'
            },
            body: JSON.stringify({
                status: newStatus
            })
        })
        .then(response => {
            if (!response.ok) {
                throw new Error(`HTTP error! Status: ${response.status}`);
            }
            return response.json();
        })
        .then(data => {
            if (data.success) {
                updateDriverUI(driverId, newStatus, button);
                showToast(`Driver ${newStatus ? 'activated' : 'deactivated'} successfully!`,
                    newStatus ? "#28a745" : "#dc3545");
            } else {
                throw new Error('Failed to update status');
            }
        })
        .catch(error => {
            console.error('Error:', error);
            showToast("An error occurred. Please try again.", "#ff4d4d");
        })
        .finally(() => {
            // Reset button state
            setLoadingState(button, buttonText, spinner, false);
        });
}

// Helper function: Update driver row in the UI
function updateDriverUI(driverId, newStatus, button) {
    const row = document.getElementById(`driver-${driverId}`);
    const badge = row.querySelector('span.badge');
    const buttonText = button.querySelector('.button-text');

    // Update badge text and style
    badge.className = newStatus ? 'badge bg-success' : 'badge bg-danger';
    badge.textContent = newStatus ? 'Active' : 'Inactive';

    // Update button class and text
    button.className = newStatus ? 'btn btn-sm btn-danger' : 'btn btn-sm btn-success';
    buttonText.textContent = newStatus ? 'Deactivate' : 'Activate';

    // Adjust button's onclick behavior
    button.setAttribute('onclick', `toggleStatus(this, ${driverId}, ${newStatus ? 0 : 1})`);
}

// Helper function: Show custom toast notification
function showToast(message, bgColor) {
    const toast = document.createElement('div');
    toast.className = 'toast toast-slide-in'; // Add animation class
    toast.style.backgroundColor = bgColor;
    toast.innerText = message;

    // Append toast to the container
    const toastContainer = document.getElementById('toast-container');
    toastContainer.appendChild(toast);

    // Show the toast
    setTimeout(() => {
        toast.classList.add('show');
    }, 100);

    // Hide the toast after 3 seconds
    setTimeout(() => {
        toast.classList.remove('show');
        toast.classList.add('toast-fade-out'); // Add fade-out class
        setTimeout(() => {
            toastContainer.removeChild(toast);
        }, 500); // Wait for fade-out transition
    }, 3000);
}

// Helper function: Set button loading state
function setLoadingState(button, buttonText, spinner, isLoading) {
    button.disabled = isLoading;
    buttonText.classList.toggle('d-none', isLoading);
    spinner.classList.toggle('d-none', !isLoading);
}

// Search functionality
document.getElementById('searchInput').addEventListener('keyup', function() {
    const filter = this.value.toLowerCase();
    const rows = document.querySelectorAll('#driversTable tbody tr');

    rows.forEach(row => {
        const name = row.cells[0].textContent.toLowerCase();
        const email = row.cells[1].textContent.toLowerCase();
        const phone = row.cells[2].textContent.toLowerCase();

        if (name.includes(filter) || email.includes(filter) || phone.includes(filter)) {
            row.style.display = '';
        } else {
            row.style.display = 'none';
        }
    });
});
</script>
@endsection