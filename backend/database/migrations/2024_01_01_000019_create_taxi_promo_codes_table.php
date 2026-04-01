<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('taxi_promo_codes', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('code')->unique();
            $table->integer('discount_percent');
            $table->decimal('max_discount', 10, 2)->nullable();
            $table->decimal('min_fare', 10, 2)->default(0);
            $table->timestamp('valid_from');
            $table->timestamp('valid_until');
            $table->integer('max_uses')->nullable();
            $table->integer('used_count')->default(0);
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('taxi_promo_codes');
    }
};
