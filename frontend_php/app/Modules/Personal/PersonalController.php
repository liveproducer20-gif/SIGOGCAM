<?php

namespace App\Modules\Personal;

use App\Core\ApiClient;
use App\Core\AuthSession;
use App\Core\Config;
use App\Core\View;

final class PersonalController
{
    public function index(): void
    {
        if (!AuthSession::check()) {
            header('Location: /');
            return;
        }

        $items = [];
        $error = null;
        try {
            $api = new ApiClient(Config::get('API_BASE_URL'), AuthSession::token());
            $response = $api->get('personal');
            $items = $response['datos'] ?? [];
        } catch (\Throwable $exception) {
            $error = $exception->getMessage();
        }

        View::render('personal/index', [
            'items' => $items,
            'error' => $error,
        ]);
    }
}
