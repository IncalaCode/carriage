<?php

use Illuminate\Support\Facades\Http; // Use Laravel's Http facade if available

// Function to send a security code (OTP)
function otpSend( $to, $pre, $post, $sb = 0, $sa = 0, $ttl = 300, $len = 6, $t = 6, $callback = "") {
    $token = env('SMS_TOKEN'); 
    $sender = env("SMS_SENDER") or "";
    $from =  env("SMS_FROM") or "otp";

    $ch = curl_init();
    $url = 'https://api.afromessage.com/api/challenge';

    // Configure request
    $query = http_build_query([
        'from' => $from,
        'sender' => $sender,
        'to' => $to,
        'pr' => urlencode($pre),
        'ps' => urlencode($post),
        'sb' => $sb,
        'sa' => $sa,
        'ttl' => $ttl,
        'len' => $len,
        't' => $t,
        'callback' => $callback
    ]);

    curl_setopt($ch, CURLOPT_URL, $url . '?' . $query);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');

    // Request headers
    $headers = [
        'Authorization: Bearer ' . $token,
    ];
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    // Send request
    $result = curl_exec($ch);

    // Handle response
    if (curl_errno($ch)) {
        return 'Error: ' . curl_error($ch);
    } else {
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        switch ($http_code) {
            case 200:
                $data = json_decode($result, true);
                if ($data['acknowledge'] === 'success') {
                    return [
                        'status' => 'success',
                        'message' => 'otp  sended successfly',
                        
                    ];
                } else {
                    return [
                        'status' => 'failure',
                        'message' => 'otp failure: ' . implode(", ", $data['response']['errors'])
                    ];
                }
            default:
                return 'Other HTTP Code: ' . $http_code . "\nResponse: " . $result;
        }
    }

    // Finish
    curl_close($ch);
}

// Function to verify a security code
function verifySecurityCode($to, $verificationId, $code) {
    $token = env('SMS_TOKEN'); // Ensure the environment variable is defined in .env

    $ch = curl_init();
    $url = 'https://api.afromessage.com/api/verify';

    // Configure request
    $query = http_build_query([
        'to' => $to,
        'vc' => $verificationId,
        'code' => $code
    ]);

    curl_setopt($ch, CURLOPT_URL, $url . '?' . $query);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, 1);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');

    // Request headers
    $headers = [
        'Authorization: Bearer ' . $token,
    ];
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    // Send request
    $result = curl_exec($ch);

    // Handle response
    if (curl_errno($ch)) {
        return 'Error: ' . curl_error($ch);
    } else {
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
        switch ($http_code) {
            case 200:
                $data = json_decode($result, true);
                if ($data['acknowledge'] === 'success') {
                    return [
                        'status' => 'success',
                        'message' => 'Verification successful',
                        'verificationData' => $data['response']
                    ];
                } else {
                    return [
                        'status' => 'failure',
                        'message' => 'Verification failure: ' . implode(", ", $data['response']['errors'])
                    ];
                }
            default:
                return 'Other HTTP Code: ' . $http_code . "\nResponse: " . $result;
        }
    }

    // Finish
    curl_close($ch);
}

// // Example usage
// $from = ''; // Your identifier ID
// $sender = ''; // Your sender name
// $to = '+251925319177'; // Replace with actual recipient number
// $pre = 'Your code is'; // Prefix message
// $post = ''; // Postfix message
// $sb = 0; // Spaces before
// $sa = 0; // Spaces after
// $ttl = 300; // Time to live in seconds (5 minutes)
// $len = 6; // Length of the code
// $t = 0; // Code type (0 for numbers only)
// $callback = 'YOUR_CALLBACK_URL'; // Replace with your callback URL

// // Send the security code
// $response = otpSend($from, $sender, $to, $pre, $post, $sb, $sa, $ttl, $len, $t, $callback);
// echo json_encode($response);

// Uncomment below lines to verify later
// $verificationId = 'VERIFICATION_ID'; // Replace with actual verification ID received from otpSend response
// $codeToVerify = ''; // Replace with actual code to verify
// $verificationResponse = verifySecurityCode($to, $verificationId, $codeToVerify);
// echo json_encode($verificationResponse);

?>