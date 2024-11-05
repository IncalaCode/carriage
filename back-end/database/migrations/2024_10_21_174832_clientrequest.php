<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class clientrequest extends Migration
{

    public function up(): void
    {

        Schema::create('user_requests', function (Blueprint $table) {
            $table->id();
            $table->string('user_id');
            $table->string('from');  // Departure point
            $table->string('destination');  // Destination
            $table->string('material_type');  // Type of material being transported
            $table->string('car_type');  // Type of car requested
            $table->json('accepted_driver_ids')->nullable();  // Driver who accepted the request
            $table->string('locked_driver_id')->default(0);
            $table->enum('status', ['pending', 'locked', 'completed', "cancelled"])->default('pending');
            $table->timestamps();
        });
    }


    public function down(): void
    {
        Schema::dropIfExists('user_requests');
    }
};
