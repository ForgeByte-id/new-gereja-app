<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Admin GPI Yehuda',
                'username' => 'admin_yehuda',
                'password' => 'password123',
                'role' => 'admin',
                'nomor_kk' => '5171010000000001',
                'jenis_kelamin' => 'L',
                'usia' => 33,
                'alamat' => 'Denpasar, Bali',
            ]
        );

        User::query()->updateOrCreate(
            ['email' => 'jemaat@example.com'],
            [
                'name' => 'Jemaat GPI Yehuda',
                'username' => 'jemaat_yehuda',
                'password' => 'password123',
                'role' => 'jemaat',
                'nomor_kk' => '5171010000000002',
                'jenis_kelamin' => 'P',
                'usia' => 27,
                'alamat' => 'Badung, Bali',
            ]
        );
    }
}
