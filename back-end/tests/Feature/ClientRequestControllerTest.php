<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\User_Request;
use App\Models\Driver;
use App\Models\DriverRequest;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ClientRequestControllerTest extends TestCase
{
    use RefreshDatabase;

    protected $user;

    protected function setUp(): void
    {
        parent::setUp();
        $this->user = User::factory()->create();
    }

    public function test_client_can_send_request()
    {
        $response = $this->postJson('/api/client/request', [
            'from' => 'Location A',
            'destination' => 'Location B',
            'material_type' => 'Some Material',
            'car_type' => 'Sedan',
            'latitude' => '12.34',
            'longitude' => '56.78',
            'token' => $this->user->uid, // Assuming the user has a 'uid' token
        ]);

        $response->assertStatus(201)
                 ->assertJsonStructure(['message', 'ride_request']);
    }

    public function test_client_can_get_driver_responses()
    {
        $userRequest = User_Request::factory()->create(['user_id' => $this->user->id]);

        DriverRequest::create([
            'driver_id' => Driver::factory()->create()->id,
            'status' => 'pending',
            'accepted_user_ids' => json_encode([['user_id' => $this->user->id]])
        ]);

        $response = $this->getJson('/api/client/driver-responses', [
            'token' => $this->user->uid,
        ]);

        $response->assertStatus(200)
                 ->assertJsonStructure([['driver_id', 'user_id']]);
    }

    public function test_client_can_confirm_driver()
    {
        $userRequest = User_Request::factory()->create(['user_id' => $this->user->id, 'status' => 'pending']);
        $driverRequest = DriverRequest::create([
            'driver_id' => Driver::factory()->create()->id,
            'status' => 'pending',
            'accepted_user_ids' => json_encode([['user_id' => $this->user->id]])
        ]);

        $response = $this->postJson('/api/client/confirm-driver', [
            'driver_id' => $driverRequest->driver_id,
            'token' => $this->user->uid,
        ]);

        $response->assertStatus(200)
                 ->assertJson(['message' => 'Driver confirmed successfully']);
    }

    public function test_client_can_cancel_request()
    {
        $userRequest = User_Request::factory()->create(['user_id' => $this->user->id, 'status' => 'pending']);

        $response = $this->postJson('/api/client/cancel', [
            'token' => $this->user->uid,
        ]);

        $response->assertStatus(200)
                 ->assertJson(['message' => 'Request cancelled successfully']);
    }
}
