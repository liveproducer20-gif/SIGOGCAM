<?php

namespace App\Core;

final class ApiClient
{
    public function __construct(
        private readonly string $baseUrl,
        private readonly ?string $token = null,
    ) {
    }

    public function get(string $path): array
    {
        return $this->request('GET', $path);
    }

    public function post(string $path, array $body): array
    {
        return $this->request('POST', $path, $body);
    }

    public function put(string $path, array $body): array
    {
        return $this->request('PUT', $path, $body);
    }

    public function delete(string $path): array
    {
        return $this->request('DELETE', $path);
    }

    private function request(string $method, string $path, ?array $body = null): array
    {
        $url = rtrim($this->baseUrl, '/') . '/' . ltrim($path, '/');
        $headers = ["Accept: application/json"];

        if ($this->token !== null && $this->token !== '') {
            $headers[] = "Authorization: Bearer {$this->token}";
        }

        $payload = null;
        if ($body !== null) {
            $payload = json_encode($body, JSON_UNESCAPED_UNICODE);
            $headers[] = "Content-Type: application/json";
        }

        $context = stream_context_create([
            'http' => [
                'method' => $method,
                'header' => implode("\r\n", $headers),
                'content' => $payload ?? '',
                'ignore_errors' => true,
                'timeout' => 12,
            ],
        ]);

        $raw = @file_get_contents($url, false, $context);
        if ($raw === false) {
            throw new \RuntimeException('No se pudo conectar con la API.');
        }

        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            throw new \RuntimeException('La API respondió un formato no válido.');
        }

        if (($decoded['ok'] ?? false) !== true) {
            throw new \RuntimeException($decoded['mensaje'] ?? $decoded['detail'] ?? 'Error al consumir la API.');
        }

        return $decoded;
    }
}
