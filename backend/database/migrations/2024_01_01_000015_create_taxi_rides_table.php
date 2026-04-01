<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('taxi_rides', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('rider_id')->constrained('profiles')->cascadeOnDelete();
            $table->foreignUuid('driver_id')->nullable()->constrained('profiles')->nullOnDelete();
            $table->foreignUuid('vehicle_category_id')->nullable()->constrained('taxi_vehicle_categories')->nullOnDelete();
            $table->string('vehicle_category_slug')->nullable();
            $table->decimal('pickup_lat', 10, 8);
            $table->decimal('pickup_lng', 11, 8);
            $table->string('pickup_address')->nullable();
            $table->decimal('dropoff_lat', 10, 8);
            $table->decimal('dropoff_lng', 11, 8);
            $table->string('dropoff_address')->nullable();
            $table->decimal('fare', 10, 2);
            $table->decimal('distance_km', 8, 2)->nullable();
            $table->integer('duration_minutes')->nullable();
            $table->enum('status', [
                'requested', 'accepted', 'arrived', 'in_progress', 'completed', 'cancelled',
            ])->default('requested');
            $table->boolean('is_parcel')->default(false);
            $table->json('parcel_details')->nullable();
            $table->json('stops')->nullable();
            $table->string('payment_method')->default('cash');
            $table->enum('payment_status', ['pending', 'completed', 'failed'])->default('pending');
            $table->decimal('surge_multiplier', 4, 2)->default(1.00);
            $table->timestamp('scheduled_for')->nullable();
            $table->string('promo_code')->nullable();
            $table->integer('rating')->nullable();
            $table->text('rating_comment')->nullable();
            $table->boolean('is_emergency_sos')->default(false);
            $table->timestamps();

            $table->index('status');
            $table->index('rider_id');
            $table->index('driver_id');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('taxi_rides');
    }
};
