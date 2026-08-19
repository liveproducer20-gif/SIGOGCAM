(function () {
    'use strict';
    const app = document.querySelector('.pa-app');
    if (!app) return;
    const $ = (s, r = document) => r.querySelector(s);
    const $$ = (s, r = document) => Array.from(r.querySelectorAll(s));
    const canRegister = app.dataset.canRegister === '1';
    const canEdit = app.dataset.canEdit === '1';
    const canExport = app.dataset.canExport === '1';

    const STATUS_META = {
        PRESENTE: { label: 'P', title: 'Presente' },
        ATRASO: { label: 'A', title: 'Atraso' },
        AUSENTE: { label: 'X', title: 'Ausente' },
        PERMISO: { label: 'M', title: 'Permiso' },
        VACACIONES: { label: 'V', title: 'Vacaciones' },
        INCAPACIDAD: { label: 'I', title: 'Incapacidad' },
        FRANCO: { label: 'F', title: 'Franco' },
    };
    const QUICK_STATUSES = ['PRESENTE', 'ATRASO', 'AUSENTE'];

    const state = {
        districtId: 0, shiftId: 0, routeId: 0,
        date: new Date().toISOString().slice(0, 10),
        personnel: [], filtered: [], selected: new Set(), routes: [],
        currentStatuses: {},
    };

    const histState = { page: 1, total: 0, totalPages: 1 };

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

    function extractTime(v) { if (!v) return ''; const m = String(v).match(/(\d{2}:\d{2})/); return m ? m[1] : ''; }
    function initials(name) { return String(name || '').split(/\s+/).filter(Boolean).slice(-2).map(p => p[0]).join('').toUpperCase(); }

    // ── Tab switching ──
    $$('.pa-tab').forEach(tab => {
        tab.addEventListener('click', () => {
            $$('.pa-tab').forEach(t => { t.classList.remove('is-active'); t.setAttribute('aria-selected', 'false'); });
            $$('.pa-tab-panel').forEach(p => { p.hidden = true; });
            tab.classList.add('is-active');
            tab.setAttribute('aria-selected', 'true');
            const panel = $(`#tab-${tab.dataset.tab}`);
            if (panel) panel.hidden = false;
        });
    });

    // ── Routes ──
    async function loadRoutes() {
        const sel = $('#paRoute');
        sel.innerHTML = '<option value="">Todas las rutas</option>';
        if (!state.districtId) { state.routes = []; return; }
        try {
            state.routes = await api(`distritos/${state.districtId}/rutas`);
            state.routes.forEach(r => {
                const opt = document.createElement('option');
                opt.value = r.id; opt.textContent = r.nombre;
                sel.appendChild(opt);
            });
        } catch (e) { notify(e.message, true); }
    }

    // ── Load personnel ──
    async function loadPersonnel() {
        state.districtId = Number($('#paDistrict').value || 0);
        state.shiftId = Number($('#paShift').value || 0);
        state.routeId = Number($('#paRoute').value || 0);
        state.date = $('#paDate').value;
        if (!state.districtId || !state.shiftId) {
            state.personnel = []; state.filtered = []; state.selected.clear(); state.currentStatuses = {};
            $('#paEmptyBoard').hidden = false; $('#paAttendanceList').hidden = true; return;
        }
        try {
            let url = `asistencia/personal-asignado?distrito_id=${state.districtId}&turno_id=${state.shiftId}&fecha=${state.date}`;
            if (state.routeId) url += `&ruta_id=${state.routeId}`;
            state.personnel = await api(url);
            state.filtered = [...state.personnel];
            state.selected.clear();
            state.currentStatuses = {};
            state.personnel.forEach(p => {
                state.currentStatuses[p.personal_id] = p.estado_asistencia || 'PENDIENTE';
            });
            renderTable(); loadStats();
        } catch (e) {
            state.personnel = []; state.filtered = []; state.selected.clear(); state.currentStatuses = {};
            notify(e.message, true); $('#paEmptyBoard').hidden = false; $('#paAttendanceList').hidden = true;
        }
    }

    // ── Stats ──
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
            $('#paNovedades').textContent = stats.novedades || 0;
            const pct = stats.porcentaje_asistencia || 0;
            $('#paCoverageBar').style.width = `${Math.min(100, pct)}%`;
            $('#paCoverageLabel').textContent = `${pct}%`;
        } catch (_) {}
    }

    function updateStatsFromLocal() {
        const counts = { PRESENTE: 0, ATRASO: 0, AUSENTE: 0, PENDIENTE: 0, PERMISO: 0, VACACIONES: 0, INCAPACIDAD: 0, FRANCO: 0 };
        state.personnel.forEach(p => { counts[state.currentStatuses[p.personal_id] || 'PENDIENTE']++; });
        const total = state.personnel.length;
        const presentes = counts.PRENTE + counts.PRESENTE;
        const atrasos = counts.ATRASO;
        const ausentes = counts.AUSENTE;
        const pendientes = counts.PENDIENTE;
        const novedades = counts.PERMISO + counts.VACACIONES + counts.INCAPACIDAD + counts.FRANCO;
        $('#paTotal').textContent = total;
        $('#paPresentes').textContent = counts.PRESENTE;
        $('#paAtrasos').textContent = atrasos;
        $('#paAusentes').textContent = ausentes;
        $('#paPendientes').textContent = pendientes;
        $('#paNovedades').textContent = novedades;
        const pct = total ? Math.round(counts.PRESENTE / total * 100) : 0;
        $('#paCoverageBar').style.width = `${pct}%`;
        $('#paCoverageLabel').textContent = `${pct}%`;
    }

    // ── Render table ──
    function renderTable() {
        if (!state.filtered.length) {
            $('#paEmptyBoard').hidden = false; $('#paAttendanceList').hidden = true; return;
        }
        $('#paEmptyBoard').hidden = true; $('#paAttendanceList').hidden = false;
        const tbody = $('#paTableBody');
        const editable = canRegister || canEdit;
        tbody.innerHTML = state.filtered.map((p, i) => {
            const status = state.currentStatuses[p.personal_id] || 'PENDIENTE';
            const statusBtns = Object.entries(STATUS_META).map(([key, meta]) => {
                const isActive = status === key;
                const isQuick = QUICK_STATUSES.includes(key);
                const cls = isActive ? 'pa-status-btn is-active' : 'pa-status-btn';
                const title = isQuick ? meta.title : meta.title;
                return `<button type="button" class="${cls}" data-pid="${p.personal_id}" data-status="${key}" title="${title}" ${editable ? '' : 'disabled'}>${meta.label}</button>`;
            }).join('');

            return `<tr class="${p.registrado ? 'pa-row-registered' : ''}" data-pid="${p.personal_id}">
                <td class="pa-th-check"><input type="checkbox" data-pid="${p.personal_id}" ${state.selected.has(p.personal_id) ? 'checked' : ''}></td>
                <td style="color:#94a3b8;font-size:.75rem">${i + 1}</td>
                <td><div class="pa-agent-cell"><span class="pa-avatar">${esc(initials(p.nombre_completo))}</span><div class="pa-agent-name">${esc(p.nombre_completo)}</div></div></td>
                <td style="color:#64748b;font-size:.78rem">${esc(p.cedula)}</td>
                <td><small style="color:#334155">${esc(p.ruta_nombre || '')}</small><br><small style="color:#94a3b8">${esc(p.lugar_nombre || '')}</small></td>
                <td><div class="pa-status-btns">${statusBtns}</div></td>
                <td><input type="time" class="pa-time-input" data-pid="${p.personal_id}" value="${extractTime(p.hora_ingreso)}" ${editable ? '' : 'disabled'}></td>
                <td><input type="text" class="pa-obs-input" data-pid="${p.personal_id}" placeholder="..." value="${esc(p.observaciones || '')}" ${editable ? '' : 'disabled'}></td>
            </tr>`;
        }).join('');
        updateSelectedCount();
    }

    function updateSelectedCount() {
        const count = state.selected.size;
        $('#paSelectedCount').textContent = `${count} seleccionado${count !== 1 ? 's' : ''}`;
        const saveBtn = $('#paSaveBtn');
        if (saveBtn) saveBtn.disabled = count === 0;
    }

    function filterList() {
        const q = ($('#paSearch')?.value || '').trim().toLowerCase();
        state.filtered = state.personnel.filter(p =>
            !q || (p.nombre_completo || '').toLowerCase().includes(q) || (p.cedula || '').includes(q)
        );
        renderTable();
    }

    // ── Quick status buttons ──
    function handleStatusClick(e) {
        const btn = e.target.closest('.pa-status-btn');
        if (!btn || btn.disabled) return;
        const pid = Number(btn.dataset.pid);
        const status = btn.dataset.status;
        state.currentStatuses[pid] = status;
        // Update all buttons in this row
        const row = btn.closest('tr');
        if (row) {
            row.querySelectorAll('.pa-status-btn').forEach(b => {
                b.classList.toggle('is-active', b.dataset.status === status);
            });
        }
        state.selected.add(pid);
        updateSelectedCount();
        updateStatsFromLocal();
    }

    // ── Save attendance ──
    async function saveAttendance() {
        if (!state.selected.size) return;
        const records = [];
        for (const pid of state.selected) {
            const row = $(`tr[data-pid="${pid}"]`);
            if (!row) continue;
            const person = state.personnel.find(p => p.personal_id === pid);
            const estado = state.currentStatuses[pid] || 'PENDIENTE';
            const hora = row.querySelector('.pa-time-input')?.value || '';
            const obs = row.querySelector('.pa-obs-input')?.value || '';
            if (person.asistencia_id) {
                records.push({ type: 'update', id: person.asistencia_id, data: { estado_asistencia: estado, hora_ingreso: hora ? `${state.date}T${hora}:00` : null, observaciones: obs || null } });
            } else {
                records.push({
                    type: 'register',
                    data: {
                        personal_id: pid, distrito_id: person.distrito_id, ruta_id: person.ruta_id,
                        lugar_id: person.lugar_id, fecha: state.date,
                        turno: $('#paShift').selectedOptions[0]?.textContent || '',
                        estado_asistencia: estado,
                        hora_ingreso: hora ? `${state.date}T${hora}:00` : null,
                        tipo_asignacion: person.tipo_asignacion, observaciones: obs || null,
                    }
                });
            }
        }
        try {
            let registered = 0, updated = 0;
            for (const rec of records) {
                if (rec.type === 'register') { await api('asistencia/registrar', { method: 'POST', body: rec.data }); registered++; }
                else { await api(`asistencia/${rec.id}`, { method: 'PUT', body: rec.data }); updated++; }
            }
            notify(`Guardado: ${registered} registrados, ${updated} actualizados.`);
            state.selected.clear();
            await loadPersonnel();
        } catch (e) { notify(e.message, true); }
    }

    // ── Bulk actions ──
    function markAll(status) {
        state.personnel.forEach(p => {
            state.currentStatuses[p.personal_id] = status;
            state.selected.add(p.personal_id);
        });
        renderTable(); updateStatsFromLocal();
    }

    // ── Export CSV ──
    function exportCSV() {
        const rows = [['#', 'Agente', 'Cedula', 'Ruta', 'Lugar', 'Estado', 'Hora llegada', 'Observaciones']];
        state.filtered.forEach((p, i) => {
            rows.push([
                i + 1, p.nombre_completo, p.cedula,
                p.ruta_nombre || '', p.lugar_nombre || '',
                state.currentStatuses[p.personal_id] || 'PENDIENTE',
                extractTime(p.hora_ingreso), p.observaciones || ''
            ]);
        });
        const csv = rows.map(r => r.map(c => `"${String(c).replace(/"/g, '""')}"`).join(',')).join('\n');
        const blob = new Blob(['\ufeff' + csv], { type: 'text/csv;charset=utf-8;' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url; a.download = `asistencia_${state.date}.csv`; a.click();
        URL.revokeObjectURL(url);
        notify('Archivo CSV exportado correctamente.');
    }

    // ── History ──
    async function loadHistory() {
        const district = $('#paHistDistrict')?.value || '';
        const status = $('#paHistStatus')?.value || '';
        const desde = $('#paHistFrom')?.value || '';
        const hasta = $('#paHistTo')?.value || '';
        try {
            let url = `asistencia/lista?page=${histState.page}&limit=20`;
            if (district) url += `&distrito_id=${district}`;
            if (status) url += `&estado_asistencia=${encodeURIComponent(status)}`;
            if (desde) url += `&fecha_desde=${desde}`;
            if (hasta) url += `&fecha_hasta=${hasta}`;
            const data = await api(url);
            const records = data.records || [];
            histState.total = data.total || 0;
            histState.totalPages = data.total_pages || 1;
            if (!records.length) {
                $('#paHistEmpty').hidden = false; $('#paHistoryList').hidden = true; return;
            }
            $('#paHistEmpty').hidden = true; $('#paHistoryList').hidden = false;
            const tbody = $('#paHistBody');
            tbody.innerHTML = records.map(r => {
                const statusClass = getStatusBadgeClass(r.estado_asistencia);
                return `<tr>
                    <td>${esc(r.fecha)}</td>
                    <td>${esc(r.turno)}</td>
                    <td><div class="pa-agent-cell"><span class="pa-avatar" style="width:26px;height:26px;font-size:.6rem">${esc(initials(r.nombre_completo))}</span><span class="pa-agent-name" style="font-size:.8rem">${esc(r.nombre_completo)}</span></div></td>
                    <td style="font-size:.78rem">${esc(r.distrito || '—')}</td>
                    <td style="font-size:.78rem">${esc(r.ruta || '—')}</td>
                    <td><span class="pa-status-badge ${statusClass}">${esc(r.estado_asistencia)}</span></td>
                    <td style="font-size:.78rem">${esc(extractTime(r.hora_ingreso) || '—')}</td>
                    <td style="font-size:.78rem;max-width:150px;overflow:hidden;text-overflow:ellipsis">${esc(r.observaciones || '—')}</td>
                </tr>`;
            }).join('');
            renderPagination();
        } catch (e) { notify(e.message, true); }
    }

    function getStatusBadgeClass(status) {
        const s = (status || '').toUpperCase();
        if (s === 'PRESENTE') return 'pa-sb-presente';
        if (s === 'ATRASO') return 'pa-sb-atraso';
        if (s === 'AUSENTE') return 'pa-sb-ausente';
        if (s === 'PENDIENTE') return 'pa-sb-pendiente';
        return 'pa-sb-novedad';
    }

    function renderPagination() {
        const container = $('#paHistPagination');
        if (!container) return;
        if (histState.totalPages <= 1) { container.innerHTML = ''; return; }
        let html = '';
        html += `<button class="pa-page-btn" ${histState.page <= 1 ? 'disabled' : ''} data-page="${histState.page - 1}">&laquo;</button>`;
        for (let i = 1; i <= Math.min(histState.totalPages, 7); i++) {
            html += `<button class="pa-page-btn ${i === histState.page ? 'is-active' : ''}" data-page="${i}">${i}</button>`;
        }
        html += `<button class="pa-page-btn" ${histState.page >= histState.totalPages ? 'disabled' : ''} data-page="${histState.page + 1}">&raquo;</button>`;
        container.innerHTML = html;
    }

    // ── Event listeners ──
    $('#paDistrict')?.addEventListener('change', async () => { state.districtId = Number($('#paDistrict').value || 0); await loadRoutes(); });
    $('#paLoadBtn')?.addEventListener('click', loadPersonnel);
    $('#paSearch')?.addEventListener('input', filterList);
    $('#paSaveBtn')?.addEventListener('click', saveAttendance);
    $('#paMarkAllPresent')?.addEventListener('click', () => markAll('PRESENTE'));
    $('#paMarkAllAbsent')?.addEventListener('click', () => markAll('AUSENTE'));
    $('#paExportBtn')?.addEventListener('click', exportCSV);

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

    // Quick status buttons (delegated)
    document.addEventListener('click', handleStatusClick);

    // History events
    $('#paHistLoadBtn')?.addEventListener('click', () => { histState.page = 1; loadHistory(); });
    document.addEventListener('click', function (e) {
        const pageBtn = e.target.closest('.pa-page-btn');
        if (pageBtn && !pageBtn.disabled) {
            histState.page = Number(pageBtn.dataset.page);
            loadHistory();
        }
    });

    // URL pre-selection
    const urlParams = new URLSearchParams(window.location.search);
    const preDistrict = urlParams.get('distrito_id');
    const preShift = urlParams.get('turno_id');
    if (preDistrict) $('#paDistrict').value = preDistrict;
    if (preShift) $('#paShift').value = preShift;
})();
