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
        // Create the drivers table
        Schema::create('drivers', function (Blueprint $table) {
            $table->id();
            $table->uuid('uid')->unique();
            $table->string('first_name');
            $table->string('last_name');
            $table->string('password');
            $table->string('phone_number')->unique();
            // $table->string('driver_id')->unique(); // Ensure this is unique, if applicable
            $table->boolean('verified')->default(0);
            $table->boolean('status')->default(0);
            $table->string('id_card_image_path')->nullable(); // Make this nullable if not mandatory
            $table->string('car_type');
            $table->string('driver_license_photo');
            $table->string('car_plate_photo');
            $table->string('user_photo');
            $table->boolean('approved')->default(false);
            $table->string('otp')->nullable();
            $table->timestamps();
            $table->timestamp('last_active')->nullable();
            $table->boolean('is_online')->default(false); 
        });

        // Create the password_reset_tokens table
        Schema::create('drivers_password_reset_tokens', function (Blueprint $table) {
            $table->id(); // Auto-incrementing ID
            $table->foreignId('driver_id')->constrained('drivers')->onDelete('cascade'); // Foreign key reference to drivers
            $table->string('token')->unique(); // Token must be unique
            $table->timestamp('created_at')->nullable(); // Timestamp for token creation
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        // Drop the password_reset_tokens table first, then drop the drivers table
        Schema::dropIfExists('drivers_password_reset_tokens');
        Schema::dropIfExists('drivers');
        Schema::table('drivers', function (Blueprint $table) {
            $table->dropColumn('uid');
            $table->dropColumn('approved');
        });
    }
};