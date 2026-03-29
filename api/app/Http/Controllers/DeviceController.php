<?php

namespace App\Http\Controllers;

use App\Http\Requests\Devices\RegisterDeviceRequest;
use App\Http\Requests\Devices\RevokeDeviceRequest;
use App\Models\User;
use App\Models\UserDevice;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class DeviceController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();
        $currentDeviceToken = request()->header('X-Device-Token');

        $devices = $user->devices()
            ->latest('last_active')
            ->get()
            ->map(function (UserDevice $device) use ($currentDeviceToken): array {
                return [
                    'id' => $device->id,
                    'device_name' => $device->device_name,
                    'device_type' => $device->device_type,
                    'last_active' => optional($device->last_active)->toIso8601String(),
                    'is_current_device' => $currentDeviceToken !== null && $device->fcm_token === $currentDeviceToken,
                ];
            });

        return $this->successResponse($devices, 'Daftar device berhasil diambil');
    }

    public function register(RegisterDeviceRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $device = UserDevice::query()->updateOrCreate(
            ['fcm_token' => $request->string('fcm_token')->toString()],
            [
                'user_id' => $user->id,
                'device_name' => mb_substr($request->string('device_name')->toString(), 0, 120) ?: null,
                'device_type' => $request->string('device_type')->toString(),
                'last_active' => now(),
            ]
        );

        return $this->successResponse($device, 'Device berhasil didaftarkan', 201);
    }

    public function revoke(RevokeDeviceRequest $request): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $device = $user->devices()->where('fcm_token', $request->string('fcm_token'))->first();

        if (! $device) {
            return $this->errorResponse('Device token tidak ditemukan', 'DEVICE_NOT_FOUND', 404);
        }

        $device->delete();

        return $this->successResponse(null, 'Device berhasil dicabut');
    }

    public function revokeAll(): JsonResponse
    {
        /** @var User $user */
        $user = auth('sanctum')->user();

        $count = $user->devices()->count();
        $user->devices()->delete();

        return $this->successResponse([
            'revoked_count' => $count,
        ], 'Semua device berhasil dicabut');
    }
}
