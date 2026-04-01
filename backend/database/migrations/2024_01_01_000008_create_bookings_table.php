<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('bookings', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('user_id')->constrained('profiles')->cascadeOnDelete();
            $table->foreignUuid('provider_id')->nullable()->constrained('profiles')->nullOnDelete();
            $table->uuid('listing_id')->nullable();
            $table->enum('listing_type', ['stay', 'vehicle', 'event', 'property'])->nullable();
            $table->date('check_in')->nullable();
            $table->date('check_out')->nullable();
            $table->integer('guests')->default(1);
            $table->decimal('total_price', 10, 2);
            $table->enum('status', ['pending', 'confirmed', 'cancelled', 'completed'])->default('pending');
            $table->enum('payment_status', ['pending', 'completed', 'refunded', 'failed'])->default('pending');
            $table->string('payment_method')->nullable();
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['listing_id', 'listing_type']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('bookings');
    }
};
