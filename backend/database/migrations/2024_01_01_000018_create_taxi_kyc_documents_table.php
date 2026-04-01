<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('taxi_kyc_documents', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignUuid('driver_id')->unique()->constrained('profiles')->cascadeOnDelete();
            $table->string('license_number');
            $table->date('license_expiry');
            $table->string('vehicle_registration');
            $table->string('vehicle_type');
            $table->string('insurance_number')->nullable();
            $table->date('insurance_expiry')->nullable();
            $table->string('nic_front_url')->nullable();
            $table->string('nic_back_url')->nullable();
            $table->string('license_front_url')->nullable();
            $table->enum('status', ['pending', 'approved', 'rejected'])->default('pending');
            $table->text('admin_note')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('taxi_kyc_documents');
    }
};
