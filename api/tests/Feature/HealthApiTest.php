<?php

namespace Tests\Feature;

use Tests\TestCase;

class HealthApiTest extends TestCase
{
    public function test_health_endpoint_returns_ok(): void
    {
        $response = $this->getJson('/api/v1/health');

        $response->assertOk()->assertJson([
            'status' => 'ok',
            'flutter_ready' => true,
        ]);

        $traceId = $response->headers->get('X-Trace-Id');
        $this->assertIsString($traceId);

        $this->assertDatabaseHas('api_activity_logs', [
            'path' => '/api/v1/health',
            'status_code' => 200,
            'trace_id' => $traceId,
        ]);
    }
}
