<?php

namespace Database\Seeders;

use App\Models\PlatformSetting;
use App\Models\Profile;
use App\Models\TaxiVehicleCategory;
use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // Create admin user
        $admin = User::create([
            'name' => 'PearlHub Admin',
            'email' => 'admin@pearlhub.lk',
            'password' => Hash::make('password'),
        ]);

        Profile::create([
            'id' => $admin->id,
            'full_name' => 'PearlHub Admin',
            'email' => 'admin@pearlhub.lk',
            'role' => 'admin',
            'verified' => true,
        ]);

        // Create test customer
        $customer = User::create([
            'name' => 'Test Customer',
            'email' => 'customer@pearlhub.lk',
            'password' => Hash::make('password'),
        ]);

        Profile::create([
            'id' => $customer->id,
            'full_name' => 'Test Customer',
            'email' => 'customer@pearlhub.lk',
            'role' => 'customer',
        ]);

        // Create test provider
        $provider = User::create([
            'name' => 'Test Provider',
            'email' => 'provider@pearlhub.lk',
            'password' => Hash::make('password'),
        ]);

        Profile::create([
            'id' => $provider->id,
            'full_name' => 'Test Provider',
            'email' => 'provider@pearlhub.lk',
            'role' => 'stays_provider',
            'provider_tier' => 'gold',
        ]);

        // Seed 13 taxi vehicle categories
        $categories = [
            ['name' => 'Tuk Tuk', 'slug' => 'tuk-tuk', 'base_fare' => 100, 'per_km_rate' => 50, 'per_minute_rate' => 3, 'max_passengers' => 3, 'sort_order' => 1],
            ['name' => 'Mini', 'slug' => 'mini', 'base_fare' => 200, 'per_km_rate' => 60, 'per_minute_rate' => 4, 'max_passengers' => 4, 'sort_order' => 2],
            ['name' => 'Sedan', 'slug' => 'sedan', 'base_fare' => 300, 'per_km_rate' => 70, 'per_minute_rate' => 5, 'max_passengers' => 4, 'sort_order' => 3],
            ['name' => 'Premium', 'slug' => 'premium', 'base_fare' => 500, 'per_km_rate' => 100, 'per_minute_rate' => 7, 'max_passengers' => 4, 'sort_order' => 4],
            ['name' => 'SUV', 'slug' => 'suv', 'base_fare' => 450, 'per_km_rate' => 90, 'per_minute_rate' => 6, 'max_passengers' => 6, 'sort_order' => 5],
            ['name' => 'Van', 'slug' => 'van', 'base_fare' => 500, 'per_km_rate' => 85, 'per_minute_rate' => 6, 'max_passengers' => 8, 'sort_order' => 6],
            ['name' => 'Mini Bus', 'slug' => 'mini-bus', 'base_fare' => 800, 'per_km_rate' => 120, 'per_minute_rate' => 8, 'max_passengers' => 15, 'sort_order' => 7],
            ['name' => 'Luxury', 'slug' => 'luxury', 'base_fare' => 1000, 'per_km_rate' => 150, 'per_minute_rate' => 10, 'max_passengers' => 4, 'sort_order' => 8],
            ['name' => 'Motorcycle', 'slug' => 'motorcycle', 'base_fare' => 80, 'per_km_rate' => 40, 'per_minute_rate' => 2, 'max_passengers' => 1, 'sort_order' => 9],
            ['name' => 'Women Only', 'slug' => 'women-only', 'base_fare' => 300, 'per_km_rate' => 70, 'per_minute_rate' => 5, 'max_passengers' => 4, 'sort_order' => 10],
            ['name' => 'Eco', 'slug' => 'eco', 'base_fare' => 250, 'per_km_rate' => 55, 'per_minute_rate' => 4, 'max_passengers' => 4, 'sort_order' => 11],
            ['name' => 'Parcel', 'slug' => 'parcel', 'base_fare' => 150, 'per_km_rate' => 45, 'per_minute_rate' => 0, 'max_passengers' => 0, 'sort_order' => 12],
            ['name' => 'Airport Transfer', 'slug' => 'airport-transfer', 'base_fare' => 800, 'per_km_rate' => 80, 'per_minute_rate' => 5, 'max_passengers' => 4, 'sort_order' => 13],
        ];

        foreach ($categories as $cat) {
            TaxiVehicleCategory::create($cat);
        }

        // Platform settings
        $settings = [
            'map_provider' => 'osm',
            'commission_rate' => '10',
            'taxi_commission_rate' => '15',
            'currency' => 'LKR',
            'platform_name' => 'PearlHub',
            'support_email' => 'support@pearlhub.lk',
            'support_phone' => '+94 11 234 5678',
        ];

        foreach ($settings as $key => $value) {
            PlatformSetting::create(['key' => $key, 'value' => $value]);
        }
    }
}
