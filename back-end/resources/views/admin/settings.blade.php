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
                            <form id="changeForm" onsubmit="return validateForm()">
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
                                        name="currentPassword" placeholder="Enter current password" required>
                                </div>

                                <!-- New password input -->
                                <div class="mb-3">
                                    <label for="newPassword" class="form-label">New Password</label>
                                    <input type="password" class="form-control" id="newPassword" name="newPassword"
                                        placeholder="Enter new password" required>
                                </div>

                                <!-- Confirm new password input -->
                                <div class="mb-3">
                                    <label for="confirmPassword" class="form-label">Confirm New Password</label>
                                    <input type="password" class="form-control" id="confirmPassword"
                                        name="confirmPassword" placeholder="Confirm new password" required>
                                </div>

                                <!-- Submit button -->
                                <div class="text-center">
                                    <button type="submit" class="btn btn-custom">Update</button>
                                </div>
                            </form>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!-- Bootstrap JS -->
        <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

        <!-- JavaScript for validation -->
        <script>
        function validateForm() {
            const newPassword = document.getElementById("newPassword").value;
            const confirmPassword = document.getElementById("confirmPassword").value;

            if (newPassword !== confirmPassword) {
                alert("New password and confirm password do not match.");
                return false;
            }

            const email = document.getElementById("email").value;
            if (!validateEmail(email)) {
                alert("Please enter a valid email address.");
                return false;
            }

            return true; // Allow form submission
        }

        function validateEmail(email) {
            const re = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return re.test(String(email).toLowerCase());
        }
        </script>
    </body>

    </html>

</div>



@endsection

@section('scripts')
@endsection