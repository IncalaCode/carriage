<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Referral Landing Page</title>
    
    <!-- Bootstrap CSS -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/css/bootstrap.min.css" rel="stylesheet">
    
    <style>
        .step-card {
            transition: transform 0.3s ease, background-color 0.3s ease;
            margin-bottom: 1rem;
        }
        .step-card:hover {
            transform: translateY(-5px);
            background-color: #f8f9fa;
        }
        .step-title {
            font-size: 1.5rem;
            font-weight: bold;
        }
    </style>
</head>
<body class="bg-light d-flex justify-content-center align-items-center vh-100">
    <div class="container">
        <div class="row justify-content-center">
            <div class="col-md-8">
                <!-- Step 1: Enter Phone Number -->
                <div class="card step-card" id="stepOneCard">
                    <div class="card-body text-center">
                        <h5 class="step-title">Step 1: Enter Your Phone Number</h5>
                        <p class="mb-4 text-muted">
                            To personalize your app experience, we need your phone number. This helps us link your account to your referrer.
                        </p>
                        <form id="referralForm" method="POST" action="/cache-referral">
                            <!-- CSRF Token -->
                            <input type="hidden" name="_token" value="CSRF_TOKEN_HERE">
                            <input type="hidden" name="referrer_id" value="{{ $driverId }}">
                            
                            <div class="mb-3">
                                <input type="text" id="phone" name="phone" class="form-control" 
                                    placeholder="e.g., +123456789" required>
                            </div>
                        </form>
                    </div>
                </div>
                
                <!-- Step 2: Download App -->
                <div class="card step-card" id="stepTwoCard">
                    <div class="card-body text-center">
                        <h5 class="step-title">Step 2: Download the App</h5>
                        <p class="mb-4 text-muted">
                            You're all set! Click below to download the app and start enjoying the benefits of your referral program.
                        </p>
                        <a href="#" class="btn btn-success w-100">Download App</a>
                    </div>
                </div>
            </div>
        </div>
    </div>
    
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0-alpha3/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- JavaScript -->
    <script>
        // Handle form submission and server interaction
        document.getElementById('phone').addEventListener('blur', function () {
            const referralForm = document.getElementById('referralForm');
            const phoneInput = document.getElementById('phone').value.trim();

            if (phoneInput === "") {
                alert("Please enter a valid phone number.");
                return;
            }

            fetch('/cache-referral', {
                method: 'POST',
                body: new FormData(referralForm),
                headers: {
                    'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value
                }
            })
            .then(response => {
                if (!response.ok) {
                    throw new Error("Server responded with an error.");
                }
                return response.json();
            })
            .then(data => {
                if (data.redirect_url) {
                    window.location.href = data.redirect_url;
                } else {
                    alert(data.message || "An error occurred.");
                }
            })
            .catch(error => {
                console.error("Error during submission:", error);
                alert("Failed to process your request. Please try again.");
            });
        });
    </script>
</body>
</html>












<!-- 
<form id="referralForm" method="POST" action="/cache-referral">
    @csrf
    <input type="hidden" name="referrer_id" value="{{ $driverId }}">
    <label for="phone">Enter Your Phone Number:</label>
    <input type="text" id="phone" name="phone" required>
    <button type="submit">Download App</button>
</form>

<script>
    document.getElementById('referralForm').addEventListener('submit', function(event) {
        event.preventDefault();

        fetch('/cache-referral', {
            method: 'POST',
            body: new FormData(this),
            headers: {
                'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value
            }
        }).then(response => response.json()).then(data => {
            if (data.redirect_url) {
                window.location.href = data.redirect_url;
            } else {
                alert(data.message);
            }
        });
    });
</script>  -->