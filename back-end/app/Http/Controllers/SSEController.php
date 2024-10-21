<?php

namespace App\Http\Controllers;

use App\Models\Driver;
use App\Models\User; // Assuming 'User' is the client model
use App\Models\RideRequest;
use Illuminate\Http\Request as HttpRequest;

class SSEController extends Controller
{
    protected static $driverConnections = [];
    protected static $clientConnections = [];

    // Stream SSE for Drivers
    public function streamDriverRequests($driverId)
    {
        // if (!$this->verifyDriver($driverId)) {
        //     return response()->json(['error' => 'Driver not found or invalid'], 404);
        // }

        $this->setSSEHeaders();

        static::$driverConnections[$driverId] = fopen('php://output', 'w');

        echo "data: {\"message\": \"Connected as Driver ID: {$driverId}\"}\n\n";
        ob_flush();
        flush();

        $this->keepConnectionAlive($driverId, 'driver');
    }

    // Stream SSE for Clients
    public function streamClientUpdates($clientId)
    {
        // if (!$this->verifyClient($clientId)) {
        //     return response()->json(['error' => 'Client not found or invalid'], 404);
        // }

        $this->setSSEHeaders();

        static::$clientConnections[$clientId] = fopen('php://output', 'w');

        echo "data: {\"message\": \"Connected as Client ID: {$clientId}\"}\n\n";
        ob_flush();
        flush();

        $this->keepConnectionAlive($clientId, 'client');
    }

    // Verify Driver Exists
    private function verifyDriver($driverId)
    {
        return Driver::where('id', $driverId)->exists();
    }

    // Verify Client Exists
    private function verifyClient($clientId)
    {
        return User::where('id', $clientId)->exists();
    }

    // Helper: Set SSE Headers
    private function setSSEHeaders()
    {
        header('Access-Control-Allow-Origin: *');
        header('Content-Type: text/event-stream');
        header('Cache-Control: no-cache');
        header('Connection: keep-alive');
        header('X-Accel-Buffering: no'); // Disable buffering for Nginx
    }

    // Helper: Keep SSE Connection Alive
    private function keepConnectionAlive($id, $type)
    {
        while (true) {
            if (connection_aborted()) {
                if ($type === 'driver') {
                    fclose(static::$driverConnections[$id]);
                    unset(static::$driverConnections[$id]);
                } else {
                    fclose(static::$clientConnections[$id]);
                    unset(static::$clientConnections[$id]);
                }
                break;
            }
            echo "event: ping\n"; // Keep connection alive with ping
            echo "data: {}\n\n";
            ob_flush();
            flush();
            sleep(1); // Maintain connection with periodic pings
        }
    }

    // Notify Driver by Driver ID
    public static function notifyDriver($driverId, RideRequest $rideRequest)
    {
        if (isset(static::$driverConnections[$driverId])) {
            $connection = static::$driverConnections[$driverId];
            fwrite($connection, "event: new_request\n");
            fwrite($connection, 'data: ' . json_encode($rideRequest) . "\n\n");
            fflush($connection);
        }
    }

    // Notify Client by Client ID
    public static function notifyClient($clientId, RideRequest $rideRequest)
    {
        if (isset(static::$clientConnections[$clientId])) {
            $connection = static::$clientConnections[$clientId];
            fwrite($connection, "event: driver_response\n");
            fwrite($connection, 'data: ' . json_encode($rideRequest) . "\n\n");
            fflush($connection);
        }
    }
}
