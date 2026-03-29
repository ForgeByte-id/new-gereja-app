<?php

namespace App\Http\Controllers;

use App\Http\Requests\Events\StoreEventRequest;
use App\Http\Requests\Events\UploadDocumentationRequest;
use App\Http\Resources\EventResource;
use App\Models\Event;
use App\Models\EventCategory;
use App\Models\EventDocumentation;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use ZipArchive;

class EventController extends Controller
{
    use ApiResponse;

    public function categories(): JsonResponse
    {
        $categories = Cache::remember('event_categories.active', 600, function () {
            return EventCategory::query()
                ->where('is_active', true)
                ->orderBy('sort_order')
                ->orderBy('name')
                ->get(['code', 'name']);
        });

        return $this->successResponse($categories, 'Daftar kategori event berhasil diambil');
    }

    public function index(Request $request): JsonResponse
    {
        $status = $request->query('status');
        $perPage = min((int) $request->query('per_page', 10), 100);
        $sortBy = in_array($request->query('sort_by'), ['date', 'start_at', 'created_at'], true) ? $request->query('sort_by') : 'start_at';
        $sortOrder = strtolower((string) $request->query('sort_order')) === 'asc' ? 'asc' : 'desc';

        $query = Event::query();

        if ($status === 'upcoming') {
            $query->where(fn($q) => $q->where('start_at', '>=', now())->orWhere('date', '>=', now()));
        }

        if ($status === 'past') {
            $query->where(fn($q) => $q->where('start_at', '<', now())->orWhere('date', '<', now()));
        }

        $events = $query->orderBy($sortBy, $sortOrder)->paginate($perPage);

        return $this->successResponse(
            EventResource::collection($events->items()),
            'Daftar event berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $events->currentPage(),
                    'per_page' => $events->perPage(),
                    'total' => $events->total(),
                    'last_page' => $events->lastPage(),
                ],
                'links' => [
                    'first' => $events->url(1),
                    'last' => $events->url($events->lastPage()),
                    'prev' => $events->previousPageUrl(),
                    'next' => $events->nextPageUrl(),
                ],
            ]
        );
    }

    public function store(StoreEventRequest $request): JsonResponse
    {
        $startAt = $request->date('start_at') ?: $request->date('date');
        $endAt = $request->date('end_at');
        $location = $request->input('location');

        if (is_string($location)) {
            $location = [
                'address' => $location,
                'latitude' => null,
                'longitude' => null,
            ];
        }

        $event = Event::query()->create([
            'title' => $request->string('title')->toString(),
            'description' => $request->string('description')->toString() ?: null,
            'date' => $startAt,
            'start_at' => $startAt,
            'end_at' => $endAt,
            'location' => $location,
            'category' => $request->string('category')->toString(),
            'created_by' => auth('sanctum')->id(),
        ]);

        return $this->successResponse(new EventResource($event), 'Event berhasil dibuat', 201);
    }

    public function uploadDocumentation(UploadDocumentationRequest $request, Event $event): JsonResponse
    {
        $files = $request->file('files', []);
        $totalSize = collect($files)->sum(fn($file) => $file->getSize());

        if ($totalSize > (200 * 1024 * 1024)) {
            return $this->errorResponse('Total upload melebihi 200MB', 'VALIDATION_ERROR', 422, [
                'files' => ['Total ukuran file maksimal 200MB per request.'],
            ]);
        }

        foreach ($files as $file) {
            $storedPath = $file->store("event-documentations/{$event->id}");

            EventDocumentation::query()->create([
                'event_id' => $event->id,
                'file_path' => $storedPath,
                'mime_type' => (string) $file->getMimeType(),
                'file_size' => (int) $file->getSize(),
                'report_summary' => $request->string('report_summary')->toString() ?: null,
            ]);
        }

        return $this->successResponse(null, 'Dokumentasi berhasil diunggah', 201);
    }

    public function downloadDocumentation(Event $event)
    {
        $docs = $event->documentations()->get();

        if ($docs->isEmpty()) {
            return $this->errorResponse('Dokumentasi event tidak ditemukan', 'NOT_FOUND', 404);
        }

        $zipPath = storage_path("app/temp/event-{$event->id}-documentation.zip");

        if (! is_dir(dirname($zipPath))) {
            mkdir(dirname($zipPath), 0755, true);
        }

        $zip = new ZipArchive();
        $zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE);

        foreach ($docs as $doc) {
            $absolutePath = storage_path('app/' . $doc->file_path);
            if (file_exists($absolutePath)) {
                $zip->addFile($absolutePath, basename($doc->file_path));
            }
        }

        $zip->close();

        return response()->download($zipPath, "event-{$event->id}-documentation.zip", [
            'Content-Type' => 'application/zip',
        ])->deleteFileAfterSend(true);
    }
}
