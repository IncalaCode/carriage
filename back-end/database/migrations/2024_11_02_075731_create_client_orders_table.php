<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class CreateClientOrdersTable extends Migration
{
    public function up()
    {
        Schema::create('client_orders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->onDelete('cascade'); // Ensure user_id references users table
            $table->string('tx_ref');  // Add this line
            $table->decimal('amount', 10, 2);  // Add this line
            $table->string('status');  // Add this line
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('client_orders');
    }
}