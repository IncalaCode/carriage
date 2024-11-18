@extends('layouts.master')

@section('title')
Dashboard
@endsection

@section('content')
<div style="margin-top: 60px; align-content: center">
    <!DOCTYPE html>
    <html lang="en">

    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Change Password & Email</title>
        <!-- Bootstrap CSS -->
        <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
        <style>
        body {
            background-color: #f4f6f9;
        }

        .card {
            margin-top: 50px;
        }

        .form-control:focus {
            box-shadow: none;
            border-color: #28a745;
        }

        .btn-custom {
            background-color: #28a745;
            color: #fff;
        }

        .btn-custom:hover {
            background-color: #218838;
        }

        .spinner-border {
            display: none;
            width: 1rem;
            height: 1rem;
        }
        </style>
    </head>

    <body>
        <div class="container">
            <div class="row justify-content-center">
                <div class="col-md-6">
                    <div class="card shadow">
                        <div class="card-header text-center">
                            <h4>Change Password & Email</h4>
                        </div>
                        <div class="card-body">
                            <!-- Alert messages -->
                            <div id="alertMessage" class="alert d-none" role="alert"></div>

                            <form id="changeForm" method="POST" action="./update">
                                @csrf
                                <!-- Email input -->
                                <div class="mb-3">
                                    <label for="email" class="form-label">New Email</label>
                                    <input type="email" class="form-control" id="email" name="email"
                                        placeholder="Enter new email" required>
                                </div>

                                <!-- Old password input -->
                                <div class="mb-3">
                                    <label for="currentPassword" class="form-label">Current Password</label>
                                    <input type="password" class="form-control" id="currentPassword"
                                        name="currentPassword" placeholder="Enter current password" minlength="8" required>
                                </div>

                                <!-- New password input -->
                                <div class="mb-3">
                                    <label for="newPassword" class="form-label">New Password</label>
                                    <input type="password" class="form-control" id="newPassword" name="newPassword"
                                        placeholder="Enter new password" minlength="8" required>
                                </div>

                                <!-- Confirm new password input -->
                                <div class="mb-3">
                                    <label for="confirmPassword" class="form-label">Confirm New Password</label>
                                    <input type="password" class="form-control" id="confirmPassword"
                                        name="password_confirmation" placeholder="Confirm new password" minlength="8" required>
                                </div>

                                <!-- Submit button -->
                                <div class="text-center">
                                    <button type="submit" class="btn btn-custom" id="submitButton">
                                        <span id="buttonText">Update</span>
                                        <div class="spinner-border text-light" role="status" id="loadingSpinner">
                                            <span class="visually-hidden">Loading...</span>
                                        </div>
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bootstrap JS -->
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
        <script>
            document.getElementById('changeForm').addEventListener('submit',async function (e) {
                e.preventDefault(); // Prevent default form submission

                const newPassword = document.getElementById('newPassword').value;
                const confirmPassword = document.getElementById('confirmPassword').value;
                const alertMessage = document.getElementById('alertMessage');
                const submitButton = document.getElementById('submitButton');
                const buttonText = document.getElementById('buttonText');
                const loadingSpinner = document.getElementById('loadingSpinner');

                // Reset alert
                alertMessage.classList.add('d-none');

                if (newPassword !== confirmPassword) {
                    alertMessage.className = 'alert alert-danger';
                    alertMessage.textContent = 'New Password and Confirm Password do not match!';
                    alertMessage.classList.remove('d-none');
                    return;
                }

                // Show loading spinner
                buttonText.textContent = 'Updating...';
                loadingSpinner.style.display = 'inline-block';
                submitButton.disabled = true;

                const formData = new FormData(this);

                try {
               var response =  await fetch(this.action, {
                    method: 'POST',
                    headers: {
                        'X-CSRF-TOKEN': document.getElementsByName("_token"),
                    },
                    body: formData,
                })

                 var data = await response.json();
        
                    // Hide loading spinner
                    buttonText.textContent = 'Update';
                    loadingSpinner.style.display = 'none';
                    submitButton.disabled = false;

                    if (data.success) {
                        alertMessage.className = 'alert alert-success';
                        alertMessage.textContent = 'Password and Email updated successfully!';
                        alertMessage.classList.remove('d-none');
                    } else {
                        alertMessage.className = 'alert alert-danger';
                        alertMessage.textContent = data.message || 'An error occurred. Please try again.';
                        alertMessage.classList.remove('d-none');
                    }
            
                }catch(error){
                    console.error('Error:', error);

                    // Hide loading spinner
                    buttonText.textContent = 'Update';
                    loadingSpinner.style.display = 'none';
                    submitButton.disabled = false;

                    alertMessage.className = 'alert alert-danger';
                    alertMessage.textContent = 'Failed to update. Please try again.';
                    alertMessage.classList.remove('d-none');
                };
            });
        </script>
    </body>

    </html>
</div>
@endsection

@section('scripts')
@endsection
