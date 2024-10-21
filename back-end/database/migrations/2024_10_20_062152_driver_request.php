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
        Schema::create('driver_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('driver_id')->constrained('drivers')->onDelete('cascade'); // Foreign key to drivers table
            $table->string('location');
            $table->foreignId('car_type')->constrained('drivers')->onDelete('cascade'); // Foreign key to car_types table
            $table->enum('status', ['pending', 'accepted', 'completed','offline',"lock"])->default('pending'); // Enum for status
            $table->json('RideRequest')->nullable(); 
            $table->enum('online_status' ,['online','offline'])->default('online');
            $table->string('user_id')->nullable(); 
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('driver_requests');
    }
};
