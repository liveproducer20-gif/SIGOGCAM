(function () {
    const dragList = document.getElementById('menuDragList');
    if (dragList) {
        let dragged = null;
        dragList.querySelectorAll('.drag-row').forEach((row) => {
            row.addEventListener('dragstart', () => {
                dragged = row;
                row.classList.add('is-dragging');
            });
            row.addEventListener('dragend', () => {
                row.classList.remove('is-dragging');
                dragged = null;
                renumberRows(dragList);
            });
            row.addEventListener('dragover', (event) => {
                event.preventDefault();
                const target = event.currentTarget;
                if (!dragged || dragged === target) return;
                const rect = target.getBoundingClientRect();
                const before = event.clientY < rect.top + rect.height / 2;
                dragList.insertBefore(dragged, before ? target : target.nextSibling);
            });
        });
    }

    document.querySelectorAll('[data-edit-target]').forEach((button) => {
        button.addEventListener('click', () => {
            const target = document.querySelector(button.dataset.editTarget);
            if (!target) return;
            const payload = JSON.parse(button.dataset.payload || '{}');
            Object.keys(payload).forEach((key) => {
                const field = target.querySelector(`[name="${key}"]`);
                if (!field) return;
                if (field.type === 'checkbox') {
                    field.checked = Boolean(payload[key]);
                } else {
                    field.value = payload[key] ?? '';
                }
            });
            target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        });
    });

    function renumberRows(list) {
        list.querySelectorAll('.drag-row').forEach((row, index) => {
            const input = row.querySelector('.order-input');
            if (input) input.value = String(index + 1);
        });
    }

    const sidebar = document.getElementById('sigoSidebar');
    const sigoApp = document.getElementById('sigoApp');
    const menuButton = document.getElementById('sigoMenuButton');
    const overlay = document.getElementById('sigoOverlay');

    document.querySelectorAll('[data-nav-group] > button').forEach((button) => {
        button.addEventListener('click', () => {
            const group = button.closest('[data-nav-group]');
            const open = !group.classList.contains('is-open');
            group.classList.toggle('is-open', open);
            button.setAttribute('aria-expanded', String(open));
        });
    });

    if (menuButton && sidebar && sigoApp) {
        menuButton.addEventListener('click', () => {
            if (window.matchMedia('(max-width: 900px)').matches) {
                sidebar.classList.toggle('mobile-open');
                overlay?.classList.toggle('is-visible', sidebar.classList.contains('mobile-open'));
                return;
            }
            sidebar.classList.toggle('is-collapsed');
            sigoApp.classList.toggle('sidebar-collapsed');
        });
        overlay?.addEventListener('click', () => {
            sidebar.classList.remove('mobile-open');
            overlay.classList.remove('is-visible');
        });
    }

    document.querySelectorAll('.inline-form').forEach((form) => {
        const danger = form.querySelector('button.danger');
        if (!danger) return;
        form.addEventListener('submit', (event) => {
            if (!window.confirm('Esta acción cambiará el estado del registro. ¿Desea continuar?')) {
                event.preventDefault();
                event.stopImmediatePropagation();
            }
        });
    });

    document.querySelectorAll('form[method="post"]').forEach((form) => {
        form.addEventListener('submit', () => {
            const submit = form.querySelector('button[type="submit"]');
            if (!submit || submit.disabled) return;
            submit.dataset.originalText = submit.textContent;
            submit.textContent = 'Procesando…';
            submit.disabled = true;
        });
    });

    document.querySelectorAll('.table-card table, .table-wrap table').forEach((table, tableIndex) => {
        if (table.dataset.enhanced === 'true') return;
        table.dataset.enhanced = 'true';
        const body = table.tBodies[0];
        if (!body) return;
        const rows = Array.from(body.rows);
        if (!rows.length) {
            const columns = Math.max(1, table.tHead?.rows[0]?.cells.length || 1);
            body.innerHTML = `<tr><td colspan="${columns}" class="empty-state">No existen registros para mostrar.</td></tr>`;
            return;
        }
        const container = table.closest('.table-card, .table-wrap');
        const controls = document.createElement('div');
        controls.className = 'table-controls';
        controls.innerHTML = `<label>Mostrar <select aria-label="Cantidad de registros"><option>10</option><option>25</option><option>50</option></select></label><label class="table-search">Buscar <input type="search" aria-label="Buscar en tabla" placeholder="Escriba para filtrar…"></label><span class="table-counter"></span><span class="table-pagination"><button type="button" aria-label="Página anterior">‹</button><button type="button" aria-label="Página siguiente">›</button></span>`;
        container.insertBefore(controls, table);
        if (table.closest('.admin-workspace')) {
            const exports = document.createElement('span');
            exports.className = 'table-exports';
            exports.innerHTML = '<button type="button" data-export="csv">CSV</button><button type="button" data-export="xls">Excel</button><button type="button" data-export="print">PDF / Imprimir</button>';
            controls.appendChild(exports);
            exports.addEventListener('click', (event) => {
                const button = event.target.closest('[data-export]');
                if (!button) return;
                if (button.dataset.export === 'print') {
                    window.print();
                    return;
                }
                const separator = button.dataset.export === 'xls' ? '\t' : ',';
                const extension = button.dataset.export === 'xls' ? 'xls' : 'csv';
                const escapeCell = (value) => {
                    const clean = value.replace(/\s+/g, ' ').trim();
                    return separator === ',' ? `"${clean.replace(/"/g, '""')}"` : clean.replace(/\t/g, ' ');
                };
                const lines = [];
                if (table.tHead) lines.push(Array.from(table.tHead.rows[0].cells).slice(0, -1).map((cell) => escapeCell(cell.textContent)).join(separator));
                rows.forEach((row) => lines.push(Array.from(row.cells).slice(0, -1).map((cell) => escapeCell(cell.textContent)).join(separator)));
                const blob = new Blob(['\ufeff' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8' });
                const link = document.createElement('a');
                link.href = URL.createObjectURL(blob);
                link.download = `sigo-administracion-${new Date().toISOString().slice(0, 10)}.${extension}`;
                link.click();
                URL.revokeObjectURL(link.href);
            });
        }
        const search = controls.querySelector('input');
        const amount = controls.querySelector('select');
        const counter = controls.querySelector('.table-counter');
        const [previous, next] = controls.querySelectorAll('.table-pagination button');
        let page = 0;
        const render = () => {
            const term = search.value.trim().toLowerCase();
            const filtered = rows.filter((row) => row.textContent.toLowerCase().includes(term));
            const size = Number(amount.value);
            const pages = Math.max(1, Math.ceil(filtered.length / size));
            page = Math.min(page, pages - 1);
            const start = page * size;
            rows.forEach((row) => { row.hidden = true; });
            filtered.slice(start, start + size).forEach((row) => { row.hidden = false; });
            counter.textContent = filtered.length ? `${start + 1}–${Math.min(start + size, filtered.length)} de ${filtered.length}` : '0 registros';
            previous.disabled = page === 0;
            next.disabled = page >= pages - 1;
        };
        search.addEventListener('input', () => { page = 0; render(); });
        amount.addEventListener('change', () => { page = 0; render(); });
        previous.addEventListener('click', () => { page = Math.max(0, page - 1); render(); });
        next.addEventListener('click', () => { page += 1; render(); });
        render();
    });

    document.addEventListener('keydown', (event) => {
        if (event.key !== 'Escape') return;
        document.querySelectorAll('.geo-modal:not([hidden]) [data-close-wizard]').forEach((button) => button.click());
        sidebar?.classList.remove('mobile-open');
        overlay?.classList.remove('is-visible');
    });
})();
