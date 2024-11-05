<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateRidePricesTable extends Migration
{
    public function up()
    {
        Schema::create('ride_prices', function (Blueprint $table) {
            $table->id();
            $table->string('request_id');
            $table->string('driver_id');
            $table->decimal('price', 10, 2);
            $table->timestamps();
            
            // Unique constraint to prevent duplicate prices for same request-driver pair
            $table->unique(['request_id', 'driver_id']);
        });
    }

    public function down()
    {
        Schema::dropIfExists('ride_prices');
    }
} 