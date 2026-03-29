<?php

namespace App\Http\Controllers;

use App\Http\Requests\Notifications\BroadcastNotificationRequest;
use App\Services\NotificationTargetingService;
use App\Services\PushNotificationService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class NotificationController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly NotificationTargetingService $targetingService,
        private readonly PushNotificationService $pushNotificationService
    ) {}

    public function broadcast(BroadcastNotificationRequest $request): JsonResponse
    {
        $targetType = $request->string('target_type')->toString();
        $filters = $request->input('target_filters', []);

        $devices = $this->targetingService->resolveTargetDevices($targetType, $filters);
        $actorId = auth('sanctum')->id();
        $result = $this->pushNotificationService->notifyDevices(
            $devices,
            $request->string('title')->toString(),
            $request->string('message')->toString(),
            'broadcast',
            'admin_broadcast',
            $actorId,
            [
                'target_type' => $targetType,
                'target_filters' => $filters,
            ]
        );

        return $this->successResponse([
            'title' => $request->string('title')->toString(),
            'message' => $request->string('message')->toString(),
            'target_type' => $targetType,
            'target_count' => $result['target_count'],
            'success_count' => $result['success_count'],
            'failed_count' => $result['failed_count'],
            'queued_count' => $result['queued_count'],
        ], 'Broadcast notifikasi berhasil diproses');
    }
}
