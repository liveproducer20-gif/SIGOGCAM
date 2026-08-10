(function () {
    'use strict';
    const $ = (sel, root = document) => root.querySelector(sel);
    const $$ = (sel, root = document) => Array.from(root.querySelectorAll(sel));
    if (!$('.dd-app')) return;

    function notify(msg, err = false) {
        const t = $('#ddToast'); if (!t) return;
        t.textContent = msg; t.classList.toggle('is-error', err); t.classList.add('is-visible');
        clearTimeout(notify._t); notify._t = setTimeout(() => t.classList.remove('is-visible'), 3500);
    }

    async function apiFetch(resource, opts = {}) {
        const res = await fetch(`/distribucion-dashboard/api?resource=${encodeURIComponent(resource)}`, {
            method: opts.method || 'GET',
            headers: opts.body ? {'Content-Type': 'application/json'} : {},
            body: opts.body ? JSON.stringify(opts.body) : undefined,
        });
        const data = await res.json().catch(() => ({ok: false, mensaje: 'Error de conexion'}));
        if (!res.ok || data.ok !== true) throw new Error(data.mensaje || data.detail || 'Error');
        return data.datos;
    }

    $$('.dd-card-header').forEach(header => {
        header.addEventListener('click', (e) => {
            if (e.target.closest('.dd-card-actions')) return;
            const groupKey = header.dataset.toggleGroup;
            const detail = $(`#ddDetail-${CSS.escape(groupKey)}`);
            const toggle = header.querySelector('.dd-card-toggle');
            if (!detail) return;
            const expanded = !detail.hidden;
            detail.hidden = expanded;
            toggle.setAttribute('aria-expanded', String(!expanded));
        });
    });

    $$('.dd-card-delete').forEach(btn => {
        btn.addEventListener('click', async (e) => {
            e.stopPropagation();
            if (!confirm('¿Eliminar esta distribucion y cancelar sus asignaciones?')) return;
            try {
                const info = JSON.parse(btn.dataset.deleteGroup);
                await apiFetch(`distribucion-tablero/dashboard/${info.turno_id}?fecha_distribucion=${encodeURIComponent(info.fecha)}`, {
                    method: 'DELETE',
                });
                btn.closest('.dd-card')?.remove();
                notify('Distribucion eliminada correctamente.');
                setTimeout(() => window.location.reload(), 600);
            } catch (err) { notify(err.message, true); }
        });
    });

    $$('.dd-card-pdf').forEach(btn => {
        btn.addEventListener('click', (event) => {
            event.stopPropagation();
            const section = $(`#ddPrint-${CSS.escape(btn.dataset.pdfGroup)}`);
            if (!section) return notify('No se encontró el detalle de esta distribución.', true);
            $$('.dd-print-section').forEach(item => item.classList.remove('is-printing'));
            section.classList.add('is-printing');
            const cleanup = () => {
                section.classList.remove('is-printing');
                window.removeEventListener('afterprint', cleanup);
            };
            window.addEventListener('afterprint', cleanup);
            window.print();
        });
    });

    const searchInput = $('#ddSearch');
    const filterEstado = $('#ddFilterEstado');

    function applyFilters() {
        const query = searchInput?.value?.trim().toLowerCase() || '';
        const estado = filterEstado?.value || '';
        $$('.dd-card').forEach(card => {
            const text = card.textContent.toLowerCase();
            const matchesSearch = !query || text.includes(query);
            let matchesEstado = true;
            if (estado === 'completa') matchesEstado = card.classList.contains('dd-card-complete');
            else if (estado === 'incompleta') matchesEstado = card.classList.contains('dd-card-incomplete');
            card.style.display = (matchesSearch && matchesEstado) ? '' : 'none';
        });
    }

    searchInput?.addEventListener('input', applyFilters);
    filterEstado?.addEventListener('change', applyFilters);

})();
