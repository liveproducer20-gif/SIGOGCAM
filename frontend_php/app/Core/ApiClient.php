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

    /**
     * Realiza varias peticiones GET en paralelo (curl_multi).
     * Recibe un mapa ['clave' => 'ruta'] y devuelve ['clave' => ['data' => ...] | ['error' => \Throwable]].
     * Cada petición se resuelve de forma independiente: un fallo no rompe las demás.
     */
    public function getMany(array $paths): array
    {
        $multi = curl_multi_init();
        $handles = [];
        foreach ($paths as $key => $path) {
            $url = rtrim($this->baseUrl, '/') . '/' . ltrim($path, '/');
            $headers = ['Accept: application/json'];
            if ($this->token !== null && $this->token !== '') {
                $headers[] = "Authorization: Bearer {$this->token}";
            }
            $ch = curl_init($url);
            curl_setopt_array($ch, [
                CURLOPT_RETURNTRANSFER => true,
                CURLOPT_HTTPHEADER => $headers,
                CURLOPT_TIMEOUT => 12,
            ]);
            curl_multi_add_handle($multi, $ch);
            $handles[$key] = $ch;
        }

        do {
            $status = curl_multi_exec($multi, $active);
            if ($active) {
                curl_multi_select($multi, 0.2);
            }
        } while ($active && $status === CURLM_OK);

        $results = [];
        foreach ($handles as $key => $ch) {
            $raw = curl_multi_getcontent($ch);
            if ($raw === false || curl_error($ch) !== '') {
                $results[$key] = ['error' => new \RuntimeException('No se pudo conectar con la API.')];
            } else {
                $decoded = json_decode($raw, true);
                if (!is_array($decoded)) {
                    $results[$key] = ['error' => new \RuntimeException('La API respondió un formato no válido.')];
                } elseif (($decoded['ok'] ?? false) !== true) {
                    $results[$key] = ['error' => new \RuntimeException($decoded['mensaje'] ?? $decoded['detail'] ?? 'Error al consumir la API.')];
                } else {
                    $results[$key] = ['data' => $decoded];
                }
            }
            curl_multi_remove_handle($multi, $ch);
        }
        curl_multi_close($multi);
        return $results;
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
