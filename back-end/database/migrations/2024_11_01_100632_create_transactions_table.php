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
        Schema::create('transactions', function (Blueprint $table) {
            $table->id();
            $table->unsignedBigInteger('wallet_id')->index(); // Assuming each user has a wallet
            $table->decimal('amount', 10, 2);
            $table->enum('type', ['deposit', 'withdraw', 'pending'])->default('pending');
            $table->enum('status', ['completed', 'pending'])->default('pending');
            $table->string('tx_ref')->unique();
            $table->string('description')->nullable();
            $table->timestamps(); // Automatically adds created_at and updated_at
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('transactions');
    }
};