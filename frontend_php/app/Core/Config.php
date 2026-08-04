<?php

namespace App\Core;

final class Config
{
    private static array $values = [];

    public static function load(string $root): void
    {
        self::$values = [
            'APP_NAME' => getenv('APP_NAME') ?: 'SIGO-GCAM',
            'APP_ENV' => getenv('APP_ENV') ?: 'development',
            'API_BASE_URL' => getenv('API_BASE_URL') ?: 'http://127.0.0.1:8000/api',
            'SESSION_NAME' => getenv('SESSION_NAME') ?: 'sigo_gcam_session',
        ];

        $file = $root . DIRECTORY_SEPARATOR . '.env';
        if (!is_file($file)) {
            return;
        }

        foreach (file($file, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES) as $line) {
            $line = trim($line);
            if ($line === '' || str_starts_with($line, '#') || !str_contains($line, '=')) {
                continue;
            }

            [$key, $value] = explode('=', $line, 2);
            self::$values[trim($key)] = trim($value);
        }
    }

    public static function get(string $key, ?string $default = null): ?string
    {
        return self::$values[$key] ?? $default;
    }
}
