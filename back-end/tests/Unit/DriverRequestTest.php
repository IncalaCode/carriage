<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Models\Driver;
use App\Models\user_Request;
use App\Models\driverRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

class DriverRequestTest extends TestCase
{
    use RefreshDatabase;

    protected $driver;
    protected $token;

    protected function setUp(): void
    {
        parent::setUp();
        
        // Bypass auth middleware for testing
        Route::middleware('auth')->post('/driver/handle-request', [driver_request::class, 'handleRequest']);
        
        // Create test driver
        $this->driver = Driver::factory()->create();
        $this->token = $this->driver->uid;
    }

    public function test_update_driver_status()
    {
        $statusData = [
            'token' => $this->token,
            'action' => 'update_status',
            'is_online' => true,
            'latitude' => '12.9716',
            'longitude' => '77.5946'
        ];

        $response = $this->postJson('/api/driver/handle-request', $statusData);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'message',
                'is_online'
            ]);

        $driverRequest = driverRequest::where('driver_id', $this->driver->id)->first();
        $this->assertTrue($driverRequest->is_online);
    }

    public function test_update_preferences()
    {
        $preferencesData = [
            'token' => $this->token,
            'action' => 'update_preferences',
            'max_requests' => 3,
            'material_types' => ['Furniture', 'Electronics'],
            'max_distance' => 10
        ];

        $response = $this->postJson('/api/driver/handle-request', $preferencesData);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'message',
                'preferences'
            ]);
    }

    public function test_accept_ride_request()
    {
        // Create a pending user request
        $userRequest = user_Request::factory()->create([
            'status' => 'pending',
            'accepted_driver_ids' => json_encode([['driver_id' => $this->driver->id]])
        ]);

        $acceptData = [
            'token' => $this->token,
            'action' => 'accept_request',
            'user_id' => $userRequest->user_id,
            'price' => 100
        ];

        $response = $this->postJson('/api/driver/handle-request', $acceptData);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'message'
            ]);
    }

    public function test_get_matching_requests()
    {
        // Create driver request with online status
        driverRequest::factory()->create([
            'driver_id' => $this->driver->id,
            'is_online' => true,
            'car_type' => 'Truck'
        ]);

        // Create some matching user requests
        user_Request::factory()->count(3)->create([
            'status' => 'pending',
            'car_type' => 'Truck'
        ]);

        $response = $this->postJson('/api/driver/handle-request', [
            'token' => $this->token,
            'latitude' => '12.9716',
            'longitude' => '77.5946'
        ]);

        $response->assertStatus(200)
            ->assertJsonStructure([
                'status',
                'message',
                'requests' => [
                    '*' => [
                        'request_id',
                        'pickup',
                        'destination',
                        'material_type',
                        'car_type',
                        'created_at',
                        'expires_at'
                    ]
                ]
            ]);
    }

    public function test_cancel_acceptance()
    {
        // Setup a pending request with driver acceptance
        $userRequest = user_Request::factory()->create([
            'status' => 'pending',
            'accepted_driver_ids' => json_encode([['driver_id' => $this->driver->id]])
        ]);

        $response = $this->postJson('/api/driver/handle-request', [
            'token' => $this->token,
            'action' => 'cancel_acceptance'
        ]);

        $response->assertStatus(200)
            ->assertJson([
                'message' => 'Acceptance cancelled successfully'
            ]);
    }

    public function test_send_tracking_updates()
    {
        $trackingData = [
            'token' => $this->token,
            'action' => 'send_tracking',
            'latitude' => '12.9716',
            'longitude' => '77.5946'
        ];

        $response = $this->postJson('/api/driver/handle-request', $trackingData);

        $response->assertStatus(200)
            ->assertJson([
                'status' => true
            ]);
    }

    public function test_unauthorized_access()
    {
        $response = $this->postJson('/api/driver/handle-request', [
            'token' => 'invalid_token',
            'action' => 'update_status'
        ]);

        $response->assertStatus(401);
    }
} 