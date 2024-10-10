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
        if (!Schema::hasTable('password_reset_tokens')) {
            // Create the drivers table
            Schema::create('drivers', function (Blueprint $table) {
                $table->id();
                $table->string('first_name');
                $table->string('last_name');
                $table->string('password');
                $table->string('phone_number')->unique();
                $table->string('driver_id');
                $table->string('id_card_image_path');  // for ID image scan
                $table->timestamps();
            });
        }

        // Create the password_reset_tokens table
        Schema::create('drivers_password_reset_tokens', function (Blueprint $table) {
            $table->id(); // Add an auto-incrementing ID
            $table->foreignId('driver_id')->constrained()->onDelete('cascade'); // Foreign key reference to drivers
            $table->string('token')->unique(); // Token must be unique
            $table->timestamp('created_at')->nullable(); // Timestamp to track when the token was created
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('drivers');
    }
};