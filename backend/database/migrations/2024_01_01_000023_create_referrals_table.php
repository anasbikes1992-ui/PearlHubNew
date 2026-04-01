<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('referrals', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('referrer_id')->constrained('profiles')->cascadeOnDelete();
            $table->foreignUuid('referred_id')->constrained('profiles')->cascadeOnDelete();
            $table->string('code');
            $table->enum('status', ['pending', 'completed', 'rewarded'])->default('pending');
            $table->integer('points_awarded')->default(0);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('referrals');
    }
};
