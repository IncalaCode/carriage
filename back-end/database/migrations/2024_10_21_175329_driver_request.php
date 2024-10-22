<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;


class driverrequest extends Migration
{


    public function up(): void
    {
        Schema::create('drivers_request', function (Blueprint $table) {
            $table->id();
            $table->bigInteger('driver_id')->unique();  // Unique Driver ID
            $table->decimal('longitude', 10, 8);  // Driver's longitude location
            $table->decimal('latitude', 11, 8);  // Driver's latitude location
            $table->string('car_type');  // Type of car driver uses
            $table->enum('status', ['pending', 'locked', 'completed'])->default('pending');  // Status of the driver
            $table->json('accepted_user_ids')->nullable();  // User who was accepted by the driver
            $table->foreignId('locked_user_id')->nullable()->constrained('users'); // List of locked users as JSON
            $table->timestamps();
        });
    }


    public function down(): void
    {
        Schema::dropIfExists('drivers');
    }
};