<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>App Maintenance</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            background-color: #f4f6f9;
            text-align: center;
            padding: 50px;
        }
        .container {
            background-color: #fff;
            padding: 20px;
            border-radius: 10px;
            box-shadow: 0 4px 8px rgba(0,0,0,0.1);
        }
        h1 {
            color: #ff0000;
        }
        p {
            font-size: 18px;
        }
        .btn-contact {
            margin-top: 20px;
            padding: 10px 20px;
            background-color: #007bff;
            color: white;
            font-size: 16px;
            text-decoration: none;
            border-radius: 5px;
            cursor: pointer;
        }
        .btn-contact:hover {
            background-color: #0056b3;
        }
        .payment-warning {
            margin-top: 30px;
            font-size: 18px;
            color: #ff4500;
        }
    </style>
</head>
<body>

<div class="container">
    <h1>We are currently performing a pay break</h1>
    <p>read the below pargraph for more  info!</p>

    <!-- Payment or Contact warning -->
    <div class="payment-warning">
        <p><strong>Attention:</strong> Our services require a payment to continue usage after 4 months. Please make the required payment to continue.</p>
        <p>If you have already paid, please contact support if you face any issues. Otherwise, you can make a payment to continue your usage.</p>
        <a href="mailto:support@example.com" class="btn-contact">Contact Support </a>
    </div>
</div>

</body>
</html>
