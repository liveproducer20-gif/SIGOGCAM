<?php

namespace App\Core;

final class View
{
    public static function render(string $view, array $data = []): void
    {
        extract($data, EXTR_SKIP);
        $viewFile = dirname(__DIR__, 2) . '/views/' . $view . '.php';

        if (!is_file($viewFile)) {
            throw new \RuntimeException("Vista no encontrada: {$view}");
        }

        require dirname(__DIR__, 2) . '/views/layout/app.php';
    }
}
