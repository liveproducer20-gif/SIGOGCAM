(() => {
  'use strict';

  const D = window.__PERSONAL_DATA__ || {};
  const API = D.apiBase || '/personal/api';

  let state = { page: 1, limit: 10, search: '', estado: null, grado: null, rol: null, grupo: null, jornada: null, total: 0, totalPages: 1, data: [] };
  let searchTimer = null;
  let editingId = null;
  let deleteTargetId = null;
  let resetTargetId = null;
  let isSaving = false;
  let activeActionsId = null;
  let activeActionsTrigger = null;
  let actionsMenu = null;

  const rowMap = new Map();

  const $ = (s, p) => (p || document).querySelector(s);
  const $$ = (s, p) => [...(p || document).querySelectorAll(s)];

  const avatarColors = ['#078c83','#2584e8','#7452c7','#ed9a34','#df444b','#26a269','#d97706','#6366f1'];
  function getAvatar(name, lastName) {
    const n = (name || '').trim();
    const l = (lastName || '').trim();
    const initials = ((n[0] || '') + (l[0] || '')).toUpperCase() || '?';
    let hash = 0;
    for (let i = 0; i < (n + l).length; i++) hash = (hash * 31 + (n + l).charCodeAt(i)) | 0;
    const color = avatarColors[Math.abs(hash) % avatarColors.length];
    return { initials, color };
  }

  function statusClass(nombre) {
    const n = (nombre || '').toLowerCase().replace(/\s+/g, '');
    const map = { 'activo': 'activo', 'inactivo': 'inactivo', 'suspendido': 'suspendido', 'vacaciones': 'vacaciones', 'permiso': 'permiso', 'capacitacion': 'capacitacion', 'reposomedico': 'reposo', 'comisionservicio': 'comision', 'sinestado': 'sinestado' };
    return 'p-status-' + (map[n] || 'sinestado');
  }

  function esc(s) { const el = document.createElement('span'); el.textContent = s ?? ''; return el.innerHTML; }

  async function apiCall(method, resource, body) {
    const opts = { method, headers: { 'Accept': 'application/json', 'Content-Type': 'application/json' } };
    if (body && method !== 'GET') opts.body = JSON.stringify(body);
    const url = resource.startsWith('http') ? resource : `${API}/${resource}`;
    const res = await fetch(url, opts);
    const json = await res.json();
    if (json.ok !== true) throw new Error(json.mensaje || 'Error de servidor');
    return json;
  }

  function toast(msg, type = 'success') {
    const existing = document.querySelector('.p-toast');
    if (existing) existing.remove();
    const el = document.createElement('div');
    el.className = 'p-toast ' + type;
    el.innerHTML = '<span class="p-toast-icon">' + (type === 'success' ? '&#10003;' : '&#9888;') + '</span><span>' + esc(msg) + '</span>';
    document.body.appendChild(el);
    setTimeout(() => { el.style.opacity = '0'; el.style.transition = 'opacity .3s'; setTimeout(() => el.remove(), 300); }, 3500);
  }

  function buildQueryString() {
    const p = new URLSearchParams();
    p.set('page', state.page);
    p.set('limit', state.limit);
    if (state.search) p.set('buscar', state.search);
    if (state.estado != null) p.set('estado', state.estado);
    if (state.grado != null) p.set('grado', state.grado);
    if (state.rol != null) p.set('rol', state.rol);
    if (state.grupo != null) p.set('grupo', state.grupo);
    if (state.jornada != null) p.set('jornada', state.jornada);
    return p.toString();
  }

  async function loadTable() {
    const tbody = $('#tableBody');
    if (!tbody) return;
    tbody.innerHTML = Array.from({ length: Math.min(state.limit, 10) }, () =>
      '<tr class="p-skeleton-row"><td><div class="p-skeleton-cell avatar"></div></td><td><div class="p-skeleton-cell"></div></td><td><div class="p-skeleton-cell"></div></td><td><div class="p-skeleton-cell"></div></td><td><div class="p-skeleton-cell"></div></td><td><div class="p-skeleton-cell"></div></td><td><div class="p-skeleton-cell"></div></td><td><div class="p-skeleton-cell"></div></td></tr>'
    ).join('');
    try {
      const qs = buildQueryString();
      const resp = await apiCall('GET', '?' + qs);
      const payload = resp.datos || {};
      state.data = payload.data || [];
      state.total = payload.pagination?.total || 0;
      state.totalPages = payload.pagination?.totalPages || 1;
      state.page = payload.pagination?.page || 1;
      rowMap.clear();
      state.data.forEach(item => rowMap.set(item.id, item));
      renderTable();
      renderPagination();
      $('#totalBadge').textContent = state.total + ' registros';
    } catch (e) {
      tbody.innerHTML = '<tr><td colspan="8" class="p-empty"><div class="p-empty-icon">!</div><h3>Error al cargar datos</h3><p>' + esc(e.message) + '</p></td></tr>';
    }
  }

  function renderTable() {
    const tbody = $('#tableBody');
    if (!tbody) return;
    closeActionsMenu(false);
    if (state.data.length === 0) {
      const hasFilters = state.search || state.estado || state.grado || state.rol || state.grupo || state.jornada;
      const emptyTitle = hasFilters ? 'No se encontraron resultados' : 'No hay personal registrado';
      const emptyDesc = hasFilters ? 'Pruebe con otros términos o limpie los filtros' : 'Cree el primer registro para comenzar';
      const emptyBtn = hasFilters
        ? '<button class="p-btn p-btn-secondary" id="emptyAction">Limpiar filtros</button>'
        : (D.canCreate ? '<button class="p-btn p-btn-primary" id="emptyAction">Crear personal</button>' : '');
      tbody.innerHTML = '<tr><td colspan="8"><div class="p-empty"><div class="p-empty-icon"><svg width="28" height="28" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"/><path d="m21 21-4.35-4.35"/></svg></div><h3>' + emptyTitle + '</h3><p>' + emptyDesc + '</p>' + emptyBtn + '</div></td></tr>';
      const actionBtn = $('#emptyAction');
      if (actionBtn) {
        actionBtn.addEventListener('click', hasFilters ? clearFilters : () => openFormModal('create'));
      }
      return;
    }
    let html = '';
    state.data.forEach(item => {
      const av = getAvatar(item.nombres, item.apellidos);
      const nombre = esc(item.nombre_completo || (item.nombres + ' ' + item.apellidos));
      const cedula = esc(item.cedula || '');
      const correo = esc(item.correo_institucional || '');
      const grado = esc(item.grado || '');
      const rol = esc(item.rol || '');
      const grupo = esc(item.grupo || '');
      const estado = esc(item.estado_personal || 'SIN ESTADO');
      const sc = statusClass(item.estado_personal);
      const hasActions = Boolean(D.canEdit || D.canResetPassword || D.canDelete);
      html += '<tr>';
      html += '<td><div class="p-name-cell"><span class="p-avatar" style="background:' + av.color + '">' + av.initials + '</span><span class="p-name-text">' + nombre + '</span></div></td>';
      html += '<td>' + cedula + '</td>';
      html += '<td><span class="p-truncate" title="' + correo + '">' + correo + '</span></td>';
      html += '<td>' + grado + '</td>';
      html += '<td>' + rol + '</td>';
      html += '<td>' + grupo + '</td>';
      html += '<td><span class="p-status ' + sc + '"><span class="p-status-dot"></span>' + estado + '</span></td>';
      html += '<td class="p-actions-cell"><div class="p-actions">';
      html += hasActions
        ? '<button type="button" class="p-actions-trigger" data-actions-trigger="' + item.id + '" aria-label="Acciones de ' + nombre + '" aria-haspopup="menu" aria-expanded="false" aria-controls="personalActionsMenu"><span aria-hidden="true">&#8942;</span></button>'
        : '<span class="p-no-actions">Sin acciones</span>';
      html += '</div></td></tr>';
    });
    tbody.innerHTML = html;
  }

  function renderPagination() {
    const info = $('#paginationInfo');
    const controls = $('#paginationControls');
    if (!info || !controls) return;
    const from = state.total === 0 ? 0 : ((state.page - 1) * state.limit + 1);
    const to = Math.min(state.page * state.limit, state.total);
    info.textContent = 'Mostrando ' + from + ' a ' + to + ' de ' + state.total + ' registros';
    let html = '';
    html += '<button class="p-pagination-btn" ' + (state.page <= 1 ? 'disabled' : '') + ' data-page="' + (state.page - 1) + '">&lsaquo;</button>';
    const maxBtns = 5;
    let start = Math.max(1, state.page - Math.floor(maxBtns / 2));
    let end = Math.min(state.totalPages, start + maxBtns - 1);
    if (end - start < maxBtns - 1) start = Math.max(1, end - maxBtns + 1);
    if (start > 1) html += '<button class="p-pagination-btn" data-page="1">1</button>';
    if (start > 2) html += '<span class="p-pagination-btn" style="border:none;background:none;cursor:default">...</span>';
    for (let i = start; i <= end; i++) {
      html += '<button class="p-pagination-btn ' + (i === state.page ? 'is-active' : '') + '" data-page="' + i + '">' + i + '</button>';
    }
    if (end < state.totalPages - 1) html += '<span class="p-pagination-btn" style="border:none;background:none;cursor:default">...</span>';
    if (end < state.totalPages) html += '<button class="p-pagination-btn" data-page="' + state.totalPages + '">' + state.totalPages + '</button>';
    html += '<button class="p-pagination-btn" ' + (state.page >= state.totalPages ? 'disabled' : '') + ' data-page="' + (state.page + 1) + '">&rsaquo;</button>';
    controls.innerHTML = html;
  }

  function openModal(id) { $('#' + id).classList.add('is-open'); }
  function closeModal(id) {
    $('#' + id).classList.remove('is-open');
    if (id === 'modalOverlay') {
      const btn = $('#createBtn');
      if (btn) btn.focus();
    }
  }

  function openFormModal(mode, data) {
    editingId = mode === 'edit' ? data.id : null;
    $('#modalTitle').textContent = mode === 'edit' ? 'Editar Personal' : 'Nuevo Personal';
    $('#submitText').textContent = mode === 'edit' ? 'Guardar cambios' : 'Guardar';
    const form = $('#personForm');
    form.reset();
    $$('.p-field-error').forEach(e => e.textContent = '');
    $$('.p-field input.error, .p-field select.error').forEach(e => e.classList.remove('error'));
    if (mode === 'edit' && data) {
      $('#formId').value = data.id || '';
      $('#formCedula').value = data.cedula || '';
      $('#formNombres').value = data.nombres || '';
      $('#formApellidos').value = data.apellidos || '';
      $('#formCorreo').value = data.correo_institucional || '';
      $('#formTelefono').value = data.telefono || '';
      $('#formGrado').value = data.grado_id || '';
      $('#formRol').value = data.rol_id || '';
      $('#formGrupo').value = data.grupo_id || '';
      $('#formJornada').value = data.jornada_id || '';
      $('#formEstado').value = data.estado_personal_id || '';
      $('#formActivo').checked = Boolean(data.activo);
      $('#formPassword').value = '';
      $('#formPassword').placeholder = 'Dejar vacío para mantener la contraseña actual';
      $('#passwordHint').textContent = 'Dejar vacío para mantener';
    } else {
      $('#formId').value = '';
      $('#formPassword').placeholder = 'Dejar vacío para generar automáticamente';
      $('#passwordHint').textContent = 'Mínimo 6 caracteres';
    }
    openModal('modalOverlay');
    setTimeout(() => $('#formCedula').focus(), 100);
  }

  function validateForm() {
    let valid = true;
    const fields = [
      { id: 'formCedula', err: 'errCedula', msg: 'La cédula es obligatoria' },
      { id: 'formNombres', err: 'errNombres', msg: 'Los nombres son obligatorios' },
      { id: 'formApellidos', err: 'errApellidos', msg: 'Los apellidos son obligatorios' },
      { id: 'formCorreo', err: 'errCorreo', msg: 'El correo es obligatorio' },
      { id: 'formGrado', err: 'errGrado', msg: 'Debe seleccionar un grado' },
      { id: 'formRol', err: 'errRol', msg: 'Debe seleccionar un rol' },
      { id: 'formJornada', err: 'errJornada', msg: 'Debe seleccionar una jornada' },
    ];
    fields.forEach(f => {
      const el = $('#' + f.id);
      const errEl = $('#' + f.err);
      el.classList.remove('error');
      errEl.textContent = '';
      if (!el.value.trim()) {
        el.classList.add('error');
        errEl.textContent = f.msg;
        valid = false;
      }
    });
    const correo = $('#formCorreo');
    if (correo.value && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(correo.value)) {
      correo.classList.add('error');
      $('#errCorreo').textContent = 'El correo no es válido';
      valid = false;
    }
    const pw = $('#formPassword');
    if (!editingId && pw.value && pw.value.length < 6) {
      pw.classList.add('error');
      $('#errPassword').textContent = 'Mínimo 6 caracteres';
      valid = false;
    }
    return valid;
  }

  async function submitForm() {
    if (isSaving) return;
    if (!validateForm()) return;
    isSaving = true;
    const btn = $('#modalSubmit');
    const origHTML = btn.innerHTML;
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Guardando...';
    const payload = {
      cedula: $('#formCedula').value.trim(),
      nombres: $('#formNombres').value.trim(),
      apellidos: $('#formApellidos').value.trim(),
      correo_institucional: $('#formCorreo').value.trim(),
      telefono: $('#formTelefono').value.trim() || null,
      cargo_id: null,
      area_id: null,
      grupo_id: $('#formGrupo').value ? parseInt($('#formGrupo').value) : null,
      jornada_id: $('#formJornada').value ? parseInt($('#formJornada').value) : null,
      rol_id: $('#formRol').value ? parseInt($('#formRol').value) : null,
      grado_id: $('#formGrado').value ? parseInt($('#formGrado').value) : null,
      estado_personal_id: $('#formEstado').value ? parseInt($('#formEstado').value) : null,
      activo: $('#formActivo').checked,
    };
    const pw = $('#formPassword').value.trim();
    if (pw) payload.password = pw;
    try {
      if (editingId) {
        await apiCall('PUT', '' + editingId, payload);
        toast('Datos del personal actualizados correctamente.');
      } else {
        await apiCall('POST', '', payload);
        toast('Personal registrado correctamente.');
      }
      closeModal('modalOverlay');
      loadTable();
    } catch (e) {
      toast(e.message, 'error');
    } finally {
      btn.disabled = false;
      btn.innerHTML = origHTML;
      isSaving = false;
    }
  }

  async function deletePerson() {
    if (!deleteTargetId) return;
    const btn = $('#deleteConfirmBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Eliminando...';
    try {
      await apiCall('DELETE', '' + deleteTargetId);
      toast('Personal eliminado correctamente.');
      closeModal('deleteOverlay');
      loadTable();
    } catch (e) {
      toast(e.message, 'error');
    } finally {
      btn.disabled = false;
      btn.innerHTML = '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg> Eliminar registro';
    }
  }

  async function resetPassword() {
    if (!resetTargetId) return;
    const btn = $('#resetConfirmBtn');
    btn.disabled = true;
    btn.innerHTML = '<span class="spinner"></span> Generando...';
    try {
      const resp = await apiCall('POST', resetTargetId + '/reset-password');
      const pw = resp.datos?.password || '';
      $('#resetResult').style.display = 'block';
      $('#resetPassword').textContent = pw;
      btn.style.display = 'none';
      toast('Contraseña restablecida correctamente.');
    } catch (e) {
      toast(e.message, 'error');
    } finally {
      btn.disabled = false;
      btn.innerHTML = 'Generar contraseña';
    }
  }

  function ensureActionsMenu() {
    if (actionsMenu) return actionsMenu;
    actionsMenu = document.createElement('div');
    actionsMenu.id = 'personalActionsMenu';
    actionsMenu.className = 'p-actions-menu';
    actionsMenu.setAttribute('role', 'menu');
    actionsMenu.setAttribute('aria-hidden', 'true');
    document.body.appendChild(actionsMenu);
    return actionsMenu;
  }

  function buildActionsMenu(personId) {
    const isCurrentUser = Number(D.currentUserId) === Number(personId);
    let html = '';
    if (D.canEdit) {
      html += '<button type="button" class="p-actions-menu-item" role="menuitem" data-action="edit" data-id="' + personId + '"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/><path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/></svg><span>Editar</span></button>';
    }
    if (D.canResetPassword) {
      html += '<button type="button" class="p-actions-menu-item" role="menuitem" data-action="reset" data-id="' + personId + '"><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg><span>Restablecer contraseña</span></button>';
    }
    if (D.canDelete) {
      html += '<div class="p-actions-menu-divider" role="separator"></div>';
      html += '<button type="button" class="p-actions-menu-item p-actions-menu-delete" role="menuitem" data-action="delete" data-id="' + personId + '"' + (isCurrentUser ? ' disabled aria-disabled="true" title="No puede eliminar su propia cuenta"' : '') + '><svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/></svg><span>Eliminar' + (isCurrentUser ? '<small>Cuenta actual</small>' : '') + '</span></button>';
    }
    return html;
  }

  function positionActionsMenu() {
    if (!actionsMenu || !activeActionsTrigger || !actionsMenu.classList.contains('is-open')) return;
    const triggerRect = activeActionsTrigger.getBoundingClientRect();
    const menuRect = actionsMenu.getBoundingClientRect();
    const gap = 6;
    const margin = 8;
    const left = Math.min(
      Math.max(margin, triggerRect.right - menuRect.width),
      window.innerWidth - menuRect.width - margin
    );
    const fitsBelow = triggerRect.bottom + gap + menuRect.height <= window.innerHeight - margin;
    const top = fitsBelow
      ? triggerRect.bottom + gap
      : Math.max(margin, triggerRect.top - menuRect.height - gap);
    actionsMenu.style.left = left + 'px';
    actionsMenu.style.top = top + 'px';
    actionsMenu.style.visibility = 'visible';
  }

  function closeActionsMenu(restoreFocus = true) {
    if (!actionsMenu) return;
    actionsMenu.classList.remove('is-open');
    actionsMenu.setAttribute('aria-hidden', 'true');
    actionsMenu.style.visibility = 'hidden';
    if (activeActionsTrigger) {
      activeActionsTrigger.setAttribute('aria-expanded', 'false');
      if (restoreFocus && document.contains(activeActionsTrigger)) activeActionsTrigger.focus();
    }
    activeActionsId = null;
    activeActionsTrigger = null;
  }

  function toggleActionsMenu(trigger, personId) {
    if (activeActionsId === personId && actionsMenu?.classList.contains('is-open')) {
      closeActionsMenu();
      return;
    }
    closeActionsMenu(false);
    const menu = ensureActionsMenu();
    activeActionsId = personId;
    activeActionsTrigger = trigger;
    menu.innerHTML = buildActionsMenu(personId);
    menu.classList.add('is-open');
    menu.setAttribute('aria-hidden', 'false');
    menu.style.visibility = 'hidden';
    trigger.setAttribute('aria-expanded', 'true');
    positionActionsMenu();
    menu.querySelector('button:not(:disabled)')?.focus();
  }

  document.addEventListener('click', async (e) => {
    const menuTrigger = e.target.closest('[data-actions-trigger]');
    if (menuTrigger) {
      e.preventDefault();
      e.stopPropagation();
      toggleActionsMenu(menuTrigger, parseInt(menuTrigger.dataset.actionsTrigger, 10));
      return;
    }

    const actionBtn = e.target.closest('[data-action]');
    if (actionBtn) {
      e.stopPropagation();
      const action = actionBtn.dataset.action;
      const id = parseInt(actionBtn.dataset.id, 10);
      const row = rowMap.get(id);
      if (!row) return;
      closeActionsMenu(false);
      if (action === 'edit') {
        actionBtn.disabled = true;
        try {
          const response = await apiCall('GET', String(id));
          openFormModal('edit', response.datos || row);
        } catch (error) {
          toast(error.message, 'error');
        } finally {
          actionBtn.disabled = false;
        }
      } else if (action === 'delete') {
        deleteTargetId = id;
        $('#deleteName').textContent = row.nombre_completo || (row.nombres + ' ' + row.apellidos);
        $('#deleteCedula').textContent = row.cedula || '';
        openModal('deleteOverlay');
      } else if (action === 'reset') {
        resetTargetId = id;
        $('#resetName').textContent = row.nombre_completo || (row.nombres + ' ' + row.apellidos);
        $('#resetResult').style.display = 'none';
        $('#resetConfirmBtn').style.display = '';
        openModal('resetOverlay');
      }
      return;
    }

    if (actionsMenu?.classList.contains('is-open') && !actionsMenu.contains(e.target)) {
      closeActionsMenu(false);
    }
  });

  window.addEventListener('resize', positionActionsMenu);
  window.addEventListener('scroll', positionActionsMenu, true);

  if ($('#createBtn')) {
    $('#createBtn').addEventListener('click', () => openFormModal('create'));
  }

  if ($('#personForm')) {
    $('#personForm').addEventListener('submit', (e) => { e.preventDefault(); submitForm(); });
  }

  if ($('#modalClose')) $('#modalClose').addEventListener('click', () => closeModal('modalOverlay'));
  if ($('#modalCancel')) $('#modalCancel').addEventListener('click', () => closeModal('modalOverlay'));
  if ($('#deleteClose')) $('#deleteClose').addEventListener('click', () => closeModal('deleteOverlay'));
  if ($('#deleteCancelBtn')) $('#deleteCancelBtn').addEventListener('click', () => closeModal('deleteOverlay'));
  if ($('#deleteConfirmBtn')) $('#deleteConfirmBtn').addEventListener('click', deletePerson);
  if ($('#resetClose')) $('#resetClose').addEventListener('click', () => closeModal('resetOverlay'));
  if ($('#resetCancelBtn')) $('#resetCancelBtn').addEventListener('click', () => closeModal('resetOverlay'));
  if ($('#resetConfirmBtn')) $('#resetConfirmBtn').addEventListener('click', resetPassword);

  $$('.p-modal-overlay').forEach(ov => {
    ov.addEventListener('click', (e) => {
      if (e.target === ov) {
        if (ov.id === 'modalOverlay' && isSaving) return;
        ov.classList.remove('is-open');
      }
    });
  });

  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
      if (isSaving) return;
      $$('.p-modal-overlay.is-open').forEach(ov => ov.classList.remove('is-open'));
      closeActionsMenu(false);
    }
  });

  if ($('#pwToggle')) {
    $('#pwToggle').addEventListener('click', () => {
      const inp = $('#formPassword');
      inp.type = inp.type === 'password' ? 'text' : 'password';
    });
  }

  if ($('#searchInput')) {
    $('#searchInput').addEventListener('input', (e) => {
      const v = e.target.value;
      $('#searchWrap').classList.toggle('has-value', v.length > 0);
      clearTimeout(searchTimer);
      searchTimer = setTimeout(() => {
        state.search = v.trim();
        state.page = 1;
        loadTable();
      }, 400);
    });
  }

  if ($('#searchClear')) {
    $('#searchClear').addEventListener('click', () => {
      $('#searchInput').value = '';
      $('#searchWrap').classList.remove('has-value');
      state.search = '';
      state.page = 1;
      loadTable();
    });
  }

  if ($('#filtersBtn')) {
    $('#filtersBtn').addEventListener('click', () => {
      $('#filtersPanel').classList.toggle('is-open');
    });
  }

  if ($('#applyFiltersBtn')) {
    $('#applyFiltersBtn').addEventListener('click', () => {
      state.estado = $('#filterEstado').value || null;
      state.grado = $('#filterGrado').value || null;
      state.rol = $('#filterRol').value || null;
      state.grupo = $('#filterGrupo').value || null;
      state.jornada = $('#filterJornada').value || null;
      state.page = 1;
      updateFilterBadge();
      loadTable();
    });
  }

  if ($('#clearFiltersBtn')) {
    $('#clearFiltersBtn').addEventListener('click', clearFilters);
  }

  function clearFilters() {
    $('#filterEstado').value = '';
    $('#filterGrado').value = '';
    $('#filterRol').value = '';
    $('#filterGrupo').value = '';
    $('#filterJornada').value = '';
    state.estado = null;
    state.grado = null;
    state.rol = null;
    state.grupo = null;
    state.jornada = null;
    state.page = 1;
    updateFilterBadge();
    loadTable();
  }

  function updateFilterBadge() {
    const badge = $('#filtersBadge');
    if (!badge) return;
    let count = 0;
    if (state.estado) count++;
    if (state.grado) count++;
    if (state.rol) count++;
    if (state.grupo) count++;
    if (state.jornada) count++;
    badge.style.display = count > 0 ? '' : 'none';
    badge.textContent = count;
  }

  if ($('#pageSizeSelect')) {
    $('#pageSizeSelect').addEventListener('change', (e) => {
      state.limit = parseInt(e.target.value) || 10;
      state.page = 1;
      loadTable();
    });
  }

  document.addEventListener('click', (e) => {
    const pageBtn = e.target.closest('.p-pagination-btn[data-page]');
    if (pageBtn && !pageBtn.disabled) {
      const p = parseInt(pageBtn.dataset.page);
      if (p >= 1 && p <= state.totalPages) {
        state.page = p;
        loadTable();
      }
    }
  });

  window.__PERSONAL__ = { openCreate: () => openFormModal('create'), clearFilters };

  loadTable();
})();
