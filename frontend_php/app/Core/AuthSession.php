<?php

namespace App\Core;

final class AuthSession
{
    public static function start(): void
    {
        $sessionName = Config::get('SESSION_NAME', 'sigo_gcam_session');
        if (session_status() === PHP_SESSION_NONE) {
            session_name($sessionName);
            session_start();
        }
    }

    public static function login(array $usuario, string $token): void
    {
        $_SESSION['usuario'] = $usuario;
        $_SESSION['token'] = $token;
    }

    public static function logout(): void
    {
        $_SESSION = [];
        if (session_status() === PHP_SESSION_ACTIVE) {
            session_destroy();
        }
    }

    public static function user(): ?array
    {
        return $_SESSION['usuario'] ?? null;
    }

    public static function token(): ?string
    {
        return $_SESSION['token'] ?? null;
    }

    public static function check(): bool
    {
        return self::user() !== null && self::token() !== null;
    }
}
