<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('ride_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade');
            $table->string('from_location');
            $table->string('to_location');
            $table->string('material_type');
            $table->string('car_type');
            $table->enum('status', ['pending', 'accepted', 'lock', 'completed'])->default('pending'); // Enum for status
            $table->json('accepted_driver_ids')->nullable(); // Store multiple driver IDs
            $table->json('locked_driver_ids')->nullable(); // Store multiple driver IDs
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('ride_requests');
    }
};
