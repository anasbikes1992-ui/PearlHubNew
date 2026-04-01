<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('stays_listings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('profiles')->cascadeOnDelete();
            $table->string('title');
            $table->string('name')->nullable();
            $table->text('description')->nullable();
            $table->enum('stay_type', [
                'hotel', 'villa', 'apartment', 'guest_house', 'boutique', 'resort', 'hostel',
            ])->default('hotel');
            $table->integer('stars')->nullable();
            $table->decimal('price_per_night', 10, 2);
            $table->string('location');
            $table->decimal('lat', 10, 8)->nullable();
            $table->decimal('lng', 11, 8)->nullable();
            $table->integer('rooms')->default(1);
            $table->json('amenities')->nullable();
            $table->json('images')->nullable();
            $table->boolean('approved')->default(false);
            $table->enum('moderation_status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('admin_note')->nullable();
            $table->boolean('active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('stays_listings');
    }
};
