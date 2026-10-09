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

  init();
})();
