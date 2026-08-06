(function () {
    'use strict';
    const app = document.querySelector('.td-app');
    if (!app) return;

    const $ = (s, r = document) => r.querySelector(s);
    const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
    const perms = { assign: app.dataset.canAssign === '1', config: app.dataset.canConfig === '1', clean: app.dataset.canClean === '1' };
    const catalogData = JSON.parse($('#tdCatalogs')?.textContent || '{}');

    let currentRoute = null, currentShift = null, currentFecha = null, currentSectors = [];
    let sorteoData = null;

    async function api(resource, opts = {}) {
        const res = await fetch(`/distribucion-tablero/api?resource=${encodeURIComponent(resource)}`, {
            method: opts.method || 'GET',
            headers: opts.body ? { 'Content-Type': 'application/json' } : {},
            body: opts.body ? JSON.stringify(opts.body) : undefined,
        });
        const payload = await res.json().catch(() => ({ ok: false, mensaje: 'Respuesta invalida del servidor.' }));
        if (!res.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'Error al procesar la operacion.');
        return payload;
    }

    function notify(msg, err = false) {
        const t = $('#tdToast');
        t.textContent = msg; t.classList.toggle('is-error', err); t.classList.add('is-visible');
        clearTimeout(notify._t); notify._t = setTimeout(() => t.classList.remove('is-visible'), 4200);
    }

    function esc(v) { const d = document.createElement('div'); d.textContent = v ?? ''; return d.innerHTML; }
    function timeStr(v) { return v ? String(v).slice(0, 5) : '—'; }

    function setLoading(btn, loading) {
        if (!btn) return;
        btn.disabled = loading;
        if (loading) { btn._origText = btn.textContent; btn.innerHTML = '<span class="td-loading"></span> Procesando...'; }
        else { btn.textContent = btn._origText || btn.textContent; }
    }

    async function loadRoutes(districtId, target, selected = '') {
        target.innerHTML = '<option value="">Seleccione</option>';
        target.disabled = !districtId;
        if (!districtId) return;
        try {
            const items = (await api(`distritos/${districtId}/rutas`)).datos || [];
            items.forEach(i => target.add(new Option(i.nombre, i.id)));
            if (selected) target.value = String(selected);
        } catch (e) { notify(e.message, true); }
    }

    $('#tdDistrict').addEventListener('change', e => loadRoutes(e.target.value, $('#tdRoute')));

    $('#tdShift').addEventListener('change', e => {
        const opt = e.target.selectedOptions[0];
        currentShift = {
            nombre: e.target.value,
            hora_inicio: opt?.dataset.start || '',
            hora_fin: opt?.dataset.end || '',
        };
    });

    $('#tdDate').value = new Date().toISOString().slice(0, 10);

    $('#tdLoadRoute').addEventListener('click', async () => {
        const routeId = $('#tdRoute').value;
        const fecha = $('#tdDate').value;
        const turno = $('#tdShift').value;
        if (!routeId || !fecha || !turno) return notify('Seleccione distrito, ruta, fecha y turno.', true);
        setLoading($('#tdLoadRoute'), true);
        try {
            const shiftOpt = $('#tdShift').selectedOptions[0];
            currentRoute = (await api(`distribucion-tablero/rutas/${routeId}/info`)).datos;
            currentFecha = fecha;
            currentShift = { nombre: turno, hora_inicio: shiftOpt?.dataset.start || '', hora_fin: shiftOpt?.dataset.end || '' };
            currentSectors = (await api(`distribucion-tablero/rutas/${routeId}/sectores`)).datos || [];
            const stats = (await api(`distribucion-tablero/rutas/${routeId}/estadisticas?fecha=${fecha}&turno=${encodeURIComponent(turno)}`)).datos || {};
            renderRouteInfo(stats);
            $('#tdRouteInfo').hidden = false;
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdLoadRoute'), false); }
    });

    function renderRouteInfo(stats) {
        if (!currentRoute) return;
        $('#tdRouteName').textContent = currentRoute.nombre;
        $('#tdRouteDistrict').textContent = currentRoute.distrito || '';
        $('#tdStatSectores').textContent = stats.total_sectores || 0;
        $('#tdStatRequeridos').textContent = stats.agentes_requeridos || 0;
        $('#tdStatAsignados').textContent = stats.agentes_asignados || 0;
        $('#tdStatPendientes').textContent = stats.agentes_pendientes || 0;
        const cob = stats.cobertura || 0;
        $('#tdStatCobertura').textContent = cob + '%';
        $('#tdCoverageFill').style.width = cob + '%';
        $('#tdCoverageFill').style.background = cob >= 100 ? '#55ad38' : cob >= 50 ? '#e3ad23' : '#e63c3c';
    }

    $('#tdViewSectors').addEventListener('click', async () => {
        if (!currentRoute) return;
        const panel = $('#tdSectorsPanel');
        if (!panel.hidden) { panel.hidden = true; return; }
        try {
            currentSectors = (await api(`distribucion-tablero/rutas/${currentRoute.id}/sectores`)).datos || [];
            const list = $('#tdSectorsList');
            if (!currentSectors.length) { list.innerHTML = '<div class="td-empty-state"><span>▧</span><strong>No hay lugares configurados</strong><p>Agregue lugares desde la administracion.</p></div>'; panel.hidden = false; return; }
            list.innerHTML = currentSectors.map(s => {
                const assigned = s.agentes_asignados || 0;
                const required = s.cantidad_agentes_requeridos || 0;
                const badgeClass = assigned >= required ? 'td-badge-ok' : assigned > 0 ? 'td-badge-partial' : 'td-badge-empty';
                const badgeText = assigned >= required ? 'Cubierto' : assigned > 0 ? 'Parcial' : 'Sin personal';
                return `<div class="td-place-card"><div><div class="td-place-name">${esc(s.nombre)}</div><div class="td-place-meta">${assigned} / ${required} agentes asignados</div></div><span class="td-sector-badge ${badgeClass}">${badgeText}</span></div>`;
            }).join('');
            panel.hidden = false;
        } catch (e) { notify(e.message, true); }
    });

    $('#tdCloseSectors')?.addEventListener('click', () => $('#tdSectorsPanel').hidden = true);

    $('#tdConfigSectors')?.addEventListener('click', () => {
        if (!currentSectors.length) return notify('Cargue la ruta primero.', true);
        const table = $('#tdConfigTable');
        table.innerHTML = currentSectors.map(s => `<div class="td-config-row"><span class="td-config-label">${esc(s.nombre)}</span><input class="td-config-input" type="number" min="0" max="100" value="${s.cantidad_agentes_requeridos || 1}" data-sector-id="${s.id}"></div>`).join('');
        $('#tdConfigModal').hidden = false;
    });

    $('#tdCloseConfig')?.addEventListener('click', () => $('#tdConfigModal').hidden = true);
    $('#tdCancelConfig')?.addEventListener('click', () => $('#tdConfigModal').hidden = true);

    $('#tdSaveConfig')?.addEventListener('click', async () => {
        if (!currentRoute) return;
        const inputs = $$('.td-config-input[data-sector-id]', $('#tdConfigTable'));
        const sectores = Array.from(inputs).map(inp => ({
            sector_id: Number(inp.dataset.sectorId),
            cantidad_agentes_requeridos: Number(inp.value) || 0,
        }));
        setLoading($('#tdSaveConfig'), true);
        try {
            await api('distribucion-tablero/sectores/requerimiento', { method: 'PUT', body: { ruta_id: currentRoute.id, sectores } });
            notify('Requerimiento actualizado correctamente');
            $('#tdConfigModal').hidden = true;
            const stats = (await api(`distribucion-tablero/rutas/${currentRoute.id}/estadisticas?fecha=${currentFecha}&turno=${encodeURIComponent(currentShift.nombre)}`)).datos || {};
            currentSectors = (await api(`distribucion-tablero/rutas/${currentRoute.id}/sectores`)).datos || [];
            renderRouteInfo(stats);
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdSaveConfig'), false); }
    });

    $('#tdRandomAssign')?.addEventListener('click', async () => {
        if (!currentRoute || !currentFecha || !currentShift) return notify('Cargue la ruta primero.', true);
        setLoading($('#tdRandomAssign'), true);
        try {
            sorteoData = (await api('distribucion-tablero/sorteo', {
                method: 'POST',
                body: {
                    ruta_id: currentRoute.id,
                    fecha_servicio: currentFecha,
                    turno: currentShift.nombre,
                    hora_inicio: currentShift.hora_inicio,
                    hora_fin: currentShift.hora_fin,
                },
            })).datos;

            if (sorteoData.insuficiente) {
                renderInsufficientModal(sorteoData);
                $('#tdInsufficientModal').hidden = false;
            } else {
                renderSorteoModal(sorteoData);
                $('#tdSorteoModal').hidden = false;
            }
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdRandomAssign'), false); }
    });

    function renderSorteoModal(data) {
        const summary = `
            <div class="td-sorteo-summary">
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${esc(data.ruta?.nombre || '—')}</div><div class="td-sorteo-summary-label">Ruta</div></div>
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${data.agentes_requeridos}</div><div class="td-sorteo-summary-label">Requeridos</div></div>
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${data.agentes_disponibles}</div><div class="td-sorteo-summary-label">Disponibles</div></div>
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${data.agentes_seleccionados}</div><div class="td-sorteo-summary-label">Seleccionados</div></div>
            </div>`;

        let sectorsHtml = '';
        for (const sector of data.sectores) {
            let agentsHtml = '';
            if (sector.agentes.length === 0) {
                agentsHtml = '<div class="td-sorteo-no-cover">Sector sin personal</div>';
            } else {
                agentsHtml = sector.agentes.map(a => `
                    <div class="td-sorteo-agent">
                        <div class="td-sorteo-agent-avatar">${(a.agente_nombre?.[0] || 'A')}</div>
                        <div class="td-sorteo-agent-info">
                            <div class="td-sorteo-agent-name">${esc(a.agente_nombre)}</div>
                            <div class="td-sorteo-agent-meta">${esc(a.cedula)} · Asignaciones previas: ${a.asignaciones_previas} · En esta ruta: ${a.en_esta_ruta}</div>
                        </div>
                        <span class="td-sorteo-agent-score">Puntaje: ${a.score}</span>
                    </div>
                `).join('');
            }
            sectorsHtml += `
                <div class="td-sorteo-sector">
                    <div class="td-sorteo-sector-header">
                        <span class="td-sorteo-sector-name">${esc(sector.sector_nombre)}</span>
                        <span class="td-sorteo-sector-count">${sector.agentes.length} / ${sector.cantidad_requerida} agentes</span>
                    </div>
                    ${agentsHtml}
                </div>`;
        }
        $('#tdSorteoBody').innerHTML = summary + sectorsHtml;
    }

    function renderInsufficientModal(data) {
        $('#tdInsufficientBody').innerHTML = `
            <div class="td-sorteo-no-cover" style="margin-bottom:14px">${esc(data.mensaje_personal_insuficiente)}</div>
            <div class="td-sorteo-summary">
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${data.agentes_requeridos}</div><div class="td-sorteo-summary-label">Requeridos</div></div>
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${data.agentes_disponibles}</div><div class="td-sorteo-summary-label">Disponibles</div></div>
                <div class="td-sorteo-summary-item"><div class="td-sorteo-summary-value">${data.agentes_seleccionados}</div><div class="td-sorteo-summary-label">Se pueden asignar</div></div>
            </div>
            ${data.sectores.filter(s => s.agentes.length < s.cantidad_requerida).map(s => `
                <div class="td-sorteo-sector">
                    <div class="td-sorteo-sector-header">
                        <span class="td-sorteo-sector-name">${esc(s.sector_nombre)}</span>
                        <span class="td-sorteo-sector-count">${s.agentes.length} / ${s.cantidad_requerida} agentes</span>
                    </div>
                    ${s.agentes.length === 0 ? '<div class="td-sorteo-no-cover">Sector sin personal</div>' : s.agentes.map(a => `
                        <div class="td-sorteo-agent">
                            <div class="td-sorteo-agent-avatar">${(a.agente_nombre?.[0] || 'A')}</div>
                            <div class="td-sorteo-agent-info">
                                <div class="td-sorteo-agent-name">${esc(a.agente_nombre)}</div>
                                <div class="td-sorteo-agent-meta">${esc(a.cedula)}</div>
                            </div>
                            <span class="td-sorteo-agent-score">Puntaje: ${a.score}</span>
                        </div>
                    `).join('')}
                </div>
            `).join('')}`;
    }

    $('#tdCloseSorteo')?.addEventListener('click', () => $('#tdSorteoModal').hidden = true);
    $('#tdCancelSorteo')?.addEventListener('click', () => $('#tdSorteoModal').hidden = true);
    $('#tdCloseInsufficient')?.addEventListener('click', () => $('#tdInsufficientModal').hidden = true);
    $('#tdCancelInsufficient')?.addEventListener('click', () => $('#tdInsufficientModal').hidden = true);

    $('#tdRetrySorteo')?.addEventListener('click', async () => {
        if (!currentRoute) return;
        setLoading($('#tdRetrySorteo'), true);
        try {
            sorteoData = (await api('distribucion-tablero/sorteo/reintentar', {
                method: 'POST',
                body: {
                    ruta_id: currentRoute.id,
                    fecha_servicio: currentFecha,
                    turno: currentShift.nombre,
                    hora_inicio: currentShift.hora_inicio,
                    hora_fin: currentShift.hora_fin,
                },
            })).datos;
            if (sorteoData.insuficiente) {
                renderInsufficientModal(sorteoData);
            } else {
                renderSorteoModal(sorteoData);
            }
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdRetrySorteo'), false); }
    });

    $('#tdConfirmSorteo')?.addEventListener('click', async () => {
        if (!sorteoData) return;
        setLoading($('#tdConfirmSorteo'), true);
        try {
            const asignaciones = [];
            for (const sector of sorteoData.sectores) {
                for (const agent of sector.agentes) {
                    asignaciones.push({
                        agente_id: agent.agente_id,
                        distrito_id: sorteoData.ruta.distrito_id,
                        ruta_id: sorteoData.ruta.id,
                        sector_id: sector.sector_id,
                        fecha_asignacion: currentFecha,
                        turno: currentShift.nombre,
                        hora_inicio: currentShift.hora_inicio,
                        hora_fin: currentShift.hora_fin,
                    });
                }
            }
            await api('distribucion-tablero/sorteo/confirmar', {
                method: 'POST',
                body: { sorteo_id: sorteoData.sorteo_id, asignaciones },
            });
            notify('Asignacion aleatoria confirmada correctamente');
            $('#tdSorteoModal').hidden = true;
            sorteoData = null;
            const stats = (await api(`distribucion-tablero/rutas/${currentRoute.id}/estadisticas?fecha=${currentFecha}&turno=${encodeURIComponent(currentShift.nombre)}`)).datos || {};
            renderRouteInfo(stats);
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdConfirmSorteo'), false); }
    });

    $('#tdConfirmPartial')?.addEventListener('click', async () => {
        if (!sorteoData) return;
        setLoading($('#tdConfirmPartial'), true);
        try {
            const asignaciones = [];
            for (const sector of sorteoData.sectores) {
                for (const agent of sector.agentes) {
                    asignaciones.push({
                        agente_id: agent.agente_id,
                        distrito_id: sorteoData.ruta.distrito_id,
                        ruta_id: sorteoData.ruta.id,
                        sector_id: sector.sector_id,
                        fecha_asignacion: currentFecha,
                        turno: currentShift.nombre,
                        hora_inicio: currentShift.hora_inicio,
                        hora_fin: currentShift.hora_fin,
                    });
                }
            }
            await api('distribucion-tablero/sorteo/confirmar', {
                method: 'POST',
                body: { sorteo_id: sorteoData.sorteo_id, asignaciones },
            });
            notify('Asignacion parcial confirmada correctamente');
            $('#tdInsufficientModal').hidden = true;
            sorteoData = null;
            const stats = (await api(`distribucion-tablero/rutas/${currentRoute.id}/estadisticas?fecha=${currentFecha}&turno=${encodeURIComponent(currentShift.nombre)}`)).datos || {};
            renderRouteInfo(stats);
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdConfirmPartial'), false); }
    });

    $('#tdCleanAssign')?.addEventListener('click', async () => {
        if (!currentRoute || !currentFecha || !currentShift) return notify('Cargue la ruta primero.', true);
        if (!confirm('Se eliminaran todas las asignaciones pendientes y activas de esta ruta para la fecha y turno seleccionados. Continuar?')) return;
        setLoading($('#tdCleanAssign'), true);
        try {
            const result = (await api('distribucion-tablero/limpiar', {
                method: 'POST',
                body: {
                    ruta_id: currentRoute.id,
                    fecha_servicio: currentFecha,
                    turno: currentShift.nombre,
                },
            })).datos;
            notify(`Se eliminaron ${result.eliminadas} asignaciones`);
            const stats = (await api(`distribucion-tablero/rutas/${currentRoute.id}/estadisticas?fecha=${currentFecha}&turno=${encodeURIComponent(currentShift.nombre)}`)).datos || {};
            renderRouteInfo(stats);
        } catch (e) { notify(e.message, true); }
        finally { setLoading($('#tdCleanAssign'), false); }
    });

    let searchTimeout = null;
    $('#tdPersonnelSearch')?.addEventListener('input', function() {
        clearTimeout(searchTimeout);
        const query = this.value.trim();
        if (query.length < 2) { $('#tdPersonnelResults').innerHTML = ''; return; }
        searchTimeout = setTimeout(() => searchPersonnel(query), 300);
    });

    async function searchPersonnel(query) {
        try {
            const result = (await api(`distribucion-tablero/personal-disponible?q=${encodeURIComponent(query)}`)).datos || [];
            const container = $('#tdPersonnelResults');
            if (!result.length) { container.innerHTML = '<div class="td-empty-state"><p>No se encontraron resultados</p></div>'; return; }
            container.innerHTML = result.map(p => `
                <div class="td-personnel-card" data-personnel-id="${p.id}">
                    <div class="td-personnel-avatar">${(p.nombre?.[0] || 'P')}</div>
                    <div class="td-personnel-info">
                        <div class="td-personnel-name">${esc(p.nombre)}</div>
                        <div class="td-personnel-meta">${esc(p.cedula)} · ${esc(p.cargo || '')}</div>
                    </div>
                </div>
            `).join('');
        } catch (e) { notify(e.message, true); }
    }

    $('#tdRandomAssignBottom')?.addEventListener('click', () => $('#tdRandomAssign').click());
})();
