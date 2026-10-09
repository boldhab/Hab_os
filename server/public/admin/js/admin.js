/**
 * HabOS Admin Console
 * Mobile-First Client Application Script
 * Clean, robust, responsive
 */

(function () {
  'use strict';

  const state = {
    currentView: 'overview',
    stats: null,
    users: [],
    jobs: [],
    logs: [],
    config: null,
    selectedUserId: null,
    schedulerPaused: false,
  };

  async function api(endpoint, options = {}) {
    const headers = {
      'Content-Type': 'application/json',
      'X-Admin-Key': 'habos-admin-secret-2026',
      'X-Demo-Admin': 'true',
      ...(options.headers || {}),
    };

    try {
      const resp = await fetch(endpoint, { ...options, headers });
      const data = await resp.json();
      return { ok: resp.ok, status: resp.status, data };
    } catch (err) {
      return { ok: false, status: 0, data: { message: err.message } };
    }
  }

  function toast(message, type = 'info') {
    const container = document.getElementById('toast-container');
    if (!container) return;

    const el = document.createElement('div');
    el.className = `toast ${type}`;
    el.textContent = message;
    container.appendChild(el);

    setTimeout(() => {
      el.style.opacity = '0';
      setTimeout(() => el.remove(), 250);
    }, 3200);
  }

  function switchView(viewName) {
    state.currentView = viewName;
    window.location.hash = viewName;

    // Update bottom nav bar items
    document.querySelectorAll('.bottom-nav-item').forEach((btn) => {
      btn.classList.toggle('active', btn.dataset.view === viewName);
    });

    // Update view sections
    document.querySelectorAll('.view-section').forEach((sec) => {
      sec.classList.toggle('active', sec.id === `view-${viewName}`);
    });

    // Scroll to top of page smoothly on tab switch
    window.scrollTo({ top: 0, behavior: 'instant' });

    if (viewName === 'overview') renderOverview();
    if (viewName === 'users') renderUsers();
    if (viewName === 'jobs') renderJobs();
    if (viewName === 'logs') renderLogs();
    if (viewName === 'settings') populateSettings();
  }

  async function loadData() {
    const [statsRes, usersRes, jobsRes, logsRes, configRes] = await Promise.all([
      api('/api/v1/admin/stats'),
      api('/api/v1/admin/users'),
      api('/api/v1/admin/jobs'),
      api('/api/v1/admin/logs?limit=40'),
      api('/api/v1/admin/config'),
    ]);

    if (statsRes.ok && statsRes.data.data) {
      state.stats = statsRes.data.data;
      renderOverview();
    }

    if (usersRes.ok && usersRes.data.data) {
      state.users = usersRes.data.data;
      const countEl = document.getElementById('count-users');
      if (countEl) countEl.textContent = state.users.length;
      if (state.currentView === 'users') renderUsers();
    }

    if (jobsRes.ok && jobsRes.data.data) {
      state.jobs = jobsRes.data.data.tasks || [];
      const countEl = document.getElementById('count-jobs');
      if (countEl) countEl.textContent = state.jobs.length;
      if (state.currentView === 'jobs') renderJobs();
    }

    if (logsRes.ok && logsRes.data.data) {
      state.logs = logsRes.data.data;
      if (state.currentView === 'logs') renderLogs();
    }

    if (configRes.ok && configRes.data.data) {
      state.config = configRes.data.data;
      populateSettings();
    }
  }

  function renderOverview() {
    const s = state.stats;
    if (!s) return;

    // Metrics Cards
    const elUsers = document.getElementById('metric-users');
    const elUsersSub = document.getElementById('metric-users-sub');
    if (elUsers && s.users) {
      elUsers.textContent = s.users.total;
      elUsersSub.textContent = `${s.users.admins} admin • ${s.users.standard} std`;
    }

    const elDbMode = document.getElementById('metric-db-mode');
    if (elDbMode && s.system?.database) {
      elDbMode.textContent = s.system.database.mode;
    }

    const elUptime = document.getElementById('metric-uptime');
    const elMem = document.getElementById('metric-memory');
    if (elUptime && s.system) {
      elUptime.textContent = s.system.uptimeFormatted;
      elMem.textContent = `${s.system.memory?.rssMb} MB RAM`;
    }

    // Overview Scheduled Jobs Card List
    const jobsList = document.getElementById('overview-jobs-list');
    if (jobsList && state.jobs) {
      jobsList.innerHTML = state.jobs
        .slice(0, 4)
        .map((j) => {
          const isSuccess = j.lastStatus === 'SUCCESS';
          const intervalSec = Math.round(j.intervalMs / 1000);
          return `
          <div class="mobile-item-card">
            <div class="mobile-item-top">
              <div class="mobile-item-main">
                <div class="mobile-item-text">
                  <div class="mobile-item-title">${j.name}</div>
                  <div class="mobile-item-subtitle">${j.description || 'Every ' + intervalSec + 's'}</div>
                </div>
              </div>
              <span class="badge ${isSuccess ? 'badge-success' : 'badge-idle'}">
                ${j.lastStatus || 'IDLE'}
              </span>
            </div>
            <div class="mobile-item-actions" style="justify-content: flex-end;">
              <button type="button" class="btn btn-tonal btn-xs btn-run-single" data-name="${j.name}">
                Run
              </button>
            </div>
          </div>
        `;
        })
        .join('');

      jobsList.querySelectorAll('.btn-run-single').forEach((btn) => {
        btn.addEventListener('click', () => runJob(btn.dataset.name));
      });
    }

    // Overview Activity List
    const activityList = document.getElementById('activity-list-overview');
    if (activityList && state.logs) {
      activityList.innerHTML = state.logs
        .slice(0, 5)
        .map((l) => {
          const time = new Date(l.timestamp).toLocaleTimeString();
          return `
          <div class="activity-item">
            <div class="activity-desc">${escapeHtml(l.message)}</div>
            <span class="activity-time">${time}</span>
          </div>
        `;
        })
        .join('');
    }
  }

  function renderUsers() {
    const container = document.getElementById('users-cards-container');
    if (!container) return;

    const q = (document.getElementById('input-search-users')?.value || '').toLowerCase().trim();
    const role = document.getElementById('select-role-filter')?.value || 'ALL';

    const filtered = state.users.filter((u) => {
      const matchRole =
        role === 'ALL' ||
        (role === 'ADMIN' && u.role === 'ADMIN') ||
        (role === 'ACTOR_USER' && u.role !== 'ADMIN');
      const matchQ =
        !q ||
        (u.name && u.name.toLowerCase().includes(q)) ||
        u.email.toLowerCase().includes(q);
      return matchRole && matchQ;
    });

    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="card-panel" style="text-align:center; padding: 32px 16px; color:var(--text-muted);">
          No users match your criteria.
        </div>
      `;
      return;
    }

    container.innerHTML = filtered
      .map((u) => {
        const isAdmin = u.role === 'ADMIN';
        const date = u.createdAt ? new Date(u.createdAt).toLocaleDateString() : 'Active';
        const initial = (u.name || u.email || 'U').charAt(0).toUpperCase();

        return `
        <div class="mobile-item-card">
          <div class="mobile-item-top">
            <div class="mobile-item-main">
              <div class="user-avatar-circle">${initial}</div>
              <div class="mobile-item-text">
                <div class="mobile-item-title">${escapeHtml(u.name || 'User')}</div>
                <div class="mobile-item-subtitle">${escapeHtml(u.email)}</div>
              </div>
            </div>
            <span class="badge ${isAdmin ? 'badge-admin' : 'badge-user'}">
              ${u.role || 'USER'}
            </span>
          </div>

          <div class="mobile-item-meta">
            <span>TZ: ${u.timezone || 'UTC'}</span>
            <span>•</span>
            <span>Joined: ${date}</span>
          </div>

          <div class="mobile-item-actions">
            <button type="button" class="btn btn-secondary btn-xs btn-user-role" data-id="${u.id}" data-email="${escapeHtml(u.email)}" data-role="${u.role}">
              Role
            </button>
            <button type="button" class="btn btn-secondary btn-xs btn-user-pwd" data-id="${u.id}" data-email="${escapeHtml(u.email)}">
              Password
            </button>
            <button type="button" class="btn btn-danger-subtle btn-xs btn-user-del" data-id="${u.id}" data-email="${escapeHtml(u.email)}">
              Delete
            </button>
          </div>
        </div>
      `;
      })
      .join('');

    container.querySelectorAll('.btn-user-role').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.selectedUserId = btn.dataset.id;
        document.getElementById('modal-role-email').value = btn.dataset.email;
        document.getElementById('modal-role-select').value = btn.dataset.role === 'ADMIN' ? 'ADMIN' : 'ACTOR_USER';
        openModal('modal-role');
      });
    });

    container.querySelectorAll('.btn-user-pwd').forEach((btn) => {
      btn.addEventListener('click', () => {
        state.selectedUserId = btn.dataset.id;
        document.getElementById('modal-pwd-user').textContent = btn.dataset.email;
        document.getElementById('modal-pwd-result').style.display = 'none';
        openModal('modal-pwd');
      });
    });

    container.querySelectorAll('.btn-user-del').forEach((btn) => {
      btn.addEventListener('click', async () => {
        const id = btn.dataset.id;
        const email = btn.dataset.email;
        if (confirm(`Are you sure you want to delete user ${email}?`)) {
          const res = await api(`/api/v1/admin/users/${id}`, { method: 'DELETE' });
          if (res.ok) {
            toast(`User ${email} deleted`, 'success');
            loadData();
          } else {
            toast(res.data.message || 'Failed to delete user', 'error');
          }
        }
      });
    });
  }

  function renderJobs() {
    const container = document.getElementById('jobs-cards-container');
    if (!container) return;

    if (state.jobs.length === 0) {
      container.innerHTML = `
        <div class="card-panel" style="text-align:center; padding: 32px 16px; color:var(--text-muted);">
          No scheduled jobs configured.
        </div>
      `;
      return;
    }

    container.innerHTML = state.jobs
      .map((j) => {
        const sec = Math.round(j.intervalMs / 1000);
        const schedule = sec >= 3600 ? `Every ${sec / 3600}h` : `Every ${sec}s`;
        const lastRun = j.lastRun ? new Date(j.lastRun).toLocaleTimeString() : 'Never';
        const isSuccess = j.lastStatus === 'SUCCESS';

        return `
        <div class="mobile-item-card">
          <div class="mobile-item-top">
            <div class="mobile-item-main">
              <div class="mobile-item-text">
                <div class="mobile-item-title">${j.name}</div>
                <div class="mobile-item-subtitle">${j.description || 'Automated recurring task'}</div>
              </div>
            </div>
            <span class="badge ${isSuccess ? 'badge-success' : 'badge-idle'}">
              ${j.lastStatus || 'IDLE'}
            </span>
          </div>

          <div class="mobile-item-meta">
            <span>Schedule: ${schedule}</span>
            <span>•</span>
            <span>Runs: ${j.runCount || 0}</span>
            <span>•</span>
            <span>Last: ${lastRun}</span>
          </div>

          <div class="mobile-item-actions" style="justify-content: flex-end;">
            <button type="button" class="btn btn-tonal btn-sm btn-run-job" data-name="${j.name}">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                <polygon points="5 3 19 12 5 21 5 3"></polygon>
              </svg>
              Run Now
            </button>
          </div>
        </div>
      `;
      })
      .join('');

    container.querySelectorAll('.btn-run-job').forEach((btn) => {
      btn.addEventListener('click', () => runJob(btn.dataset.name));
    });
  }

  async function runJob(name) {
    toast(`Running worker "${name}"...`, 'info');
    const res = await api(`/api/v1/admin/jobs/${name}/run`, { method: 'POST' });
    if (res.ok) {
      const ms = res.data.data?.durationMs ?? 0;
      toast(`✓ Worker "${name}" completed in ${ms}ms`, 'success');
      loadData();
    } else {
      toast(`Job execution failed for "${name}"`, 'error');
    }
  }

  function renderLogs() {
    const container = document.getElementById('logs-cards-container');
    if (!container) return;

    const q = (document.getElementById('input-search-logs')?.value || '').toLowerCase().trim();
    const lvl = document.getElementById('select-log-level')?.value || 'ALL';

    const filtered = state.logs.filter((l) => {
      const matchLvl = lvl === 'ALL' || l.level === lvl;
      const matchQ =
        !q ||
        l.message.toLowerCase().includes(q) ||
        l.category.toLowerCase().includes(q);
      return matchLvl && matchQ;
    });

    if (filtered.length === 0) {
      container.innerHTML = `
        <div class="card-panel" style="text-align:center; padding: 32px 16px; color:var(--text-muted);">
          No audit logs match criteria.
        </div>
      `;
      return;
    }

    container.innerHTML = filtered
      .map((l) => {
        const time = new Date(l.timestamp).toLocaleTimeString();
        const badgeClass =
          l.level === 'SUCCESS'
            ? 'badge-success'
            : l.level === 'ERROR'
            ? 'badge-error'
            : l.level === 'WARN'
            ? 'badge-warning'
            : 'badge-user';

        return `
        <div class="mobile-item-card">
          <div class="mobile-item-top">
            <span class="badge ${badgeClass}">${l.level}</span>
            <span style="font-family:var(--font-mono); font-size:0.72rem; color:var(--text-dim);">${time}</span>
          </div>
          <div style="font-size:0.86rem; color:var(--text-primary); line-height:1.4;">
            ${escapeHtml(l.message)}
          </div>
          <div class="mobile-item-meta">
            <span>Category: ${l.category}</span>
            <span>•</span>
            <span>Actor: ${escapeHtml(l.user || 'system')}</span>
          </div>
        </div>
      `;
      })
      .join('');
  }

  function populateSettings() {
    if (!state.config) return;

    const dbInfo = document.getElementById('settings-db-info');
    if (dbInfo && state.stats?.system?.database) {
      const db = state.stats.system.database;
      dbInfo.textContent = `${db.mode} (${db.latencyMs}ms latency)`;
    }

    const flagAi = document.getElementById('flag-ai');
    const flagGh = document.getElementById('flag-github');
    const flagLc = document.getElementById('flag-leetcode');
    const flagMm = document.getElementById('flag-maintenance');

    if (flagAi) flagAi.checked = Boolean(state.config.aiAssistantEnabled);
    if (flagGh) flagGh.checked = Boolean(state.config.githubSyncEnabled);
    if (flagLc) flagLc.checked = Boolean(state.config.leetcodeSyncEnabled);
    if (flagMm) flagMm.checked = Boolean(state.config.maintenanceMode);
  }

  function openModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.add('open');
  }

  function closeModal(id) {
    const el = document.getElementById(id);
    if (el) el.classList.remove('open');
  }

  function escapeHtml(str) {
    if (!str) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;');
  }

  function setupEvents() {
    // Bottom Nav view switches
    document.querySelectorAll('.bottom-nav-item').forEach((btn) => {
      btn.addEventListener('click', () => switchView(btn.dataset.view));
    });

    // Links on dashboard
    document.getElementById('link-view-all-jobs')?.addEventListener('click', () => switchView('jobs'));
    document.getElementById('link-view-all-logs')?.addEventListener('click', () => switchView('logs'));

    // Refresh
    document.getElementById('btn-refresh')?.addEventListener('click', () => {
      loadData();
      toast('Telemetry refreshed', 'info');
    });

    // Scheduler toggle
    document.getElementById('btn-toggle-scheduler')?.addEventListener('click', () => {
      state.schedulerPaused = !state.schedulerPaused;
      const lbl = document.getElementById('lbl-scheduler-state');
      if (lbl) lbl.textContent = state.schedulerPaused ? 'Resume Engine' : 'Pause Engine';
      toast(state.schedulerPaused ? 'Scheduler paused' : 'Scheduler active', 'info');
    });

    // User filters
    document.getElementById('input-search-users')?.addEventListener('input', renderUsers);
    document.getElementById('select-role-filter')?.addEventListener('change', renderUsers);

    // Logs filters
    document.getElementById('input-search-logs')?.addEventListener('input', renderLogs);
    document.getElementById('select-log-level')?.addEventListener('change', renderLogs);

    // Save user role
    document.getElementById('btn-save-role')?.addEventListener('click', async () => {
      if (!state.selectedUserId) return;
      const role = document.getElementById('modal-role-select')?.value;
      const res = await api(`/api/v1/admin/users/${state.selectedUserId}/role`, {
        method: 'PATCH',
        body: JSON.stringify({ role }),
      });
      if (res.ok) {
        toast('Role updated successfully', 'success');
        closeModal('modal-role');
        loadData();
      } else {
        toast(res.data.message || 'Failed to update role', 'error');
      }
    });

    // Reset user password
    document.getElementById('btn-confirm-pwd')?.addEventListener('click', async () => {
      if (!state.selectedUserId) return;
      const res = await api(`/api/v1/admin/users/${state.selectedUserId}/reset-password`, {
        method: 'POST',
      });
      if (res.ok && res.data.data?.temporaryPassword) {
        document.getElementById('modal-pwd-text').textContent = res.data.data.temporaryPassword;
        document.getElementById('modal-pwd-result').style.display = 'flex';
        toast('Temporary password created', 'success');
      }
    });

    document.getElementById('btn-copy-pwd')?.addEventListener('click', () => {
      const txt = document.getElementById('modal-pwd-text')?.textContent;
      if (txt) {
        navigator.clipboard.writeText(txt);
        toast('Password copied to clipboard', 'info');
      }
    });

    // Add user
    document.getElementById('btn-add-user')?.addEventListener('click', () => {
      openModal('modal-add-user');
    });

    document.getElementById('btn-submit-add-user')?.addEventListener('click', async () => {
      const name = document.getElementById('add-user-name')?.value;
      const email = document.getElementById('add-user-email')?.value;
      const role = document.getElementById('add-user-role')?.value;
      const password = document.getElementById('add-user-pwd')?.value;

      if (!email) {
        toast('Email is required', 'error');
        return;
      }

      const res = await api('/api/v1/admin/users', {
        method: 'POST',
        body: JSON.stringify({ name, email, role, password }),
      });

      if (res.ok) {
        toast(`User ${email} created`, 'success');
        closeModal('modal-add-user');
        loadData();
      } else {
        toast(res.data.message || 'Error creating user', 'error');
      }
    });

    // Settings actions
    document.getElementById('btn-clear-cache')?.addEventListener('click', async () => {
      const res = await api('/api/v1/admin/maintenance/cache-clear', { method: 'POST' });
      if (res.ok) toast('Dashboard feed cache cleared', 'success');
    });

    document.getElementById('btn-test-db')?.addEventListener('click', async () => {
      const res = await api('/api/v1/admin/maintenance/db-ping');
      if (res.ok) toast(`Connected (${res.data.data.latencyMs}ms)`, 'success');
    });

    document.getElementById('btn-save-settings')?.addEventListener('click', async () => {
      const payload = {
        aiAssistantEnabled: document.getElementById('flag-ai')?.checked,
        githubSyncEnabled: document.getElementById('flag-github')?.checked,
        leetcodeSyncEnabled: document.getElementById('flag-leetcode')?.checked,
        maintenanceMode: document.getElementById('flag-maintenance')?.checked,
      };
      const res = await api('/api/v1/admin/config', {
        method: 'PUT',
        body: JSON.stringify(payload),
      });
      if (res.ok) toast('Configuration saved', 'success');
    });

    // Export logs
    document.getElementById('btn-export-logs')?.addEventListener('click', () => {
      const blob = new Blob([JSON.stringify(state.logs, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `habos-audit-logs-${Date.now()}.json`;
      a.click();
      URL.revokeObjectURL(url);
      toast('Logs downloaded', 'info');
    });

    document.getElementById('btn-clear-logs')?.addEventListener('click', async () => {
      if (confirm('Clear all in-memory audit logs?')) {
        const res = await api('/api/v1/admin/logs/clear', { method: 'POST' });
        if (res.ok) {
          state.logs = [];
          renderLogs();
          toast('Logs cleared', 'info');
        }
      }
    });

    // Modal close buttons and backdrops
    document.querySelectorAll('[data-close]').forEach((btn) => {
      btn.addEventListener('click', () => closeModal(btn.dataset.close));
    });

    document.querySelectorAll('.modal-backdrop').forEach((backdrop) => {
      backdrop.addEventListener('click', (e) => {
        if (e.target === backdrop) closeModal(backdrop.id);
      });
    });

    // Hash change routing
    window.addEventListener('hashchange', () => {
      const h = window.location.hash.replace('#', '');
      if (h && h !== state.currentView) switchView(h);
    });
  }

  function init() {
    setupEvents();
    const h = window.location.hash.replace('#', '');
    if (h) switchView(h);
    loadData();
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
