<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $adminPassword = env('ADMIN_PASSWORD', 'password123');
        if (!Hash::needsRehash($adminPassword)) {
            $adminPassword = Hash::make($adminPassword);
        }

        User::query()->updateOrCreate(
            ['email' => env('ADMIN_EMAIL', 'admin@example.com')],
            [
                'name' => env('ADMIN_NAME', 'Admin GPI Yehuda'),
                'username' => env('ADMIN_USERNAME', 'admin_yehuda'),
                'password' => $adminPassword,
                'role' => 'admin',
                'nomor_kk' => env('ADMIN_NOMOR_KK', '5171010000000001'),
                'jenis_kelamin' => env('ADMIN_JENIS_KELAMIN', 'L'),
                'usia' => (int) env('ADMIN_USIA', 33),
                'alamat' => env('ADMIN_ALAMAT', 'Denpasar, Bali'),
            ]
        );

        $jemaatPassword = 'password123';
        if (!Hash::needsRehash($jemaatPassword)) {
            $jemaatPassword = Hash::make($jemaatPassword);
        }

        User::query()->updateOrCreate(
            ['email' => 'jemaat@example.com'],
            [
                'name' => 'Jemaat GPI Yehuda',
                'username' => 'jemaat_yehuda',
                'password' => $jemaatPassword,
                'role' => 'jemaat',
                'nomor_kk' => '5171010000000002',
                'jenis_kelamin' => 'P',
                'usia' => 27,
                'alamat' => 'Badung, Bali',
            ]
        );
    }
}
