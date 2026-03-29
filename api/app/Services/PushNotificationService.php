<?php

namespace App\Services;

use App\Models\NotificationDispatchLog;
use App\Models\User;
use App\Models\UserDevice;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Mail;
use Throwable;

class PushNotificationService
{
    /**
     * @param list<int> $recipientUserIds
     * @param array<string, mixed> $context
     */
    public function notifyUsers(
        array $recipientUserIds,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId = null,
        array $context = []
    ): int {
        if ($recipientUserIds === []) {
            return 0;
        }

        $devices = UserDevice::query()
            ->whereIn('user_id', $recipientUserIds)
            ->get(['user_id', 'fcm_token'])
            ->map(fn(UserDevice $device) => [
                'user_id' => (int) $device->user_id,
                'fcm_token' => (string) $device->fcm_token,
            ])
            ->all();

        $result = $this->notifyDevices($devices, $title, $message, $module, $eventType, $senderUserId, $context);

        return $result['success_count'] + $result['queued_count'];
    }

    /**
     * @param list<array{user_id:int,fcm_token:string}> $devices
     * @param array<string, mixed> $context
     *
     * @return array{target_count:int,success_count:int,failed_count:int,queued_count:int}
     */
    public function notifyDevices(
        array $devices,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId = null,
        array $context = []
    ): array {
        $result = [
            'target_count' => count($devices),
            'success_count' => 0,
            'failed_count' => 0,
            'queued_count' => 0,
        ];

        if ($devices === []) {
            return $result;
        }

        $traceId = request()->attributes->get('trace_id') ?? request()->header('X-Trace-Id');
        $fcmEnabled = filter_var((string) config('services.fcm.enabled', false), FILTER_VALIDATE_BOOL);
        $serverKey = (string) config('services.fcm.server_key', '');
        $endpoint = (string) config('services.fcm.endpoint', 'https://fcm.googleapis.com/fcm/send');

        foreach ($devices as $device) {
            $recipientUserId = (int) $device['user_id'];
            $fcmToken = (string) $device['fcm_token'];

            $status = 'queued';
            $providerResponse = ['reason' => 'fcm_not_configured'];

            if ($fcmEnabled && $serverKey !== '') {
                try {
                    $httpResponse = Http::timeout(8)
                        ->withHeaders([
                            'Authorization' => 'key=' . $serverKey,
                            'Content-Type' => 'application/json',
                        ])
                        ->post($endpoint, [
                            'to' => $fcmToken,
                            'priority' => 'high',
                            'notification' => [
                                'title' => $title,
                                'body' => $message,
                            ],
                            'data' => array_merge($context, [
                                'module' => $module,
                                'event_type' => $eventType,
                                'trace_id' => $traceId,
                            ]),
                        ]);

                    if ($httpResponse->successful()) {
                        $status = 'sent';
                        $providerResponse = ['http_status' => $httpResponse->status(), 'body' => $httpResponse->json()];
                    } else {
                        $status = 'failed';
                        $providerResponse = ['http_status' => $httpResponse->status(), 'body' => $httpResponse->body()];
                    }
                } catch (Throwable $throwable) {
                    $status = 'failed';
                    $providerResponse = ['error' => $throwable->getMessage()];
                }
            }

            NotificationDispatchLog::query()->create([
                'sender_user_id' => $senderUserId,
                'recipient_user_id' => $recipientUserId,
                'fcm_token' => $fcmToken,
                'module' => $module,
                'event_type' => $eventType,
                'title' => $title,
                'message' => $message,
                'context' => $context,
                'status' => $status,
                'provider' => 'fcm',
                'trace_id' => is_string($traceId) ? $traceId : null,
                'provider_response' => $providerResponse,
            ]);

            if ($status === 'sent') {
                $result['success_count']++;
            } elseif ($status === 'failed') {
                $result['failed_count']++;
            } else {
                $result['queued_count']++;
            }
        }

        $this->sendEmailNotifications(
            collect($devices)->pluck('user_id')->map(fn($id) => (int) $id)->unique()->values()->all(),
            $title,
            $message,
            $module,
            $eventType,
            $senderUserId,
            is_string($traceId) ? $traceId : null,
            $context
        );

        return $result;
    }

    /**
     * @param list<int> $recipientUserIds
     * @param array<string, mixed> $context
     */
    private function sendEmailNotifications(
        array $recipientUserIds,
        string $title,
        string $message,
        string $module,
        string $eventType,
        ?int $senderUserId,
        ?string $traceId,
        array $context
    ): void {
        $emailEnabled = filter_var((string) config('services.notifications.email_enabled', false), FILTER_VALIDATE_BOOL);

        if (! $emailEnabled || $recipientUserIds === []) {
            return;
        }

        $recipients = User::query()
            ->whereIn('id', $recipientUserIds)
            ->whereNotNull('email')
            ->get(['id', 'email']);

        foreach ($recipients as $recipient) {
            $email = (string) $recipient->email;
            if ($email === '') {
                continue;
            }

            $status = 'sent';
            $providerResponse = ['channel' => 'smtp'];

            try {
                Mail::raw($message, function ($mail) use ($email, $title): void {
                    $mail->to($email)->subject($title);
                });
            } catch (Throwable $throwable) {
                $status = 'failed';
                $providerResponse = ['error' => $throwable->getMessage()];
            }

            NotificationDispatchLog::query()->create([
                'sender_user_id' => $senderUserId,
                'recipient_user_id' => (int) $recipient->id,
                'fcm_token' => $email,
                'module' => $module,
                'event_type' => $eventType,
                'title' => $title,
                'message' => $message,
                'context' => $context,
                'status' => $status,
                'provider' => 'email',
                'trace_id' => $traceId,
                'provider_response' => $providerResponse,
            ]);
        }
    }
}
