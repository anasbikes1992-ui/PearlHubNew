<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('profiles', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('full_name')->nullable();
            $table->string('email')->unique();
            $table->string('phone')->nullable();
            $table->enum('role', [
                'customer',
                'stays_provider',
                'vehicle_provider',
                'event_organizer',
                'property_owner',
                'taxi_driver',
                'sme_owner',
                'admin',
            ])->default('customer');
            $table->string('avatar_url')->nullable();
            $table->string('nic')->nullable();
            $table->boolean('verified')->default(false);
            $table->json('verification_badges')->nullable();
            $table->enum('provider_tier', ['basic', 'silver', 'gold', 'platinum'])->default('basic');
            $table->string('sltda_number')->nullable();
            $table->integer('total_bookings')->default(0);
            $table->decimal('avg_rating', 3, 2)->default(0);
            $table->string('preferred_language')->default('en');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('profiles');
    }
};
