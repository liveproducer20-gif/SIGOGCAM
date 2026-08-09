(function () {
    'use strict';
    const app = document.querySelector('.td-app');
    if (!app) return;
    const $ = (selector, root = document) => root.querySelector(selector);
    const $$ = (selector, root = document) => Array.from(root.querySelectorAll(selector));
    const catalogs = JSON.parse($('#tdCatalogs')?.textContent || '{}');
    const canAssign = app.dataset.canAssign === '1';
    const canDelete = app.dataset.canDelete === '1';

    const state = {
        districtId: 0, shiftId: 0, board: null, routeId: 0,
        places: new Map(), assignments: [], agentTarget: null, availability: null,
        saved: null, editingId: 0,
    };

    async function api(resource, options = {}) {
        const response = await fetch(`/distribucion-tablero/api?resource=${encodeURIComponent(resource)}`, {
            method: options.method || 'GET',
            headers: options.body ? {'Content-Type': 'application/json'} : {},
            body: options.body ? JSON.stringify(options.body) : undefined,
        });
        const payload = await response.json().catch(() => ({ok: false, mensaje: 'Respuesta inválida del servidor.'}));
        if (!response.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'No fue posible completar la operación.');
        return payload.datos;
    }

    function esc(value) { const node = document.createElement('div'); node.textContent = value ?? ''; return node.innerHTML; }
    function notify(message, error = false) {
        const toast = $('#tdToast'); toast.textContent = message; toast.classList.toggle('is-error', error); toast.classList.add('is-visible');
        clearTimeout(notify.timer); notify.timer = setTimeout(() => toast.classList.remove('is-visible'), 4300);
    }
    function loading(button, active) {
        if (!button) return; button.disabled = active;
        if (active) { button.dataset.label = button.innerHTML; button.innerHTML = '<span class="td-loading"></span> Procesando...'; }
        else if (button.dataset.label) button.innerHTML = button.dataset.label;
    }
    function openModal(id) { const modal = document.getElementById(id); if (modal) modal.hidden = false; }
    function closeModal(id) { const modal = document.getElementById(id); if (modal) modal.hidden = true; }
    function draftKey() { return `sigo-distribucion-draft:${state.districtId}:${state.shiftId}`; }
    function saveDraft() {
        if (!state.districtId || !state.shiftId) return;
        sessionStorage.setItem(draftKey(), JSON.stringify({assignments: state.assignments, updatedAt: new Date().toISOString()}));
    }
    function restoreDraft() {
        try { state.assignments = JSON.parse(sessionStorage.getItem(draftKey()) || '{}').assignments || []; }
        catch (_) { state.assignments = []; }
    }
    function usedAgentIds(exceptAgentId = 0) { return state.assignments.map(item => Number(item.agente_id)).filter(id => id !== Number(exceptAgentId)); }
    function assignmentsFor(placeId) { return state.assignments.filter(item => Number(item.lugar_id) === Number(placeId)); }
    function initials(name) { return String(name || 'A').split(/\s+/).filter(Boolean).slice(-2).map(part => part[0]).join('').toUpperCase(); }

    async function loadBoard() {
        state.districtId = Number($('#tdDistrict').value || 0);
        state.shiftId = Number($('#tdShift').value || 0);
        if (!state.districtId || !state.shiftId) {
            state.board = null; state.routeId = 0; state.assignments = []; state.places.clear();
            $('#tdRouteList').innerHTML = '<div class="td-empty-small">Seleccione distrito y turno.</div>';
            showEmpty(); return;
        }
        try {
            state.board = await api(`distribucion-tablero/tablero?distrito_id=${state.districtId}&turno_id=${state.shiftId}`);
            state.places.clear(); restoreDraft(); renderRoutes();
            const first = state.board.rutas?.find(route => Number(route.lugares || 0) > 0) || state.board.rutas?.[0];
            if (first) await selectRoute(Number(first.id)); else showEmpty('No existen rutas para la selección actual.');
            await refreshAvailability();
        } catch (error) { notify(error.message, true); showEmpty(error.message); }
    }

    function showEmpty(message = 'Elija un distrito, turno y una ruta para comenzar la distribución.') {
        $('#tdEmptyBoard').hidden = false; $('#tdRouteWorkspace').hidden = true;
        $('#tdEmptyBoard p').textContent = message;
    }
    function renderRoutes() {
        const query = $('#tdRouteSearch').value.trim().toLowerCase();
        const routes = (state.board?.rutas || []).filter(route => String(route.nombre).toLowerCase().includes(query));
        $('#tdRouteList').innerHTML = routes.length ? routes.map(route => `
            <button class="td-route-item ${Number(route.id) === state.routeId ? 'is-active' : ''}" type="button" data-route-id="${route.id}">
                <i>⌖</i><span><b>${esc(route.nombre)}</b><small>${Number(route.lugares || 0)} ${Number(route.lugares || 0) === 1 ? 'lugar' : 'lugares'}</small></span>
            </button>`).join('') : '<div class="td-empty-small">No se encontraron rutas.</div>';
    }
    async function ensurePlaces(routeId) {
        if (!state.places.has(routeId)) state.places.set(routeId, await api(`distribucion-tablero/rutas/${routeId}/lugares?turno_id=${state.shiftId}`));
        return state.places.get(routeId);
    }
    async function ensureAllPlaces() {
        await Promise.all((state.board?.rutas || []).map(route => ensurePlaces(Number(route.id))));
    }
    async function selectRoute(routeId) {
        state.routeId = routeId; renderRoutes();
        try { await ensurePlaces(routeId); renderWorkspace(); }
        catch (error) { notify(error.message, true); }
    }

    function routeData() { return (state.board?.rutas || []).find(route => Number(route.id) === state.routeId); }
    function routeStats() {
        const places = state.places.get(state.routeId) || [];
        const required = places.reduce((sum, place) => sum + Number(place.cantidad_requerida || 0), 0);
        const assigned = places.reduce((sum, place) => sum + assignmentsFor(place.id).length, 0);
        return {places: places.length, required, assigned, pending: Math.max(0, required - assigned), coverage: required ? Math.round(assigned / required * 100) : 0};
    }
    function renderWorkspace() {
        const route = routeData(); if (!route) return showEmpty();
        const places = state.places.get(state.routeId) || []; const stats = routeStats();
        $('#tdEmptyBoard').hidden = true; $('#tdRouteWorkspace').hidden = false;
        $('#tdRouteName').textContent = route.nombre;
        $('#tdRoutePlacesBadge').textContent = `${stats.places} ${stats.places === 1 ? 'lugar' : 'lugares'}`;
        $('#tdKpiPlaces').textContent = stats.places; $('#tdKpiRequired').textContent = stats.required;
        $('#tdKpiAssigned').textContent = stats.assigned; $('#tdKpiPending').textContent = stats.pending;
        $('#tdKpiCoverage').textContent = `${stats.coverage}%`; $('#tdCoverageBar').style.width = `${Math.min(100, stats.coverage)}%`;
        $('#tdCoverageLabel').textContent = stats.coverage >= 100 ? 'Ruta completa' : 'Ruta incompleta';
        $('#tdPlacesBody').innerHTML = places.length ? places.map((place, index) => renderPlaceRow(place, index)).join('') : '<tr><td colspan="6"><div class="td-empty-small">Esta ruta no tiene lugares de servicio activos.</div></td></tr>';
    }
    function renderPlaceRow(place, index) {
        const assigned = assignmentsFor(place.id); const required = Number(place.cantidad_requerida || 0); const covered = assigned.length >= required && required > 0;
        const agents = assigned.length ? assigned.map(item => `<div class="td-agent"><span class="td-avatar">${esc(initials(item.agente?.nombre_completo))}</span><div><b>${esc(item.agente?.nombre_completo || `Agente ${item.agente_id}`)}</b><small>${esc(item.agente?.cedula || '')}</small></div></div>`).join('') : '<div class="td-empty-agent"><span class="td-avatar">♙</span><div><b>Sin asignar</b><small>Seleccione un agente</small></div></div>';
        const actions = canAssign ? `${assigned.map(item => `<button type="button" data-change-agent="${item.agente_id}" data-place-id="${place.id}">Cambiar</button><button class="td-remove" type="button" data-remove-agent="${item.agente_id}" data-place-id="${place.id}">Quitar</button>`).join('')}${assigned.length < required ? `<button type="button" data-assign-place="${place.id}">♙ Asignar</button>` : ''}` : '—';
        return `<tr><td><span class="td-row-number">${index + 1}</span></td><td><div class="td-place-cell"><i>⌖</i><div><b>${esc(place.nombre)}</b><small>${esc(place.referencia)}</small></div></div></td><td class="td-required"><b>${required}</b>${required === 1 ? 'Agente' : 'Agentes'}</td><td>${agents}</td><td><span class="td-status ${covered ? 'td-status-assigned' : 'td-status-pending'}">${covered ? 'Asignado' : 'Pendiente'}</span></td><td><div class="td-actions">${actions}</div></td></tr>`;
    }

    async function refreshAvailability() {
        if (!state.districtId || !state.shiftId) return;
        try {
            state.availability = await api(`distribucion-tablero/disponibilidad?distrito_id=${state.districtId}&turno_id=${state.shiftId}&excluidos=${usedAgentIds().join(',')}`);
            $('#tdAvailable').textContent = state.availability.disponibles || 0; $('#tdInService').textContent = state.availability.en_servicio || 0;
            $('#tdUnavailable').textContent = state.availability.no_disponibles || 0; $('#tdTotalAgents').textContent = state.availability.total_agentes || 0;
        } catch (error) { notify(error.message, true); }
    }

    async function openAgentSelector(placeId, replaceAgentId = 0) {
        state.agentTarget = {placeId: Number(placeId), replaceAgentId: Number(replaceAgentId)};
        const place = (state.places.get(state.routeId) || []).find(item => Number(item.id) === Number(placeId));
        $('#tdAgentModalTitle').textContent = `${replaceAgentId ? 'Cambiar' : 'Asignar'} · ${place?.nombre || 'Lugar de servicio'}`;
        $('#tdAgentSearch').value = ''; $('#tdAgentList').innerHTML = '<div class="td-empty-small">Consultando personal disponible...</div>'; openModal('tdAgentModal');
        try {
            const excluded = usedAgentIds(replaceAgentId);
            const data = await api(`distribucion-tablero/disponibilidad?distrito_id=${state.districtId}&turno_id=${state.shiftId}&excluidos=${excluded.join(',')}`);
            state.agentTarget.agents = data.agentes || []; renderAgentOptions();
        } catch (error) { $('#tdAgentList').innerHTML = `<div class="td-empty-small">${esc(error.message)}</div>`; }
    }
    function renderAgentOptions() {
        if (!state.agentTarget) return; const query = $('#tdAgentSearch').value.trim().toLowerCase();
        const agents = (state.agentTarget.agents || []).filter(agent => `${agent.nombre_completo} ${agent.cedula}`.toLowerCase().includes(query));
        $('#tdAgentList').innerHTML = agents.length ? agents.map(agent => `<button class="td-agent-option" type="button" data-select-agent="${agent.id}"><span class="td-avatar">${esc(initials(agent.nombre_completo))}</span><span><b>${esc(agent.nombre_completo)}</b><small>${esc(agent.cedula)} · ${esc(agent.estado_personal)}</small></span></button>`).join('') : '<div class="td-empty-small">No hay agentes disponibles.</div>';
    }
    function chooseAgent(agentId) {
        const target = state.agentTarget; if (!target) return;
        const agent = (target.agents || []).find(item => Number(item.id) === Number(agentId)); if (!agent) return;
        if (target.replaceAgentId) state.assignments = state.assignments.filter(item => !(Number(item.lugar_id) === target.placeId && Number(item.agente_id) === target.replaceAgentId));
        if (usedAgentIds().includes(Number(agentId))) return notify('El agente ya está asignado en este borrador.', true);
        state.assignments.push({lugar_id: target.placeId, agente_id: Number(agentId), tipo_asignacion: 'MANUAL', agente: agent});
        saveDraft(); closeModal('tdAgentModal'); state.agentTarget = null; renderWorkspace(); refreshAvailability();
    }
    function removeAgent(placeId, agentId) {
        state.assignments = state.assignments.filter(item => !(Number(item.lugar_id) === Number(placeId) && Number(item.agente_id) === Number(agentId)));
        saveDraft(); renderWorkspace(); refreshAvailability();
    }

    async function randomAssign() {
        const button = $('#tdRandomAssign'); loading(button, true);
        try {
            const result = await api('distribucion-tablero/asignacion-aleatoria', {method: 'POST', body: {distrito_id: state.districtId, turno_id: state.shiftId, ruta_id: state.routeId, asignaciones: state.assignments.map(({lugar_id, agente_id, tipo_asignacion}) => ({lugar_id, agente_id, tipo_asignacion}))}});
            for (const assignment of result.asignaciones || []) state.assignments.push(assignment);
            saveDraft(); renderWorkspace(); await refreshAvailability();
            notify(result.insuficiente ? result.mensaje : 'Asignación aleatoria preparada sin repetir agentes.', Boolean(result.insuficiente));
        } catch (error) { notify(error.message, true); }
        finally { loading(button, false); }
    }

    function formatDate(value) { if (!value) return 'DD/MM/AAAA'; const [year, month, day] = value.split('-'); return `${day}/${month}/${year}`; }
    async function draftTotals() {
        await ensureAllPlaces(); let required = 0;
        for (const places of state.places.values()) for (const place of places) required += Number(place.cantidad_requerida || 0);
        return {required, assigned: state.assignments.length, pending: Math.max(0, required - state.assignments.length)};
    }
    async function openSave() {
        if (!state.districtId || !state.shiftId) return notify('Seleccione distrito y turno.', true);
        try { const totals = await draftTotals(); if (!totals.required) return notify('No existen lugares para guardar.', true); }
        catch (error) { return notify(error.message, true); }
        const editingDate = state.editingId && state.saved ? String(state.saved.fecha_distribucion || '').slice(0, 10) : '';
        $('#tdDistributionDate').value = editingDate;
        $('#tdGeneratedName').textContent = `DISTRIBUCIÓN DE PERSONAL FECHA ${formatDate(editingDate)}`;
        openModal('tdSaveModal');
    }
    async function requestSave(force = false) {
        const date = $('#tdDistributionDate').value; if (!date) return notify('Seleccione la fecha de distribución.', true);
        const totals = await draftTotals();
        if (totals.pending && !force) { closeModal('tdSaveModal'); openModal('tdPendingModal'); return; }
        const button = force ? $('#tdForceSave') : $('#tdConfirmSave'); loading(button, true);
        try {
            const resource = state.editingId ? `distribucion-tablero/distribuciones/${state.editingId}` : 'distribucion-tablero/distribuciones';
            const saved = await api(resource, {method: state.editingId ? 'PUT' : 'POST', body: {distrito_id: state.districtId, turno_id: state.shiftId, fecha_distribucion: date, guardar_con_pendientes: force, asignaciones: state.assignments.map(({lugar_id, agente_id, tipo_asignacion}) => ({lugar_id, agente_id, tipo_asignacion}))}});
            state.saved = await api(`distribucion-tablero/distribuciones/${saved.id}`);
            state.editingId = 0;
            sessionStorage.removeItem(draftKey()); closeModal('tdSaveModal'); closeModal('tdPendingModal'); renderSaved(); openModal('tdResultModal');
            notify('Distribución guardada correctamente.');
        } catch (error) { notify(error.message, true); }
        finally { loading(button, false); }
    }
    function renderSaved() {
        const saved = state.saved; if (!saved) return;
        $('#tdSavedName').textContent = saved.nombre;
        $('#tdSavedSummary').textContent = `${saved.distrito} · ${saved.turno} · ${Number(saved.porcentaje_cobertura || 0)}% de cobertura`;
        const groups = new Map(); for (const detail of saved.detalles || []) { if (!groups.has(detail.ruta)) groups.set(detail.ruta, []); groups.get(detail.ruta).push(detail); }
        $('#tdSavedDetail').innerHTML = Array.from(groups.entries()).map(([route, details]) => `<div class="td-saved-route"><b>${esc(route)}</b><div>${details.filter(item => item.agente_id).length} asignados · ${details.filter(item => !item.agente_id).length} pendientes</div></div>`).join('');
    }

    $('#tdDistrict').addEventListener('change', loadBoard); $('#tdShift').addEventListener('change', loadBoard);
    $('#tdRouteSearch').addEventListener('input', renderRoutes); $('#tdRouteList').addEventListener('click', event => { const item = event.target.closest('[data-route-id]'); if (item) selectRoute(Number(item.dataset.routeId)); });
    $('#tdPlacesBody').addEventListener('click', event => {
        const assign = event.target.closest('[data-assign-place]'); const change = event.target.closest('[data-change-agent]'); const remove = event.target.closest('[data-remove-agent]');
        if (assign) openAgentSelector(assign.dataset.assignPlace); if (change) openAgentSelector(change.dataset.placeId, change.dataset.changeAgent); if (remove) removeAgent(remove.dataset.placeId, remove.dataset.removeAgent);
    });
    $('#tdAgentSearch').addEventListener('input', renderAgentOptions); $('#tdAgentList').addEventListener('click', event => { const item = event.target.closest('[data-select-agent]'); if (item) chooseAgent(item.dataset.selectAgent); });
    $('#tdRandomAssign')?.addEventListener('click', randomAssign); $('#tdSaveDraft')?.addEventListener('click', openSave);
    $('#tdDistributionDate').addEventListener('change', event => { $('#tdGeneratedName').textContent = `DISTRIBUCIÓN DE PERSONAL FECHA ${formatDate(event.target.value)}`; });
    $('#tdConfirmSave').addEventListener('click', () => requestSave(false)); $('#tdForceSave').addEventListener('click', () => requestSave(true));
    $$('[data-close]').forEach(button => button.addEventListener('click', () => closeModal(button.dataset.close)));
    $$('.td-modal').forEach(modal => modal.addEventListener('click', event => { if (event.target === modal) modal.hidden = true; }));
    $('#tdViewSaved').addEventListener('click', () => { renderSaved(); notify('Detalle de la distribución cargado.'); });
    $('#tdEditSaved').addEventListener('click', () => {
        if (!state.saved) return;
        state.editingId = Number(state.saved.id);
        state.assignments = (state.saved.detalles || []).filter(item => item.agente_id).map(item => ({
            lugar_id: Number(item.lugar_id), agente_id: Number(item.agente_id), tipo_asignacion: item.tipo_asignacion || 'MANUAL',
            agente: {id: Number(item.agente_id), nombre_completo: item.agente, cedula: item.cedula},
        }));
        saveDraft(); closeModal('tdResultModal'); renderWorkspace(); refreshAvailability();
        notify('Distribución abierta para edición. Realice los cambios y pulse Guardar distribución.');
    });
    $('#tdPrintSaved').addEventListener('click', () => window.print()); $('#tdPdfSaved').addEventListener('click', () => { notify('Seleccione “Guardar como PDF” en el diálogo de impresión.'); setTimeout(() => window.print(), 250); });
    $('#tdDeleteSaved')?.addEventListener('click', async () => {
        if (!state.saved || !canDelete || !confirm('¿Eliminar esta distribución y cancelar sus asignaciones?')) return;
        try { await api(`distribucion-tablero/distribuciones/${state.saved.id}`, {method: 'DELETE'}); closeModal('tdResultModal'); state.saved = null; state.editingId = 0; notify('Distribución eliminada correctamente.'); }
        catch (error) { notify(error.message, true); }
    });
    if (catalogs.distritos?.length === 1) $('#tdDistrict').value = String(catalogs.distritos[0].id);
    if (catalogs.turnos?.length === 1) $('#tdShift').value = String(catalogs.turnos[0].id);
    if ($('#tdDistrict').value && $('#tdShift').value) loadBoard();
})();
