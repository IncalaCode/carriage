<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateUserRequestsTable extends Migration
{

    public function up(): void
    {

        Schema::create('user_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('users')->onDelete('cascade');
            $table->string('from');  // Departure point
            $table->string('destination');  // Destination
            $table->string('material_type');  // Type of material being transported
            $table->string('car_type');  // Type of car requested
            $table->json('accepted_driver_ids')->nullable();  // Driver who accepted the request
            $table->foreignId('locked_driver_id')->nullable()->constrained('drivers'); // Drivers locked out
            $table->enum('status', ['pending', 'locked', 'completed'])->default('pending');
            $table->timestamps();
        });
    }


    public function down(): void
    {
        Schema::dropIfExists('user_requests');
    }
};