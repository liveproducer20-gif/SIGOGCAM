<?php

declare(strict_types=1);

spl_autoload_register(function (string $class): void {
    $prefix = 'App\\';
    if (!str_starts_with($class, $prefix)) {
        return;
    }

    $relative = str_replace('\\', DIRECTORY_SEPARATOR, substr($class, strlen($prefix)));
    $file = dirname(__DIR__) . '/app/' . $relative . '.php';
    if (is_file($file)) {
        require $file;
    }
});

use App\Core\AuthSession;
use App\Core\Config;
use App\Modules\Admin\AdminController;
use App\Modules\Anuncios\AnunciosController;
use App\Modules\Auth\AuthController;
use App\Modules\Cartillas\CartillasController;
use App\Modules\Configuracion\ConfiguracionController;
use App\Modules\Dashboard\DashboardController;
use App\Modules\DistribucionGeografica\DistribucionGeograficaController;
use App\Modules\DistribucionTablero\DistribucionTableroController;
use App\Modules\Eventos\EventosController;
use App\Modules\Insignias\InsigniasController;
use App\Modules\Personal\PersonalController;
use App\Modules\Perfil\PerfilController;
use App\Modules\Soporte\SoporteController;

Config::load(dirname(__DIR__));
date_default_timezone_set('America/Guayaquil');
AuthSession::start();

$path = parse_url($_SERVER['REQUEST_URI'] ?? '/', PHP_URL_PATH) ?: '/';
$method = strtoupper($_SERVER['REQUEST_METHOD'] ?? 'GET');

if ($path === '/' && $method === 'GET') {
    (new AuthController())->showLogin();
    return;
}

if ($path === '/login' && $method === 'POST') {
    (new AuthController())->login();
    return;
}

if ($path === '/logout' && $method === 'POST') {
    (new AuthController())->logout();
    return;
}

if ($path === '/dashboard' && $method === 'GET') {
    (new DashboardController())->index();
    return;
}

if ($path === '/distribucion-geografica' && $method === 'GET') {
    (new DistribucionGeograficaController())->index();
    return;
}

if ($path === '/distribucion-geografica/api' && in_array($method, ['GET', 'POST', 'PUT', 'DELETE'], true)) {
    (new DistribucionGeograficaController())->proxy();
    return;
}

if ($path === '/distribucion-tablero' && $method === 'GET') {
    (new DistribucionTableroController())->index();
    return;
}

if ($path === '/distribucion-tablero/api' && in_array($method, ['GET', 'POST', 'PUT', 'DELETE'], true)) {
    (new DistribucionTableroController())->proxy();
    return;
}

if ($path === '/cartillas' && $method === 'GET') {
    (new CartillasController())->index();
    return;
}

if ($path === '/cartillas' && $method === 'POST') {
    (new CartillasController())->store();
    return;
}

if ($path === '/eventos' && $method === 'GET') {
    (new EventosController())->index();
    return;
}

if ($path === '/eventos' && $method === 'POST') {
    (new EventosController())->store();
    return;
}

if ($path === '/eventos/eliminar' && $method === 'POST') {
    (new EventosController())->destroy();
    return;
}
if ($path === '/eventos/estado' && $method === 'POST') { (new EventosController())->status(); return; }

if ($path === '/anuncios' && $method === 'GET') {
    (new AnunciosController())->index();
    return;
}

if ($path === '/anuncios' && $method === 'POST') {
    (new AnunciosController())->store();
    return;
}

if ($path === '/anuncios/eliminar' && $method === 'POST') {
    (new AnunciosController())->destroy();
    return;
}
if ($path === '/anuncios/publicar' && $method === 'POST') { (new AnunciosController())->publish(); return; }

if ($path === '/personal' && $method === 'GET') {
    (new PersonalController())->index();
    return;
}

if (str_starts_with($path, '/personal/api') && in_array($method, ['GET', 'POST', 'PUT', 'DELETE'], true)) {
    (new PersonalController())->proxy();
    return;
}

if ($path === '/admin' && $method === 'GET') {
    (new AdminController())->index();
    return;
}

if ($path === '/admin' && $method === 'POST') {
    (new AdminController())->store();
    return;
}

if ($path === '/admin/eliminar' && $method === 'POST') {
    (new AdminController())->destroy();
    return;
}

if ($path === '/insignias' && $method === 'GET') {
    (new InsigniasController())->index();
    return;
}

if ($path === '/soporte' && $method === 'GET') {
    (new SoporteController())->index();
    return;
}

if ($path === '/soporte' && $method === 'POST') {
    (new SoporteController())->store();
    return;
}

if ($path === '/soporte/actualizar' && $method === 'POST') {
    (new SoporteController())->update();
    return;
}

if ($path === '/soporte/comentar' && $method === 'POST') {
    (new SoporteController())->comment();
    return;
}

if ($path === '/perfil' && $method === 'GET') {
    (new PerfilController())->index();
    return;
}

if ($path === '/configuracion' && $method === 'GET') {
    (new ConfiguracionController())->index();
    return;
}

if ($path === '/configuracion/permisos' && $method === 'POST') {
    (new ConfiguracionController())->updatePermissions();
    return;
}

if ($path === '/configuracion/menu' && $method === 'POST') {
    (new ConfiguracionController())->updateMenu();
    return;
}

if ($path === '/configuracion/alcance' && $method === 'POST') {
    (new ConfiguracionController())->storeScope();
    return;
}

if ($path === '/configuracion/condiciones' && $method === 'POST') {
    (new ConfiguracionController())->storeCondition();
    return;
}

if ($path === '/configuracion/condiciones/eliminar' && $method === 'POST') {
    (new ConfiguracionController())->deleteCondition();
    return;
}
if ($path === '/configuracion/campos' && $method === 'POST') { (new ConfiguracionController())->updateFields(); return; }
if ($path === '/configuracion/versiones' && $method === 'POST') { (new ConfiguracionController())->createVersion(); return; }
if ($path === '/configuracion/cambios' && $method === 'POST') { (new ConfiguracionController())->storeCambio(); return; }
if ($path === '/configuracion/cambios/eliminar' && $method === 'POST') { (new ConfiguracionController())->deleteCambio(); return; }

http_response_code(404);
echo 'Ruta no encontrada';
