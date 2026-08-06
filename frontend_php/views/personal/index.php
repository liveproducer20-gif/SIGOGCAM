<?php
$esc = static fn($value): string => htmlspecialchars((string)$value, ENT_QUOTES, 'UTF-8');
$json = static fn($value): string => htmlspecialchars(json_encode($value, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES), ENT_QUOTES, 'UTF-8');
$perms = $permissions ?? [];
$canCreate = $isAdministrator || in_array('personal.crear', $perms, true);
$canEdit = $isAdministrator || in_array('personal.editar', $perms, true);
$canDelete = $isAdministrator || in_array('personal.editar', $perms, true);
$roles = $catalogs['roles'] ?? [];
$grados = $catalogs['grados'] ?? [];
$estados = $catalogs['estados'] ?? [];
$grupos = $catalogs['grupos'] ?? [];
$jornadas = $catalogs['jornadas'] ?? [];
?>
<section>
    <!-- Page Header -->
    <div class="p-page-header">
        <div class="p-page-title">
            <h1>Personal</h1>
            <p>Consulta del talento operativo</p>
            <div class="p-breadcrumb">
                <a href="/dashboard">Inicio</a>
                <span>›</span>
                <span>Personal</span>
            </div>
        </div>
        <div class="p-toolbar" id="toolbar">
            <div class="p-search-wrap" id="searchWrap">
                <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg>
                <input type="text" class="p-search-input" id="searchInput" placeholder="Buscar por nombre, cédula o correo..." aria-label="Buscar personal">
                <button class="p-search-clear" id="searchClear" aria-label="Limpiar búsqueda">&times;</button>
            </div>
            <?php if ($canCreate || $canEdit): ?>
            <button class="p-btn p-btn-secondary p-filters-btn" id="filtersBtn" aria-label="Filtros">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M7 12h10M10 18h4"/></svg>
                Filtros
                <span class="p-filters-badge" id="filtersBadge" style="display:none">0</span>
            </button>
            <?php endif; ?>
            <?php if ($canCreate): ?>
            <button class="p-btn p-btn-primary" id="createBtn" aria-label="Crear personal">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M12 5v14M5 12h14"/></svg>
                Crear
            </button>
            <?php endif; ?>
        </div>
    </div>

    <!-- Filters Panel -->
    <?php if ($canCreate || $canEdit): ?>
    <div class="p-filters-panel" id="filtersPanel">
        <div class="p-filters-grid">
            <div class="p-field">
                <label for="filterEstado">Estado</label>
                <select id="filterEstado"><option value="">Todos</option><?php foreach ($estados as $e): ?><option value="<?= (int)$e['id'] ?>"><?= $esc($e['nombre']) ?></option><?php endforeach; ?></select>
            </div>
            <div class="p-field">
                <label for="filterGrado">Grado</label>
                <select id="filterGrado"><option value="">Todos</option><?php foreach ($grados as $g): ?><option value="<?= (int)$g['id'] ?>"><?= $esc($g['nombre']) ?></option><?php endforeach; ?></select>
            </div>
            <div class="p-field">
                <label for="filterRol">Rol</label>
                <select id="filterRol"><option value="">Todos</option><?php foreach ($roles as $r): ?><option value="<?= (int)$r['id'] ?>"><?= $esc($r['nombre']) ?></option><?php endforeach; ?></select>
            </div>
            <div class="p-field">
                <label for="filterGrupo">Grupo</label>
                <select id="filterGrupo"><option value="">Todos</option><?php foreach ($grupos as $g): ?><option value="<?= (int)$g['id'] ?>"><?= $esc($g['nombre']) ?></option><?php endforeach; ?></select>
            </div>
            <div class="p-field">
                <label for="filterJornada">Jornada</label>
                <select id="filterJornada"><option value="">Todas</option><?php foreach ($jornadas as $j): ?><option value="<?= (int)$j['id'] ?>"><?= $esc($j['nombre']) ?></option><?php endforeach; ?></select>
            </div>
        </div>
        <div class="p-filters-actions">
            <button class="p-btn p-btn-secondary" id="clearFiltersBtn">Limpiar filtros</button>
            <button class="p-btn p-btn-primary" id="applyFiltersBtn">Aplicar filtros</button>
        </div>
    </div>
    <?php endif; ?>

    <!-- Table Card -->
    <div class="p-card">
        <div class="p-card-header">
            <div class="p-card-header-left">
                <div class="p-card-header-icon">
                    <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M22 21v-2a4 4 0 0 0-3-3.87"/><path d="M16 3.13a4 4 0 0 1 0 7.75"/></svg>
                </div>
                <div>
                    <h2>Personal registrado</h2>
                    <p>Listado de todo el personal del sistema</p>
                </div>
            </div>
            <span class="p-card-badge" id="totalBadge">0 registros</span>
        </div>

        <!-- Table -->
        <div class="p-table-wrap">
            <table class="p-table">
                <thead>
                    <tr>
                        <th>Nombre</th>
                        <th>Cédula</th>
                        <th>Correo</th>
                        <th>Grado</th>
                        <th>Rol</th>
                        <th>Grupo</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody id="tableBody">
                </tbody>
            </table>
        </div>

        <!-- Pagination -->
        <div class="p-pagination-bar">
            <span class="p-pagination-info" id="paginationInfo">Mostrando 0 de 0 registros</span>
            <div class="p-pagination-controls" id="paginationControls"></div>
            <div class="p-page-size">
                <span>Filas por página:</span>
                <select id="pageSizeSelect">
                    <option value="10">10</option>
                    <option value="20">20</option>
                    <option value="50">50</option>
                    <option value="100">100</option>
                </select>
            </div>
        </div>
    </div>
</section>

<!-- Modal Overlay -->
<div class="p-modal-overlay" id="modalOverlay">
    <div class="p-modal" id="personModal">
        <div class="p-modal-header">
            <div class="p-modal-header-left">
                <div class="p-modal-icon">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2"/><circle cx="9" cy="7" r="4"/><path d="M19 8v6M22 11h-6"/></svg>
                </div>
                <h2 id="modalTitle">Nuevo Personal</h2>
            </div>
            <button class="p-modal-close" id="modalClose" aria-label="Cerrar">&times;</button>
        </div>
        <form id="personForm" novalidate>
            <div class="p-modal-body">
                <input type="hidden" name="id" id="formId" value="">
                <div class="p-form-grid">
                    <div class="p-field">
                        <label for="formCedula">Cédula <span class="req">*</span></label>
                        <input type="text" id="formCedula" name="cedula" required maxlength="20" placeholder="0912345678">
                        <span class="p-field-error" id="errCedula"></span>
                    </div>
                    <div class="p-field">
                        <label for="formNombres">Nombres <span class="req">*</span></label>
                        <input type="text" id="formNombres" name="nombres" required maxlength="120" placeholder="Juan Carlos">
                        <span class="p-field-error" id="errNombres"></span>
                    </div>
                    <div class="p-field">
                        <label for="formApellidos">Apellidos <span class="req">*</span></label>
                        <input type="text" id="formApellidos" name="apellidos" required maxlength="120" placeholder="Pérez López">
                        <span class="p-field-error" id="errApellidos"></span>
                    </div>
                    <div class="p-field">
                        <label for="formCorreo">Correo institucional <span class="req">*</span></label>
                        <input type="email" id="formCorreo" name="correo_institucional" required maxlength="180" placeholder="usuario@seguraep.com">
                        <span class="p-field-error" id="errCorreo"></span>
                    </div>
                    <div class="p-field">
                        <label for="formTelefono">Teléfono</label>
                        <input type="text" id="formTelefono" name="telefono" maxlength="30" placeholder="0991234567">
                        <span class="p-field-error" id="errTelefono"></span>
                    </div>
                    <div class="p-field">
                        <label for="formGrado">Grado <span class="req">*</span></label>
                        <select id="formGrado" name="grado_id" required>
                            <option value="">Seleccione</option>
                            <?php foreach ($grados as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <span class="p-field-error" id="errGrado"></span>
                    </div>
                    <div class="p-field">
                        <label for="formRol">Rol <span class="req">*</span></label>
                        <select id="formRol" name="rol_id" required>
                            <option value="">Seleccione</option>
                            <?php foreach ($roles as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <span class="p-field-error" id="errRol"></span>
                    </div>
                    <div class="p-field">
                        <label for="formGrupo">Grupo</label>
                        <select id="formGrupo" name="grupo_id">
                            <option value="">Seleccione</option>
                            <?php foreach ($grupos as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="p-field">
                        <label for="formJornada">Jornada <span class="req">*</span></label>
                        <select id="formJornada" name="jornada_id" required>
                            <option value="">Seleccione</option>
                            <?php foreach ($jornadas as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option>
                            <?php endforeach; ?>
                        </select>
                        <span class="p-field-error" id="errJornada"></span>
                    </div>
                    <div class="p-field">
                        <label for="formEstado">Estado</label>
                        <select id="formEstado" name="estado_personal_id">
                            <option value="">Seleccione</option>
                            <?php foreach ($estados as $item): ?>
                            <option value="<?= (int)$item['id'] ?>"><?= $esc($item['nombre']) ?></option>
                            <?php endforeach; ?>
                        </select>
                    </div>
                    <div class="p-field">
                        <label for="formPassword">Contraseña</label>
                        <div class="pw-wrap">
                            <input type="password" id="formPassword" name="password" maxlength="128" placeholder="Dejar vacío para generar" autocomplete="new-password">
                            <button type="button" class="pw-toggle" id="pwToggle" aria-label="Ver contraseña">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>
                            </button>
                        </div>
                        <small id="passwordHint">Mínimo 6 caracteres</small>
                        <span class="p-field-error" id="errPassword"></span>
                    </div>
                    <div class="p-field p-field-check">
                        <label for="formActivo">
                            <input type="checkbox" id="formActivo" name="activo" checked>
                            Activo
                        </label>
                    </div>
                </div>
            </div>
            <div class="p-modal-footer">
                <button type="button" class="p-btn p-btn-secondary" id="modalCancel">Cancelar</button>
                <button type="submit" class="p-btn p-btn-primary" id="modalSubmit">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"/><polyline points="17 21 17 13 7 13 7 21"/><polyline points="7 3 7 8 15 8"/></svg>
                    <span id="submitText">Guardar</span>
                </button>
            </div>
        </form>
    </div>
</div>

<!-- Delete Confirmation Modal -->
<div class="p-modal-overlay" id="deleteOverlay">
    <div class="p-modal" style="max-width:440px">
        <div class="p-modal-header">
            <div class="p-modal-header-left">
                <div class="p-modal-icon" style="background:#fee2e2;color:#dc2626">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                </div>
                <h2>Eliminar personal</h2>
            </div>
            <button class="p-modal-close" id="deleteClose" aria-label="Cerrar">&times;</button>
        </div>
        <div class="p-modal-body">
            <p style="margin:0;color:var(--sigo-text);font-size:14px">¿Está seguro de eliminar este registro de personal?</p>
            <p style="margin:10px 0 0;font-weight:700;color:var(--sigo-text)" id="deleteName"></p>
        </div>
        <div class="p-modal-footer">
            <button class="p-btn p-btn-secondary" id="deleteCancelBtn">Cancelar</button>
            <button class="p-btn p-btn-danger" id="deleteConfirmBtn">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg>
                Eliminar registro
            </button>
        </div>
    </div>
</div>

<!-- Reset Password Modal -->
<div class="p-modal-overlay" id="resetOverlay">
    <div class="p-modal" style="max-width:440px">
        <div class="p-modal-header">
            <div class="p-modal-header-left">
                <div class="p-modal-icon" style="background:#fef3c7;color:#d97706">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
                </div>
                <h2>Restablecer contraseña</h2>
            </div>
            <button class="p-modal-close" id="resetClose" aria-label="Cerrar">&times;</button>
        </div>
        <div class="p-modal-body">
            <p style="margin:0;color:var(--sigo-text);font-size:14px">Se generará una nueva contraseña para:</p>
            <p style="margin:10px 0 0;font-weight:700;color:var(--sigo-text)" id="resetName"></p>
            <div id="resetResult" style="display:none;margin-top:14px;padding:12px;border-radius:8px;background:#ecfdf5;border:1px solid #a7f3d0">
                <p style="margin:0;color:#065f46;font-size:13px">Nueva contraseña:</p>
                <p style="margin:6px 0 0;font-family:monospace;font-size:15px;font-weight:700;color:#065f46" id="resetPassword"></p>
            </div>
        </div>
        <div class="p-modal-footer">
            <button class="p-btn p-btn-secondary" id="resetCancelBtn">Cancelar</button>
            <button class="p-btn p-btn-primary" id="resetConfirmBtn">Generar contraseña</button>
        </div>
    </div>
</div>

<script>
window.__PERSONAL_DATA__ = {
    catalogs: <?= $json($catalogs) ?>,
    canCreate: <?= $json($canCreate) ?>,
    canEdit: <?= $json($canEdit) ?>,
    canDelete: <?= $json($canDelete) ?>,
    apiBase: '/personal/api',
};
</script>
<script src="/assets/js/personal.js"></script>
