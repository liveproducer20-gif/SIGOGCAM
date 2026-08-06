<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$permissions = $usuario['permisos'] ?? [];
$role = strtoupper((string)($usuario['rolNombre'] ?? $usuario['rol'] ?? ''));
$isAdmin = str_contains($role, 'ADMINISTRADOR');
$can = static function (array $required) use ($permissions, $isAdmin): bool {
    if ($isAdmin) return true;
    foreach ($required as $permission) if (in_array($permission, $permissions, true)) return true;
    return false;
};
$kpis = [
    ['♙', $stats['agentesActivos'] ?? 0, 'Agentes activos', 'Personal operativo'],
    ['▦', $stats['eventosProgramados'] ?? 0, 'Eventos programados', 'Próximas actividades'],
    ['▤', $stats['cartillasGeneradas'] ?? 0, 'Cartillas generadas', 'Registro histórico'],
    ['♜', $stats['insigniasOtorgadas'] ?? 0, 'Insignias otorgadas', 'Reconocimientos'],
    ['◇', $stats['alertasActivas'] ?? 0, 'Alertas activas', 'Requieren atención'],
    ['⌖', $stats['puntosGeorreferenciados'] ?? 0, 'Puntos geográficos', 'Ubicaciones operativas'],
    ['↝', $stats['rutasOperativas'] ?? 0, 'Rutas operativas', 'Rutas activas'],
];
?>
<section class="dashboard-hero">
    <?php if (!empty($error)): ?><div class="alert">No se pudieron cargar todos los indicadores: <?= $esc($error) ?></div><?php endif; ?>
    <div class="dashboard-kpis" aria-label="Indicadores operativos">
        <?php foreach ($kpis as [$icon, $value, $label, $caption]): ?>
            <article class="dashboard-kpi"><i class="dashboard-kpi-icon"><?= $esc($icon) ?></i><div><strong><?= number_format((int)$value, 0, ',', '.') ?></strong><span><?= $esc($label) ?></span><small><?= $esc($caption) ?></small></div></article>
        <?php endforeach; ?>
    </div>

    <h2 class="dashboard-section-title">Módulos disponibles</h2>
    <div class="dashboard-modules">
        <?php if ($can(['cartillas.ver', 'cartillas.generar'])): ?>
        <article class="dashboard-module" data-art="▤"><i class="dashboard-module-icon">▤</i><h3>Cartillas</h3><p>Generador institucional de reportes y procedimientos operativos.</p><div class="dashboard-module-actions"><a href="/cartillas">Abrir</a></div></article>
        <?php endif; ?>
        <?php if ($can(['eventos.ver', 'eventos.crear'])): ?>
        <article class="dashboard-module" data-art="▦"><i class="dashboard-module-icon">◖</i><h3>Eventos y anuncios</h3><p>Gestión de convocatorias, publicaciones y notificaciones institucionales.</p><div class="dashboard-module-actions"><a href="/eventos">Eventos</a><a class="secondary" href="/anuncios">Anuncios</a></div></article>
        <?php endif; ?>
        <?php if ($can(['administracion.ver', 'personal.ver', 'catalogos.ver'])): ?>
        <article class="dashboard-module" data-art="♙"><i class="dashboard-module-icon">♙</i><h3>Administración</h3><p>Catálogos, personal, EAS, móviles, rutas y recursos institucionales.</p><div class="dashboard-module-actions"><a href="/personal">Personal</a><a class="secondary" href="/admin">Catálogos</a></div></article>
        <?php endif; ?>
        <?php if ($can(['distribucion.ver'])): ?>
        <article class="dashboard-module" data-art="⌖"><i class="dashboard-module-icon">⌖</i><h3>Distribución geográfica</h3><p>Gestión de distritos, rutas, lugares de servicio y asignación territorial.</p><div class="dashboard-module-actions"><a href="/distribucion-geografica">Abrir mapa</a><?php if ($can(['distribucion.crear'])): ?><a class="secondary" href="/distribucion-geografica?crear=1">Crear punto</a><?php endif; ?></div></article>
        <?php endif; ?>
        <?php if ($can(['insignias.ver', 'cartillas.ver'])): ?>
        <article class="dashboard-module" data-art="♜"><i class="dashboard-module-icon">♜</i><h3>Insignias</h3><p>Seguimiento de logros, reconocimientos y progreso institucional.</p><div class="dashboard-module-actions"><a href="/insignias">Abrir</a></div></article>
        <?php endif; ?>
        <?php if ($can(['soporte.ver', 'soporte.crear'])): ?>
        <article class="dashboard-module" data-art="◉"><i class="dashboard-module-icon">◉</i><h3>Soporte</h3><p>Registro, clasificación y seguimiento de alertas internas.</p><div class="dashboard-module-actions"><a href="/soporte">Abrir</a></div></article>
        <?php endif; ?>
        <?php if ($can(['configuracion.ver', 'roles.ver', 'permisos.ver'])): ?>
        <article class="dashboard-module" data-art="⚙"><i class="dashboard-module-icon">⚙</i><h3>Configuración</h3><p>Revisión de roles, permisos, alcances y estructura del menú.</p><div class="dashboard-module-actions"><a href="/configuracion">Abrir</a></div></article>
        <?php endif; ?>
    </div>
</section>
