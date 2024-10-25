<?php

use Illuminate\Support\Facades\Http; // Use Laravel's Http facade if available

// Function to send a security code (OTP)
function otpSendsecurity($to, $pre, $post, $sb = 0, $sa = 0, $ttl = 300, $len = 6, $t = 6, $callback = "")
{
    $token = env('SMS_TOKEN');
    $sender = env("SMS_SENDER") or "";
    $from =  env("SMS_FROM") or "otp";

    // $token = "eyJhbGciOiJIUzI1NiJ9.eyJpZGVudGlmaWVyIjoiOHFEd1ladkZXTG5yZENMaUZDNFduYldabUk4U2pxeWMiLCJleHAiOjE4ODYyMjMyNDcsImlhdCI6MTcyODQ1Njg0NywianRpIjoiYTViMTM0NjQtNTVlYS00YzAwLTk0ZDAtMWZiYzVhNzY2NTA5In0.7gTtkf83jnzBro1oRq9WCTrJF26epR5j2EQpMGm3i5s";
    // $sender ="";
    // $from =  "";

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

function otpSend($to, $message, $callback = '') {
    $ch = curl_init();
    $url = 'https://api.afromessage.com/api/send';

    // Get values from environment variables
    $token = getenv('AFRO_MESSAGE_TOKEN');
    $from = getenv('AFRO_MESSAGE_FROM');
    $sender = getenv('AFRO_MESSAGE_SENDER');

    // URL encode the message
    $encodedMessage = curl_escape($ch, $message);

    // Construct the full URL with query parameters
    $fullUrl = "{$url}?from={$from}&sender={$sender}&to={$to}&message={$encodedMessage}&callback={$callback}";

    // Set cURL options
    curl_setopt($ch, CURLOPT_URL, $fullUrl);
    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_CUSTOMREQUEST, 'GET');

    // Add the Authorization header
    $headers = [
        'Authorization: Bearer ' . $token
    ];
    curl_setopt($ch, CURLOPT_HTTPHEADER, $headers);

    // Execute the request and get the response
    $result = curl_exec($ch);
    $response = [];

    if (curl_errno($ch)) {
        // Handle cURL errors
        $response = [
            'status' => 'error',
            'message' => curl_error($ch),
            'http_code' => null,
            'data' => null
        ];
    } else {
        $http_code = curl_getinfo($ch, CURLINFO_HTTP_CODE);

        if ($http_code === 200) {
            $data = json_decode($result, true);
            if (isset($data['acknowledge']) && $data['acknowledge'] === 'success') {
                $response = [
                    'status' => 'success',
                    'message' => 'Message sent successfully.',
                    'http_code' => $http_code,
                    'data' => $data
                ];
            } else {
                $response = [
                    'status' => 'failure',
                    'message' => 'Message sending failed.',
                    'http_code' => $http_code,
                    'data' => $data
                ];
            }
        } else {
            $response = [
                'status' => 'error',
                'message' => 'Unexpected HTTP response code.',
                'http_code' => $http_code,
                'data' => json_decode($result, true)
            ];
        }
    }
    curl_close($ch);


    return $response;
}


// $to = '+251925319177'; 
// $message = 'Hello, this is a test message!';
// $callback = '';

// // Call the function to send SMS
// otpSend($to, $message, $callback);




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
// $response = otpSend($to, $post,  $pre);
// echo json_encode($response);