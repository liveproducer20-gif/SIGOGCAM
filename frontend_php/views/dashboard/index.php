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
        <?php
        $moduleDescriptions = [
            'dashboard' => 'Indicadores operativos y acceso rápido a los módulos.',
            'administracion' => 'Personal, catálogos, EAS, móviles, rutas y recursos institucionales.',
            'personal' => 'Gestión del personal operativo y administrativo.',
            'catalogos' => 'Catálogos maestros de la plataforma.',
            'lugares_servicio' => 'Puntos de servicio y su configuración.',
            'rutas' => 'Recorridos operativos configurados.',
            'circuitos' => 'Circuitos y agrupaciones de rutas.',
            'grados' => 'Jerarquías y grados del personal.',
            'eas' => 'Estaciones de Atención y Servicio.',
            'moviles' => 'Unidades móviles registradas.',
            'asignaciones' => 'Relaciones móvil–EAS.',
            'mantenimiento' => 'Historial de mantenimiento de unidades.',
            'distribucion' => 'Distribución territorial y asignación de personal.',
            'distribucion_geografica' => 'Mapa de distritos, rutas y lugares de servicio.',
            'distribucion_tablero' => 'Tablero de distribución operativa.',
            'distribucion_dashboard' => 'Resumen consolidado de la distribución.',
            'eventos_anuncios' => 'Convocatorias, publicaciones y notificaciones institucionales.',
            'eventos' => 'Convocatorias y eventos operativos.',
            'anuncios' => 'Publicaciones institucionales.',
            'panel_asistencia' => 'Registro y control de asistencia del personal.',
            'cartillas' => 'Generador de reportes y procedimientos operativos.',
            'insignias' => 'Logros y reconocimientos institucionales.',
            'soporte' => 'Alertas y solicitudes de soporte interno.',
            'configuracion' => 'Roles, permisos, alcances y estructura del menú.',
            'perfil' => 'Datos de tu cuenta y preferencias.',
        ];
        $menuItems = array_values(array_filter($menu ?? [], static fn($item) => !empty($item['habilitado'])));
        ?>
        <?php if (empty($menuItems)): ?>
            <div class="empty-state">No hay módulos disponibles para tu rol</div>
        <?php else: foreach ($menuItems as $item): $icon = $item['icono'] ?? '▫'; $desc = $moduleDescriptions[$item['codigo'] ?? ''] ?? ''; ?>
            <?php if (!empty($item['hijos'])): ?>
            <article class="dashboard-module" data-art="<?= $esc($icon) ?>">
                <i class="dashboard-module-icon"><?= $esc($icon) ?></i>
                <h3><?= $esc($item['nombre']) ?></h3>
                <p><?= $esc($desc) ?></p>
                <div class="dashboard-module-actions">
                    <?php foreach (array_values(array_filter($item['hijos'], static fn($h) => !empty($h['habilitado']))) as $child): ?>
                        <a href="<?= $esc($child['ruta'] ?? '#') ?>"><?= $esc($child['nombre']) ?></a>
                    <?php endforeach; ?>
                </div>
            </article>
            <?php else: ?>
            <article class="dashboard-module" data-art="<?= $esc($icon) ?>">
                <i class="dashboard-module-icon"><?= $esc($icon) ?></i>
                <h3><?= $esc($item['nombre']) ?></h3>
                <p><?= $esc($desc) ?></p>
                <div class="dashboard-module-actions"><a href="<?= $esc($item['ruta'] ?? '#') ?>">Abrir</a></div>
            </article>
            <?php endif; ?>
        <?php endforeach; endif; ?>
    </div>
</section>
