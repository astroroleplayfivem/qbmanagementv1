const resourceName = typeof GetParentResourceName === 'function'
    ? GetParentResourceName()
    : 'qb-management';

const state = {
    open: false,
    payload: null,
    activeTab: 'dashboard',
    selectedEmployee: null
};

const app = document.getElementById('app');
const navButtons = document.querySelectorAll('.nav-btn');
const tabEls = document.querySelectorAll('.tab');
const modalLayer = document.getElementById('modalLayer');
const modalTitle = document.getElementById('modalTitle');
const modalBody = document.getElementById('modalBody');
const modalCloseBtn = document.getElementById('modalCloseBtn');

function post(event, data = {}) {
    fetch(`https://${resourceName}/${event}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(data)
    }).catch(() => {});
}

function safeObj(v) {
    return v && typeof v === 'object' ? v : {};
}

function safeArray(v) {
    return Array.isArray(v) ? v : [];
}

function money(v) {
    return '$' + Number(v || 0).toLocaleString();
}

function setText(id, value) {
    const el = document.getElementById(id);
    if (el) el.textContent = value ?? '';
}

function setTheme(theme) {
    const t = safeObj(theme);

    document.documentElement.style.setProperty('--accent', t.accent || '#3b82f6');
    document.documentElement.style.setProperty('--accent-soft', t.accentSoft || 'rgba(59, 130, 246, 0.16)');
    document.documentElement.style.setProperty('--panel', t.panel || '#0f172a');
    document.documentElement.style.setProperty('--panel2', t.panel2 || '#111827');
    document.documentElement.style.setProperty('--text', t.text || '#f3f4f6');
    document.documentElement.style.setProperty('--muted', t.muted || '#9ca3af');
}

function openModal(title, innerHtml) {
    modalTitle.textContent = title || 'Action';
    modalBody.innerHTML = innerHtml || '';
    modalLayer.classList.remove('hidden');
}

function closeModal() {
    modalLayer.classList.add('hidden');
    modalBody.innerHTML = '';
}

function switchTab(tab) {
    state.activeTab = tab;

    navButtons.forEach(btn => {
        btn.classList.toggle('active', btn.dataset.tab === tab);
    });

    tabEls.forEach(el => {
        el.classList.toggle('active', el.id === tab);
    });

    const titleMap = {
        dashboard: 'Dashboard',
        employees: 'Employees',
        finance: 'Finance',
        billings: 'Billings',
        bonuses: 'Bonuses',
        logs: 'Logs',
        settings: 'Settings'
    };

    setText('pageTitle', titleMap[tab] || 'Management');
    render();
}

function renderDashboard() {
    const payload = safeObj(state.payload);
    const business = safeObj(payload.business);
    const stats = safeObj(payload.stats);

    document.getElementById('dashboard').innerHTML = `
        <div class="grid grid-4">
            <div class="card"><h3>Society Balance</h3><div class="stat">${money(stats.balance)}</div></div>
            <div class="card"><h3>Total Employees</h3><div class="stat">${stats.totalEmployees || 0}</div></div>
            <div class="card"><h3>Online Employees</h3><div class="stat">${stats.onlineEmployees || 0}</div></div>
            <div class="card"><h3>Recent Billings</h3><div class="stat">${stats.totalBillings || 0}</div></div>
        </div>

<div class="grid grid-2" style="margin-top:16px;">
    <div class="card">
        <h3>Quick Actions</h3>
        <div class="row">
            <button class="action-btn" data-goto="employees">Employees</button>
            <button class="action-btn" data-goto="finance">Finance</button>
            <button class="action-btn" data-goto="billings">Billings</button>
            <button class="action-btn" data-goto="bonuses">Bonuses</button>
            <button class="action-btn" id="bossStashBtn">Boss Stash</button>
            <button class="action-btn" id="wardrobeBtn">Wardrobe</button>
        </div>
    </div>
            <div class="card">
                <h3>Business Overview</h3>
                <div class="list">
                    <div class="list-item">
                        <strong>${business.label || 'Business'}</strong>
                        <div class="muted">${business.subtitle || 'Management'}</div>
                    </div>
                    <div class="list-item">
                        <strong>Employee Type</strong>
                        <div class="muted">${business.employeeLabel || 'Employees'}</div>
                    </div>
                </div>
            </div>
        </div>
    `;

    document.querySelectorAll('[data-goto]').forEach(btn => {
        btn.addEventListener('click', () => switchTab(btn.dataset.goto));
    });

    document.getElementById('bossStashBtn')?.addEventListener('click', () => {
        post('openBossStash', { job: payload.job });
    });

    document.getElementById('wardrobeBtn')?.addEventListener('click', () => {
        post('openWardrobe');
    });
}

function renderEmployees() {
    const payload = safeObj(state.payload);
    const employees = safeArray(payload.employees);

    if (!state.selectedEmployee && employees.length) {
        state.selectedEmployee = employees[0];
    }

    const selected = state.selectedEmployee;
    let notes = [];

    if (selected && selected.notes) {
        try {
            notes = typeof selected.notes === 'string'
                ? JSON.parse(selected.notes || '[]')
                : safeArray(selected.notes);
        } catch (e) {
            notes = [];
        }
    }

    document.getElementById('employees').innerHTML = `
        <div class="employee-layout">
            <div class="card">
                <h3>${payload.business?.employeeLabel || 'Employees'}</h3>
                <div class="row" style="margin-bottom:12px;">
                    <button class="action-btn" id="hireEmployeeBtn">Hire Nearest</button>
                </div>
                <div class="list">
                    ${employees.length ? employees.map(emp => `
                        <div class="list-item employee-row ${selected && selected.citizenid === emp.citizenid ? 'active' : ''}" data-cid="${emp.citizenid}">
                            <strong>${emp.name || 'Unknown'}</strong>
                            <div class="muted">Grade: ${emp.grade ?? 0} • ${emp.online ? 'Online' : 'Offline'}</div>
                            <div class="muted">Hire Date: ${emp.hiredAt || 'Unknown'}</div>
                        </div>
                    `).join('') : `<div class="list-item"><div class="muted">No employees found.</div></div>`}
                </div>
            </div>

            <div class="card">
                ${selected ? `
                    <h3>${selected.name || 'Unknown'}</h3>
                    <div class="grid grid-2">
                        <div class="list-item"><strong>Citizen ID</strong><div class="muted">${selected.citizenid || 'Unknown'}</div></div>
                        <div class="list-item"><strong>Grade</strong><div class="muted">${selected.grade ?? 0}</div></div>
                        <div class="list-item"><strong>Hire Date</strong><div class="muted">${selected.hiredAt || 'Unknown'}</div></div>
                        <div class="list-item"><strong>Hired By</strong><div class="muted">${selected.hiredBy || 'Unknown'}</div></div>
                    </div>

                    <div class="row" style="margin-top:16px;">
                        <button class="action-btn" id="setGradeBtn">Set Grade</button>
                        <button class="action-btn" id="fireBtn">Fire</button>
                        <button class="action-btn" id="bonusBtn">Give Bonus</button>
                    </div>

                    <div class="card" style="margin-top:16px; padding:0; background:none; border:none;">
                        <h3>Notes</h3>
                        <div class="list">
                            ${notes.length ? notes.slice().reverse().map(n => `
                                <div class="list-item">
                                    <strong>Note</strong>
                                    <div class="muted">${n.note || ''}</div>
                                </div>
                            `).join('') : `<div class="list-item"><div class="muted">No notes yet.</div></div>`}
                        </div>

                        <div class="form-block" style="margin-top:12px;">
                            <label class="label">Add Note</label>
                            <textarea class="textarea" id="noteText"></textarea>
                        </div>
                        <button class="action-btn" id="saveNoteBtn">Save Note</button>
                    </div>
                ` : `<div class="muted">No employee selected.</div>`}
            </div>
        </div>
    `;

    document.querySelectorAll('.employee-row').forEach(row => {
        row.addEventListener('click', () => {
            const cid = row.dataset.cid;
            state.selectedEmployee = employees.find(emp => emp.citizenid === cid) || null;
            renderEmployees();
        });
    });

    document.getElementById('hireEmployeeBtn')?.addEventListener('click', () => {
        openModal('Hire Nearest Employee', `
            <div class="form-block">
                <label class="label">Grade</label>
                <input class="input" id="hireGradeInput" type="number" min="0" value="0">
            </div>
            <div class="row">
                <button class="action-btn" id="confirmHireBtn">Hire</button>
                <button class="secondary-btn" id="cancelHireBtn">Cancel</button>
            </div>
        `);

        document.getElementById('confirmHireBtn')?.addEventListener('click', () => {
            const grade = Number(document.getElementById('hireGradeInput')?.value || 0);
            post('hireNearest', { job: payload.job, grade });
            closeModal();
            setTimeout(() => post('requestRefresh'), 250);
        });

        document.getElementById('cancelHireBtn')?.addEventListener('click', closeModal);
    });

    if (selected) {
        document.getElementById('setGradeBtn')?.addEventListener('click', () => {
            openModal(`Set Grade - ${selected.name}`, `
                <div class="form-block">
                    <label class="label">New Grade</label>
                    <input class="input" id="gradeInput" type="number" min="0" value="${selected.grade ?? 0}">
                </div>
                <div class="row">
                    <button class="action-btn" id="confirmGradeBtn">Save</button>
                    <button class="secondary-btn" id="cancelGradeBtn">Cancel</button>
                </div>
            `);

            document.getElementById('confirmGradeBtn')?.addEventListener('click', () => {
                const grade = Number(document.getElementById('gradeInput')?.value || 0);
                post('setGrade', {
                    job: payload.job,
                    citizenid: selected.citizenid,
                    grade
                });
                closeModal();
                setTimeout(() => post('requestRefresh'), 250);
            });

            document.getElementById('cancelGradeBtn')?.addEventListener('click', closeModal);
        });

        document.getElementById('fireBtn')?.addEventListener('click', () => {
            openModal(`Fire Employee - ${selected.name}`, `
                <div class="form-block">
                    <label class="label">Reason</label>
                    <textarea class="textarea" id="fireReasonInput">No reason given</textarea>
                </div>
                <div class="row">
                    <button class="action-btn" id="confirmFireBtn">Fire Employee</button>
                    <button class="secondary-btn" id="cancelFireBtn">Cancel</button>
                </div>
            `);

            document.getElementById('confirmFireBtn')?.addEventListener('click', () => {
                const reason = document.getElementById('fireReasonInput')?.value || 'No reason given';
                post('fireEmployee', {
                    job: payload.job,
                    citizenid: selected.citizenid,
                    reason
                });
                closeModal();
                setTimeout(() => post('requestRefresh'), 250);
            });

            document.getElementById('cancelFireBtn')?.addEventListener('click', closeModal);
        });

        document.getElementById('bonusBtn')?.addEventListener('click', () => {
            openModal(`Give Bonus - ${selected.name}`, `
                <div class="form-block">
                    <label class="label">Amount</label>
                    <input class="input" id="bonusAmountInput" type="number" min="1" value="1000">
                </div>
                <div class="form-block">
                    <label class="label">Reason</label>
                    <textarea class="textarea" id="bonusReasonInput">Great work</textarea>
                </div>
                <div class="row">
                    <button class="action-btn" id="confirmBonusBtn">Pay Bonus</button>
                    <button class="secondary-btn" id="cancelBonusBtn">Cancel</button>
                </div>
            `);

            document.getElementById('confirmBonusBtn')?.addEventListener('click', () => {
                const amount = Number(document.getElementById('bonusAmountInput')?.value || 0);
                const reason = document.getElementById('bonusReasonInput')?.value || 'Bonus';
                post('payBonus', {
                    job: payload.job,
                    citizenid: selected.citizenid,
                    amount,
                    reason
                });
                closeModal();
                setTimeout(() => post('requestRefresh'), 250);
            });

            document.getElementById('cancelBonusBtn')?.addEventListener('click', closeModal);
        });

        document.getElementById('saveNoteBtn')?.addEventListener('click', () => {
            const note = (document.getElementById('noteText')?.value || '').trim();
            if (!note) return;
            post('addNote', {
                job: payload.job,
                citizenid: selected.citizenid,
                note
            });
            setTimeout(() => post('requestRefresh'), 250);
        });
    }
}

function renderFinance() {
    const payload = safeObj(state.payload);
    const stats = safeObj(payload.stats);

    document.getElementById('finance').innerHTML = `
        <div class="grid grid-2">
            <div class="card">
                <h3>Society Balance</h3>
                <div class="stat">${money(stats.balance)}</div>
            </div>
            <div class="card">
                <h3>Finance Actions</h3>
                <div class="form-block">
                    <label class="label">Amount</label>
                    <input id="financeAmount" class="input" type="number" min="1" />
                </div>
                <div class="row">
                    <button class="action-btn" id="depositBtn">Deposit</button>
                    <button class="action-btn" id="withdrawBtn">Withdraw</button>
                </div>
            </div>
        </div>
    `;

    document.getElementById('depositBtn')?.addEventListener('click', () => {
        const amount = Number(document.getElementById('financeAmount')?.value || 0);
        if (amount <= 0) return;
        post('societyDeposit', { job: payload.job, amount });
        setTimeout(() => post('requestRefresh'), 250);
    });

    document.getElementById('withdrawBtn')?.addEventListener('click', () => {
        const amount = Number(document.getElementById('financeAmount')?.value || 0);
        if (amount <= 0) return;
        post('societyWithdraw', { job: payload.job, amount });
        setTimeout(() => post('requestRefresh'), 250);
    });
}

function renderBillings() {
    const payload = safeObj(state.payload);
    const billings = safeArray(payload.billings);

    document.getElementById('billings').innerHTML = `
        <div class="card">
            <h3>Recent Billings</h3>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Employee</th>
                            <th>Customer</th>
                            <th>Amount</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${billings.length ? billings.map(row => `
                            <tr>
                                <td>${row.employee_name || 'Unknown'}</td>
                                <td>${row.customer_name || 'Unknown'}</td>
                                <td>${money(row.amount)}</td>
                                <td>${row.created_at || 'Unknown'}</td>
                            </tr>
                        `).join('') : `<tr><td colspan="4">No billing records found.</td></tr>`}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

function renderBonuses() {
    const payload = safeObj(state.payload);
    const bonuses = safeArray(payload.bonuses);

    document.getElementById('bonuses').innerHTML = `
        <div class="card">
            <h3>Bonus History</h3>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Employee</th>
                            <th>Amount</th>
                            <th>Reason</th>
                            <th>Paid By</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${bonuses.length ? bonuses.map(row => `
                            <tr>
                                <td>${row.employee_name || 'Unknown'}</td>
                                <td>${money(row.amount)}</td>
                                <td>${row.reason || 'Bonus'}</td>
                                <td>${row.paid_by || 'Unknown'}</td>
                                <td>${row.paid_at || 'Unknown'}</td>
                            </tr>
                        `).join('') : `<tr><td colspan="5">No bonuses yet.</td></tr>`}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

function renderLogs() {
    const payload = safeObj(state.payload);
    const logs = safeArray(payload.logs);

    document.getElementById('logs').innerHTML = `
        <div class="card">
            <h3>Management Logs</h3>
            <div class="table-wrap">
                <table class="table">
                    <thead>
                        <tr>
                            <th>Action</th>
                            <th>Actor</th>
                            <th>Target</th>
                            <th>Date</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${logs.length ? logs.map(row => `
                            <tr>
                                <td>${row.action || 'Unknown'}</td>
                                <td>${row.actor_name || 'Unknown'}</td>
                                <td>${row.target_name || row.target_citizenid || 'N/A'}</td>
                                <td>${row.created_at || 'Unknown'}</td>
                            </tr>
                        `).join('') : `<tr><td colspan="4">No logs yet.</td></tr>`}
                    </tbody>
                </table>
            </div>
        </div>
    `;
}

function renderSettings() {
    const payload = safeObj(state.payload);
    const business = safeObj(payload.business);
    const theme = safeObj(payload.theme);

    document.getElementById('settings').innerHTML = `
        <div class="card">
            <h3>Business Settings</h3>
            <div class="list">
                <div class="list-item">
                    <strong>Theme</strong>
                    <div class="muted">${theme.label || 'Default'}</div>
                </div>
                <div class="list-item">
                    <strong>Business</strong>
                    <div class="muted">${business.label || 'Business'} • ${business.subtitle || 'Management'}</div>
                </div>
            </div>
        </div>
    `;
}

function render() {
    const payload = safeObj(state.payload);
    const business = safeObj(payload.business);
    const theme = safeObj(payload.theme);
    const stats = safeObj(payload.stats);

    setTheme(theme);

    setText('bizName', business.label || 'Business');
    setText('bizSub', business.subtitle || 'Management');
    setText('brandIcon', theme.icon || '??');
    setText('societyBalance', money(stats.balance));
    setText('pageSubtitle', business.subtitle || 'Business management overview');

    renderDashboard();
    renderEmployees();
    renderFinance();
    renderBillings();
    renderBonuses();
    renderLogs();
    renderSettings();
}

document.getElementById('closeBtn')?.addEventListener('click', () => post('close'));
modalCloseBtn?.addEventListener('click', closeModal);
modalLayer?.addEventListener('click', (e) => {
    if (e.target === modalLayer) closeModal();
});

navButtons.forEach(btn => {
    btn.addEventListener('click', () => switchTab(btn.dataset.tab));
});

window.addEventListener('message', (event) => {
    const data = event.data || {};

    if (data.action === 'open') {
        state.open = true;
        state.payload = safeObj(data.payload);
        state.selectedEmployee = safeArray(state.payload.employees)[0] || null;
        app.classList.remove('hidden');
        closeModal();
        switchTab('dashboard');
    }

    if (data.action === 'hydrate') {
        const newPayload = safeObj(data.payload);
        const currentCid = state.selectedEmployee?.citizenid || null;

        state.payload = newPayload;
        const employees = safeArray(newPayload.employees);
        state.selectedEmployee = employees.find(emp => emp.citizenid === currentCid) || employees[0] || null;
        closeModal();
        render();
    }

    if (data.action === 'close' || data.action === 'forceClose') {
        state.open = false;
        state.payload = null;
        state.selectedEmployee = null;
        closeModal();
        app.classList.add('hidden');
    }
});

document.addEventListener('keyup', (e) => {
    if (e.key === 'Escape' && state.open) {
        if (!modalLayer.classList.contains('hidden')) {
            closeModal();
        } else {
            post('close');
        }
    }
});
