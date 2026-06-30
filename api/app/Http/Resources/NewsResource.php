<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NewsResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'title' => $this->title,
            'description' => $this->description,
            'content' => $this->content,
            'cover_image' => $this->cover_image,
            'published_at' => $this->published_at?->toIso8601String(),
            'created_by' => $this->created_by,
            'creator_name' => $this->relationLoaded('creator') ? $this->creator?->name : null,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
            'attachment_count' => $this->relationLoaded('attachments')
                ? $this->attachments->count()
                : $this->attachments()->count(),
        ];
    }
}
