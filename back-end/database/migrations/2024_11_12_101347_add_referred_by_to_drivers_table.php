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
        Schema::table('drivers', function (Blueprint $table) {
        $table->unsignedBigInteger('referred_by')->nullable()->index();
        $table->foreign('referred_by')->references('id')->on('drivers')->onDelete('cascade');
    });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('drivers', function (Blueprint $table) {
        $table->dropForeign(['referred_by']);
        $table->dropColumn('referred_by');
    });
    }
};
