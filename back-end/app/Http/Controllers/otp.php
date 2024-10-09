<?php

if (!function_exists('otpSend')) {
    /**
     * Send OTP to the specified phone number.
     *
     * @param string $to
     * @param string $otp
     * @param string $domain
     * @param string $id
     * @return array
     */
    function otpSend($to, $otp, $domain, $id)
    {
        $server = 'https://sms.yegara.com/api3/send';
        $postData = array('to' => $to, 'otp' => $otp, 'id' => $id, 'domain' => $domain);
        $content = json_encode($postData);
        $curl = curl_init($server);
        curl_setopt($curl, CURLOPT_HEADER, false);
        curl_setopt($curl, CURLOPT_RETURNTRANSFER, true);
        curl_setopt($curl, CURLOPT_HTTPHEADER, array("Content-type: application/json"));
        curl_setopt($curl, CURLOPT_POST, true);
        curl_setopt($curl, CURLOPT_POSTFIELDS, $content);
        $json_response = curl_exec($curl);
        $status = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);

        return [$status, $json_response];
    }
}

var_dump(otpSend('0925319177', '1234', 'example.com', '1'));