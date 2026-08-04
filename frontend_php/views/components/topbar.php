<?php
$titles = [
    '/dashboard' => ['Panel principal', 'Resumen operativo y accesos del sistema'],
    '/admin' => ['Administración', 'Catálogos y recursos operativos'],
    '/personal' => ['Personal', 'Consulta del talento operativo'],
    '/eventos' => ['Eventos', 'Convocatorias y programación institucional'],
    '/anuncios' => ['Anuncios', 'Comunicaciones internas'],
    '/cartillas' => ['Cartillas', 'Registro institucional operativo'],
    '/insignias' => ['Insignias', 'Rendimiento y logros'],
    '/soporte' => ['Alertas / Soporte', 'Atención interna y seguimiento'],
    '/perfil' => ['Mi perfil', 'Información de la cuenta'],
    '/configuracion' => ['Configuración', 'Roles, permisos y estructura'],
    '/distribucion-geografica' => ['Distribución geográfica', 'Personal asignado por puntos de servicio'],
];
$current = $titles[$path] ?? ['SIGO', 'Sistema Inteligente de Gestión Operativa'];
$title = $pageTitle ?? $current[0];
$description = $pageDescription ?? $current[1];
?>
<header class="sigo-topbar">
    <button class="sigo-menu-button" id="sigoMenuButton" type="button" aria-label="Contraer o expandir menú">☰</button>
    <div class="sigo-screen-title"><h1><?= htmlspecialchars($title) ?></h1><p><?= htmlspecialchars($description) ?></p></div>
    <div class="sigo-top-actions">
        <a class="sigo-button sigo-button-dark" href="/perfil">♙ <span>Mi perfil</span></a>
        <form method="post" action="/logout"><button class="sigo-button sigo-button-primary" type="submit">⇥ <span>Cerrar sesión</span></button></form>
    </div>
</header>
