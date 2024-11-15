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
        Schema::table('driverRequest', function (Blueprint $table) {
            $table->string('tx_ref')->nullable(); // Replace 'column_name' with the column after which you want to place `tx_ref`
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('driverRequest', function (Blueprint $table) {
            $table->dropColumn('tx_ref');
        });
    }
};