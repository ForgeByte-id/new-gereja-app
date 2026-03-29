<?php

namespace Tests\Feature\Events;

use App\Models\Event;
use App\Models\EventDocumentation;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class EventApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_event_categories_endpoint_returns_list(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->getJson('/api/v1/events/categories');

        $response->assertOk()->assertJsonPath('status', 'success');
        $response->assertJsonFragment(['code' => 'ibadah']);
    }

    public function test_admin_can_create_event(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/events', [
            'title' => 'Ibadah Raya',
            'description' => 'Deskripsi',
            'start_at' => now()->addDay()->setHour(9)->setMinute(0)->toIso8601String(),
            'end_at' => now()->addDay()->setHour(11)->setMinute(0)->toIso8601String(),
            'category' => 'ibadah',
            'location' => [
                'address' => 'Jl. Sunset Road',
                'latitude' => -8.670458,
                'longitude' => 115.212629,
            ],
        ]);

        $response->assertCreated()->assertJsonPath('status', 'success');
    }

    public function test_jemaat_cannot_create_event(): void
    {
        $jemaat = User::factory()->create(['role' => 'jemaat']);
        Sanctum::actingAs($jemaat);

        $response = $this->postJson('/api/v1/events', [
            'title' => 'Ibadah Raya',
            'start_at' => now()->addDay()->setHour(9)->setMinute(0)->toIso8601String(),
            'end_at' => now()->addDay()->setHour(11)->setMinute(0)->toIso8601String(),
            'category' => 'ibadah',
            'location' => [
                'address' => 'Jl. Sunset Road',
                'latitude' => -8.670458,
                'longitude' => 115.212629,
            ],
        ]);

        $response->assertForbidden();
    }

    public function test_admin_can_upload_documentation(): void
    {
        $admin = User::factory()->create(['role' => 'admin']);
        $event = Event::factory()->create();
        Sanctum::actingAs($admin);

        $response = $this->postJson('/api/v1/events/' . $event->id . '/documentation', [
            'files' => [UploadedFile::fake()->create('doc.jpg', 10, 'image/jpeg')],
            'report_summary' => 'Ringkas',
        ]);

        $response->assertCreated()->assertJsonPath('status', 'success');
    }

    public function test_documentation_download_success(): void
    {
        $user = User::factory()->create();
        $event = Event::factory()->create();
        Sanctum::actingAs($user);

        $relativePath = 'event-documentations/' . $event->id . '/file.jpg';
        $absolutePath = storage_path('app/' . $relativePath);

        if (! is_dir(dirname($absolutePath))) {
            mkdir(dirname($absolutePath), 0755, true);
        }

        file_put_contents($absolutePath, 'dummy-content');

        EventDocumentation::query()->create([
            'event_id' => $event->id,
            'file_path' => $relativePath,
            'mime_type' => 'image/jpeg',
            'file_size' => 12,
            'report_summary' => 'dummy',
        ]);

        $response = $this->get('/api/v1/events/' . $event->id . '/documentation/download');

        $response->assertOk();
        $this->assertSame('application/zip', $response->headers->get('content-type'));
    }
}
