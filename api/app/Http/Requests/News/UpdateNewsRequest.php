<?php

namespace App\Http\Requests\News;

use Illuminate\Foundation\Http\FormRequest;

class UpdateNewsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'title' => ['sometimes', 'required', 'string', 'max:255'],
            'description' => ['nullable', 'string', 'max:500'],
            'content' => ['sometimes', 'required', 'string'],
            'cover_image' => ['nullable', 'array'],
            'cover_image.url' => ['nullable', 'string', 'max:2048'],
            'cover_image.path' => ['nullable', 'string', 'max:2048'],
            'cover_image.disk' => ['nullable', 'string', 'max:50'],
            'published_at' => ['nullable', 'date'],
        ];
    }
}
