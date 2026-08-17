/* ============================================================
 * Configuración: interactividad de permisos y vista previa del menú.
 * Vanilla JS, sin dependencias. Todos los valores se insertan con
 * textContent (nunca innerHTML) para evitar XSS.
 * ============================================================ */

(function () {
    'use strict';

    /* ---------- Permisos: contadores, colapso, selección por grupo ---------- */

    const permisosForm = document.getElementById('permisosForm');
    const permCounter = document.getElementById('permCounter');
    const permSearch = document.getElementById('permSearch');

    function groupGrid(groupName) {
        return document.querySelector(`[data-perm-grid="${CSS.escape(groupName)}"]`);
    }

    function updateCounters() {
        if (!permisosForm) return;
        const allInputs = permisosForm.querySelectorAll('input[name="permiso_ids[]"]');
        const checked = permisosForm.querySelectorAll('input[name="permiso_ids[]"]:checked').length;
        if (permCounter) {
            permCounter.textContent = `${checked} de ${allInputs.length} permisos seleccionados`;
        }
        document.querySelectorAll('[data-perm-group]').forEach((group) => {
            const name = group.getAttribute('data-perm-group');
            const grid = groupGrid(name);
            if (!grid) return;
            const inputs = grid.querySelectorAll('input[type="checkbox"]');
            const sel = grid.querySelectorAll('input[type="checkbox"]:checked').length;
            const badge = group.querySelector('[data-group-count]');
            if (badge) badge.textContent = `${sel}/${inputs.length}`;
        });
    }

    function applyGroupAction(name, action) {
        const grid = groupGrid(name);
        if (!grid) return;
        grid.querySelectorAll('input[type="checkbox"]').forEach((cb) => {
            cb.checked = action === 'all';
        });
        updateCounters();
    }

    function filterPermissions(term) {
        const q = term.trim().toLowerCase();
        document.querySelectorAll('[data-perm-group]').forEach((group) => {
            const name = group.getAttribute('data-perm-group');
            const grid = groupGrid(name);
            if (!grid) return;
            let visibleCount = 0;
            grid.querySelectorAll('.check-row').forEach((row) => {
                const code = row.querySelector('span')?.textContent.toLowerCase() || '';
                const matches = q === '' || code.includes(q);
                row.style.display = matches ? '' : 'none';
                if (matches) visibleCount += 1;
            });
            group.style.display = visibleCount > 0 ? '' : 'none';
        });
        updateCounters();
    }

    if (permisosForm) {
        document.addEventListener('change', (event) => {
            if (event.target.matches('#permisosForm input[type="checkbox"]')) updateCounters();
        });

        document.querySelectorAll('[data-perm-action]').forEach((button) => {
            button.addEventListener('click', () => {
                const group = button.closest('[data-perm-group]');
                if (!group) return;
                applyGroupAction(group.getAttribute('data-perm-group'), button.getAttribute('data-perm-action'));
            });
        });

        document.querySelectorAll('.config-perm-toggle').forEach((button) => {
            button.addEventListener('click', () => {
                const group = button.closest('[data-perm-group]');
                if (!group) return;
                const grid = groupGrid(group.getAttribute('data-perm-group'));
                if (!grid) return;
                const isOpen = grid.classList.toggle('is-collapsed');
                button.setAttribute('aria-expanded', String(!isOpen));
                button.textContent = isOpen ? '›' : '⌄';
            });
        });

        if (permSearch) {
            permSearch.addEventListener('input', () => filterPermissions(permSearch.value));
        }

        updateCounters();
    }

    /* ---------- Menú: vista previa en vivo ---------- */

    const menuBuilder = document.getElementById('menuBuilderForm');
    const menuPreview = document.getElementById('menuPreview');

    function previewRows() {
        const rows = Array.from(document.querySelectorAll('#menuDragList [data-menu-row]'));
        const items = rows.map((row) => {
            const get = (selector) => row.querySelector(selector);
            const value = (selector) => (get(selector)?.value || '').trim();
            const checked = (selector) => Boolean(get(selector)?.checked);
            return {
                label: value('input[name$="[nombre_visual]"]'),
                icon: value('input[name$="[icono_visual]"]'),
                grupo: value('input[name$="[grupo]"]').toUpperCase(),
                badge: value('input[name$="[color_badge]"]'),
                visible: checked('input[name$="[visible]"]'),
                habilitado: checked('input[name$="[habilitado]"]'),
                mostrarBadge: checked('input[name$="[mostrar_badge]"]'),
                inicio: checked('input[name$="[pagina_inicial]"]'),
            };
        });

        const roots = [];
        let currentRoot = null;
        items.forEach((item) => {
            if (!item.grupo || item.grupo === 'PRINCIPAL') {
                currentRoot = { ...item, hijos: [] };
                roots.push(currentRoot);
            } else if (currentRoot) {
                currentRoot.hijos.push(item);
            } else {
                roots.push({ ...item, hijos: [] });
            }
        });
        return roots;
    }

    function renderPreview() {
        if (!menuPreview) return;
        menuPreview.textContent = '';
        const roots = previewRows();

        if (roots.length === 0) {
            const empty = document.createElement('p');
            empty.className = 'empty-state';
            empty.textContent = 'Sin elementos en el menú';
            menuPreview.appendChild(empty);
            return;
        }

        const list = document.createElement('ul');
        list.className = 'menu-preview-list';

        roots.forEach((root) => {
            const li = document.createElement('li');
            li.className = 'menu-preview-root' + (root.visible ? '' : ' is-hidden') + (root.habilitado ? '' : ' is-disabled');
            const line = document.createElement('div');
            line.className = 'menu-preview-line';

            const icon = document.createElement('i');
            icon.textContent = root.icon || '▫';
            line.appendChild(icon);

            const label = document.createElement('span');
            label.textContent = root.label || 'Sin etiqueta';
            line.appendChild(label);

            if (root.badge && root.mostrarBadge) {
                const dot = document.createElement('b');
                dot.className = 'menu-preview-badge';
                dot.style.background = root.badge;
                line.appendChild(dot);
            }
            if (root.inicio) {
                const tag = document.createElement('em');
                tag.className = 'menu-preview-tag';
                tag.textContent = 'Inicio';
                line.appendChild(tag);
            }
            li.appendChild(line);

            if (root.hijos.length > 0) {
                const sub = document.createElement('ul');
                sub.className = 'menu-preview-children';
                root.hijos.forEach((child) => {
                    const cli = document.createElement('li');
                    cli.className = (child.visible ? '' : ' is-hidden') + (child.habilitado ? '' : ' is-disabled');
                    const cLine = document.createElement('div');
                    cLine.className = 'menu-preview-line';
                    const cIcon = document.createElement('i');
                    cIcon.textContent = child.icon || '·';
                    cLine.appendChild(cIcon);
                    const cLabel = document.createElement('span');
                    cLabel.textContent = child.label || 'Sin etiqueta';
                    cLine.appendChild(cLabel);
                    if (child.badge && child.mostrarBadge) {
                        const dot = document.createElement('b');
                        dot.className = 'menu-preview-badge';
                        dot.style.background = child.badge;
                        cLine.appendChild(dot);
                    }
                    cli.appendChild(cLine);
                    sub.appendChild(cli);
                });
                li.appendChild(sub);
            }
            list.appendChild(li);
        });

        menuPreview.appendChild(list);
    }

    if (menuBuilder) {
        menuBuilder.addEventListener('input', renderPreview);
        menuBuilder.addEventListener('change', renderPreview);
        renderPreview();
    }

    /* ---------- Iconos: selector visual ---------- */

    const iconPicker = document.getElementById('menuIconPicker');
    let iconTarget = null;

    function syncIconPreview(row) {
        const input = row.querySelector('input[name$="[icono_visual]"]');
        const preview = row.querySelector('.menu-icon-preview');
        if (!input || !preview) return;
        preview.textContent = input.value.trim() || '▫';
    }

    function openIconPicker(input) {
        if (!iconPicker) return;
        iconTarget = input;
        const rect = input.getBoundingClientRect();
        iconPicker.hidden = false;
        iconPicker.style.left = Math.max(8, Math.min(rect.left, window.innerWidth - 320)) + 'px';
        iconPicker.style.top = (rect.bottom + 8) + 'px';
    }

    function closeIconPicker() {
        if (iconPicker) iconPicker.hidden = true;
        iconTarget = null;
    }

    if (iconPicker) {
        document.querySelectorAll('.menu-icon-preview').forEach((preview) => {
            preview.addEventListener('click', () => {
                const row = preview.closest('[data-menu-row]');
                const input = row ? row.querySelector('input[name$="[icono_visual]"]') : null;
                if (!input) return;
                if (!iconPicker.hidden && iconTarget === input) {
                    closeIconPicker();
                    return;
                }
                openIconPicker(input);
            });
        });

        document.querySelectorAll('input[name$="[icono_visual]"]').forEach((input) => {
            input.addEventListener('input', () => {
                const row = input.closest('[data-menu-row]');
                if (row) syncIconPreview(row);
            });
        });

        iconPicker.querySelectorAll('.menu-icon-option').forEach((option) => {
            option.addEventListener('click', () => {
                if (iconTarget) {
                    iconTarget.value = option.textContent;
                    const row = iconTarget.closest('[data-menu-row]');
                    if (row) syncIconPreview(row);
                    iconTarget.dispatchEvent(new Event('input', { bubbles: true }));
                }
                closeIconPicker();
            });
        });

        iconPicker.querySelector('.menu-icon-picker-close').addEventListener('click', closeIconPicker);

        document.addEventListener('click', (event) => {
            if (!iconPicker.hidden
                && !iconPicker.contains(event.target)
                && !event.target.closest('.menu-icon-preview')) {
                closeIconPicker();
            }
        });

        document.addEventListener('keydown', (event) => {
            if (event.key === 'Escape') closeIconPicker();
        });
    }
})();
