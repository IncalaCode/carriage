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
        Schema::table('client_orders', function (Blueprint $table) {
            $table->string('tx_ref')->after('user_id'); // Adjust the position as needed
            $table->decimal('amount', 10, 2)->after('tx_ref'); // Adjust the position as needed
            $table->string('status')->after('amount'); // Adjust the position as needed
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('client_orders', function (Blueprint $table) {
            $table->dropColumn(['tx_ref', 'amount', 'status']);
        });
    }
};