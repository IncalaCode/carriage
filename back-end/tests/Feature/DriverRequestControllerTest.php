<?php

namespace Tests\Feature;

use App\Models\Driver;
use App\Models\User_Request;
use App\Models\DriverRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;

class DriverRequestControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $driver;

    protected function setUp(): void
    {
        parent::setUp();
        $this->driver = Driver::factory()->create();
    }

    public function test_driver_can_send_request()
    {
        $response = $this->postJson('/api/driver/request', [
            'latitude' => '12.34',
            'longitude' => '56.78',
            'token' => $this->driver->uid, // Assuming the driver has a 'uid' token
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure(['message', 'ride_request']);
    }

    public function test_driver_can_accept_request()
    {
        $userRequest = User_Request::factory()->create(); // Create a user request for the test
        DriverRequest::create([
            'driver_id' => $this->driver->id,
            'status' => 'pending',
            'accepted_user_ids' => json_encode([])
        ]);

        $response = $this->postJson('/api/driver/accept', [
            'user_id' => $userRequest->user_id,
            'price' => 100,
            'token' => $this->driver->uid,
        ]);

        $response->assertStatus(200)
                 ->assertJson(['message' => 'Acceptance sent successfully, please wait for confirmation']);
    }

    public function test_driver_can_cancel_request()
    {
        DriverRequest::create([
            'driver_id' => $this->driver->id,
            'status' => 'pending',
        ]);

        $response = $this->postJson('/api/driver/cancel', [
            'token' => $this->driver->uid,
        ]);

        $response->assertStatus(200)
                 ->assertJson(['message' => 'Request cancelled successfully']);
    }
}
