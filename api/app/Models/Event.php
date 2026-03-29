<?php

namespace App\Models;

use App\Models\EventDocumentation;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Event extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'date',
        'start_at',
        'end_at',
        'location',
        'category',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'datetime',
            'start_at' => 'datetime',
            'end_at' => 'datetime',
            'location' => 'array',
        ];
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function documentations(): HasMany
    {
        return $this->hasMany(EventDocumentation::class);
    }
}
