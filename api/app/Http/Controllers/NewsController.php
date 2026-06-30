<?php

namespace App\Http\Controllers;

use App\Http\Requests\News\StoreNewsRequest;
use App\Http\Requests\News\UpdateNewsRequest;
use App\Http\Requests\News\UploadNewsAttachmentsRequest;
use App\Http\Resources\NewsResource;
use App\Models\News;
use App\Models\NewsAttachment;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use ZipArchive;

class NewsController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $perPage = min((int) $request->query('per_page', 15), 100);

        $news = News::query()
            ->with('creator')
            ->withCount('attachments')
            ->orderBy('published_at', 'desc')
            ->orderBy('created_at', 'desc')
            ->paginate($perPage);

        return $this->successResponse(
            NewsResource::collection($news->items()),
            'Daftar berita berhasil diambil',
            200,
            [
                'meta' => [
                    'current_page' => $news->currentPage(),
                    'per_page' => $news->perPage(),
                    'total' => $news->total(),
                    'last_page' => $news->lastPage(),
                ],
            ]
        );
    }

    public function show(News $news): JsonResponse
    {
        $news->load('creator');

        return $this->successResponse(new NewsResource($news), 'Berita berhasil diambil');
    }

    public function store(StoreNewsRequest $request): JsonResponse
    {
        $news = News::query()->create([
            'title' => $request->string('title')->toString(),
            'description' => $request->string('description')->toString() ?: null,
            'content' => $request->string('content')->toString(),
            'cover_image' => $request->input('cover_image'),
            'created_by' => auth('sanctum')->id(),
            'published_at' => $request->date('published_at') ?? now(),
        ]);

        return $this->successResponse(new NewsResource($news), 'Berita berhasil dibuat', 201);
    }

    public function update(UpdateNewsRequest $request, News $news): JsonResponse
    {
        $data = $request->only(['title', 'description', 'content', 'cover_image', 'published_at']);

        $news->update($data);

        return $this->successResponse(new NewsResource($news), 'Berita berhasil diperbarui');
    }

    public function destroy(News $news): JsonResponse
    {
        $news->delete();

        return $this->successResponse(null, 'Berita berhasil dihapus');
    }

    public function uploadAttachments(UploadNewsAttachmentsRequest $request, News $news): JsonResponse
    {
        $files = $request->file('files', []);

        $uploaded = [];
        foreach ($files as $file) {
            $storedPath = $file->store("news-attachments/{$news->id}");

            $attachment = NewsAttachment::query()->create([
                'news_id' => $news->id,
                'file_path' => $storedPath,
                'file_name' => $file->getClientOriginalName(),
                'mime_type' => (string) $file->getMimeType(),
                'file_size' => (int) $file->getSize(),
            ]);

            $uploaded[] = $attachment;
        }

        return $this->successResponse($uploaded, 'Lampiran berhasil diunggah', 201);
    }

    public function downloadAttachments(News $news)
    {
        $attachments = $news->attachments()->get();

        if ($attachments->isEmpty()) {
            return $this->errorResponse('Lampiran berita tidak ditemukan', 'NOT_FOUND', 404);
        }

        $zipPath = storage_path("app/temp/news-{$news->id}-attachments.zip");

        if (! is_dir(dirname($zipPath))) {
            mkdir(dirname($zipPath), 0755, true);
        }

        $zip = new ZipArchive();
        $zip->open($zipPath, ZipArchive::CREATE | ZipArchive::OVERWRITE);

        foreach ($attachments as $att) {
            $absolutePath = storage_path('app/private/' . $att->file_path);
            if (file_exists($absolutePath)) {
                $zip->addFile($absolutePath, $att->file_name);
            }
        }

        $zip->close();

        return response()->download($zipPath, "berita-{$news->id}-lampiran.zip", [
            'Content-Type' => 'application/zip',
        ])->deleteFileAfterSend(true);
    }
}
