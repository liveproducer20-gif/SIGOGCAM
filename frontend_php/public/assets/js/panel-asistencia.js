(function () {
    'use strict';
    const app = document.querySelector('.pa-app');
    if (!app) return;
    const $ = (s, r = document) => r.querySelector(s);
    const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
    const canRegister = app.dataset.canRegister === '1';
    const canEdit = app.dataset.canEdit === '1';

    const state = {
        districtId: 0, shiftId: 0, routeId: 0,
        date: new Date().toISOString().slice(0, 10),
        personnel: [], filtered: [], selected: new Set(),
        routes: [],
    };

    async function api(resource, options = {}) {
        const resp = await fetch(`/panel-asistencia/api?resource=${encodeURIComponent(resource)}`, {
            method: options.method || 'GET',
            headers: options.body ? { 'Content-Type': 'application/json' } : {},
            body: options.body ? JSON.stringify(options.body) : undefined,
        });
        const payload = await resp.json().catch(() => ({ ok: false, mensaje: 'Respuesta invalida.' }));
        if (!resp.ok || payload.ok !== true) throw new Error(payload.mensaje || payload.detail || 'Error del servidor.');
        return payload.datos;
    }

    function notify(msg, error = false) {
        const t = $('#paToast');
        t.textContent = msg;
        t.classList.toggle('is-error', error);
        t.classList.add('is-visible');
        clearTimeout(notify._t);
        notify._t = setTimeout(() => t.classList.remove('is-visible'), 4000);
    }

    function esc(v) { const d = document.createElement('div'); d.textContent = v ?? ''; return d.innerHTML; }

    async function loadRoutes() {
        const sel = $('#paRoute');
        sel.innerHTML = '<option value="">Todas las rutas</option>';
        if (!state.districtId) { state.routes = []; return; }
        try {
            state.routes = await api(`distritos/${state.districtId}/rutas`);
            state.routes.forEach(r => {
                const opt = document.createElement('option');
                opt.value = r.id;
                opt.textContent = r.nombre;
                sel.appendChild(opt);
            });
        } catch (e) { notify(e.message, true); }
    }

    async function loadPersonnel() {
        state.districtId = Number($('#paDistrict').value || 0);
        state.shiftId = Number($('#paShift').value || 0);
        state.routeId = Number($('#paRoute').value || 0);
        state.date = $('#paDate').value;
        if (!state.districtId || !state.shiftId) {
            state.personnel = []; state.filtered = []; state.selected.clear();
            $('#paEmptyBoard').hidden = false;
            $('#paAttendanceList').hidden = true;
            return;
        }
        try {
            let url = `asistencia/personal-asignado?distrito_id=${state.districtId}&turno_id=${state.shiftId}&fecha=${state.date}`;
            if (state.routeId) url += `&ruta_id=${state.routeId}`;
            state.personnel = await api(url);
            state.filtered = [...state.personnel];
            state.selected.clear();
            renderTable();
            loadStats();
        } catch (e) {
            state.personnel = []; state.filtered = []; state.selected.clear();
            notify(e.message, true);
            $('#paEmptyBoard').hidden = false;
            $('#paAttendanceList').hidden = true;
        }
    }

    async function loadStats() {
        try {
            const turno = $('#paShift').selectedOptions[0]?.textContent || '';
            let url = `asistencia/estadisticas?fecha=${state.date}`;
            if (state.districtId) url += `&distrito_id=${state.districtId}`;
            if (turno) url += `&turno=${encodeURIComponent(turno)}`;
            const stats = await api(url);
            $('#paTotal').textContent = stats.total;
            $('#paPresentes').textContent = stats.presentes;
            $('#paAtrasos').textContent = stats.atrasos;
            $('#paAusentes').textContent = stats.ausentes;
            $('#paPendientes').textContent = stats.pendientes;
            const pct = stats.porcentaje_asistencia || 0;
            $('#paCoverageBar').style.width = `${Math.min(100, pct)}%`;
            $('#paCoverageLabel').textContent = `${pct}%`;
        } catch (_) {}
    }

    function renderTable() {
        if (!state.filtered.length) {
            $('#paEmptyBoard').hidden = false;
            $('#paAttendanceList').hidden = true;
            return;
        }
        $('#paEmptyBoard').hidden = true;
        $('#paAttendanceList').hidden = false;
        const tbody = $('#paTableBody');
        tbody.innerHTML = state.filtered.map((p, i) => {
            const statusOptions = ['PENDIENTE', 'PRESENTE', 'ATRASO', 'AUSENTE', 'PERMISO', 'VACACIONES', 'INCAPACIDAD', 'FRANCO']
                .map(s => `<option value="${s}" ${p.estado_asistencia === s ? 'selected' : ''}>${s}</option>`).join('');
            const isRegistered = p.registrado;
            const rowClass = isRegistered ? 'pa-row-registered' : '';
            return `<tr class="${rowClass}" data-pid="${p.personal_id}">
                <td class="pa-th-check"><input type="checkbox" data-pid="${p.personal_id}" ${state.selected.has(p.personal_id) ? 'checked' : ''}></td>
                <td>${i + 1}</td>
                <td><div class="pa-agent-cell"><span class="pa-avatar">${esc(initials(p.nombre_completo))}</span><div><div class="pa-agent-name">${esc(p.nombre_completo)}</div></div></div></td>
                <td>${esc(p.cedula)}</td>
                <td><small>${esc(p.ruta_nombre || '')}</small><br><small style="color:#94a3b8">${esc(p.lugar_nombre || '')}</small></td>
                <td><select class="pa-status-select" data-pid="${p.personal_id}" ${canRegister || canEdit ? '' : 'disabled'}>${statusOptions}</select></td>
                <td><input type="time" class="pa-time-input" data-pid="${p.personal_id}" value="${p.hora_ingreso ? extractTime(p.hora_ingreso) : ''}" ${canRegister || canEdit ? '' : 'disabled'}></td>
                <td><input type="text" class="pa-obs-input" data-pid="${p.personal_id}" placeholder="Observacion..." value="${esc(p.observaciones || '')}" ${canRegister || canEdit ? '' : 'disabled'}></td>
            </tr>`;
        }).join('');
        updateSelectedCount();
    }

    function initials(name) {
        return String(name || '').split(/\s+/).filter(Boolean).slice(-2).map(p => p[0]).join('').toUpperCase();
    }

    function extractTime(datetimeStr) {
        if (!datetimeStr) return '';
        const match = datetimeStr.match(/(\d{2}:\d{2})/);
        return match ? match[1] : '';
    }

    function updateSelectedCount() {
        $('#paSelectedCount').textContent = state.selected.size;
        const saveBtn = $('#paSaveBtn');
        if (saveBtn) saveBtn.disabled = state.selected.size === 0;
    }

    function filterList() {
        const q = $('#paSearch').value.trim().toLowerCase();
        state.filtered = state.personnel.filter(p =>
            !q || (p.nombre_completo || '').toLowerCase().includes(q) || (p.cedula || '').includes(q)
        );
        renderTable();
    }

    async function saveAttendance() {
        if (!state.selected.size) return;
        const records = [];
        for (const pid of state.selected) {
            const row = $(`tr[data-pid="${pid}"]`);
            if (!row) continue;
            const person = state.personnel.find(p => p.personal_id === pid);
            const estado = row.querySelector('.pa-status-select')?.value || 'PENDIENTE';
            const hora = row.querySelector('.pa-time-input')?.value || '';
            const obs = row.querySelector('.pa-obs-input')?.value || '';

            if (person.asistencia_id) {
                records.push({ type: 'update', id: person.asistencia_id, data: { estado_asistencia: estado, hora_ingreso: hora || null, observaciones: obs || null } });
            } else {
                records.push({
                    type: 'register',
                    data: {
                        personal_id: pid, distrito_id: person.distrito_id, ruta_id: person.ruta_id,
                        lugar_id: person.lugar_id, fecha: state.date,
                        turno: $('#paShift').selectedOptions[0]?.textContent || '',
                        estado_asistencia: estado,
                        hora_ingreso: hora ? `${state.date}T${hora}:00` : null,
                        tipo_asignacion: person.tipo_asignacion,
                        observaciones: obs || null,
                    }
                });
            }
        }
        try {
            let registered = 0, updated = 0;
            for (const rec of records) {
                if (rec.type === 'register') {
                    await api('asistencia/registrar', { method: 'POST', body: rec.data });
                    registered++;
                } else {
                    await api(`asistencia/${rec.id}`, { method: 'PUT', body: rec.data });
                    updated++;
                }
            }
            notify(`Asistencia guardada: ${registered} registrados, ${updated} actualizados.`);
            state.selected.clear();
            await loadPersonnel();
        } catch (e) { notify(e.message, true); }
    }

    function markAllPresent() {
        state.personnel.forEach(p => state.selected.add(p.personal_id));
        $$('.pa-status-select').forEach(sel => { if (sel.value === 'PENDIENTE') sel.value = 'PRESENTE'; });
        renderTable();
    }

    $('#paDistrict')?.addEventListener('change', async () => {
        state.districtId = Number($('#paDistrict').value || 0);
        await loadRoutes();
    });
    $('#paShift')?.addEventListener('change', () => {});
    $('#paRoute')?.addEventListener('change', () => {});
    $('#paDate')?.addEventListener('change', () => {});
    $('#paLoadBtn')?.addEventListener('click', loadPersonnel);
    $('#paSearch')?.addEventListener('input', filterList);
    $('#paSaveBtn')?.addEventListener('click', saveAttendance);
    $('#paMarkAllPresent')?.addEventListener('click', markAllPresent);

    $('#paCheckAll')?.addEventListener('change', function () {
        const checked = this.checked;
        $$('input[type="checkbox"][data-pid]').forEach(cb => {
            cb.checked = checked;
            const pid = Number(cb.dataset.pid);
            if (checked) state.selected.add(pid); else state.selected.delete(pid);
        });
        updateSelectedCount();
    });

    document.addEventListener('change', function (e) {
        if (e.target.matches('input[type="checkbox"][data-pid]')) {
            const pid = Number(e.target.dataset.pid);
            if (e.target.checked) state.selected.add(pid); else state.selected.delete(pid);
            updateSelectedCount();
        }
    });

    const urlParams = new URLSearchParams(window.location.search);
    const preDistrict = urlParams.get('distrito_id');
    const preShift = urlParams.get('turno_id');
    if (preDistrict) $('#paDistrict').value = preDistrict;
    if (preShift) $('#paShift').value = preShift;
})();
