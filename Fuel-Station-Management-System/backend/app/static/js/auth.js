/**
 * auth.js — FuelSys Pro Role Guard
 * Include on every protected page: <script src="/static/js/auth.js"></script>
 * Place BEFORE any other page scripts.
 */

(function () {
  'use strict';

  // ── Page key map: match the `data-page` attr on <body> to PAGE_ACCESS keys ──
  const PAGE_KEYS = {
    'dashboard':  'dashboard',
    'sales':      'sales',
    'inventory':  'inventory',
    'tank':       'tank',
    'pumps':      'pumps',
    'staff':      'staff',
    'shifts':     'shifts',
    'lubricants': 'lubricants',
    'reports':    'reports',
    'suppliers':  'suppliers',
    'expenses':   'expenses',
    'settings':   'settings',
  };

  // ── Sidebar nav item → page key mapping via data-page on each <a> ──
  // Each sidebar <a> should have:  data-page="sales"  (matching PAGE_KEYS)

  let currentUser = null;

  // ─────────────────────────────────────────────
  //  INIT — runs on every page load
  // ─────────────────────────────────────────────

  async function init() {
    try {
      const res = await fetch('/auth/me', { credentials: 'include' });

      if (res.status === 401) {
        redirectToLogin();
        return;
      }

      const data = await res.json();

      if (!data.authenticated) {
        redirectToLogin();
        return;
      }

      currentUser = data;

      // Populate user info in sidebar
      populateUserInfo(data);

      // Apply role rules to sidebar nav
      applyNavAccess(data.page_access);

      // Check if current page is allowed
      checkCurrentPage(data.page_access);

    } catch (err) {
      console.error('Auth check failed:', err);
      redirectToLogin();
    }
  }

  // ─────────────────────────────────────────────
  //  POPULATE USER INFO IN SIDEBAR
  // ─────────────────────────────────────────────

  function populateUserInfo(user) {
    const nameEl   = document.getElementById('auth-user-name');
    const roleEl   = document.getElementById('auth-user-role');
    const imageEl  = document.getElementById('auth-user-image');

    // Dropdown extras
    const nameDdEl  = document.getElementById('auth-user-name-dd');
    const roleDdEl  = document.getElementById('auth-user-role-dd');
    const imageDdEl = document.getElementById('auth-user-image-dd');

    const imgSrc = user.profile_image
      ? `/static/${user.profile_image}`
      : 'https://via.placeholder.com/40';

    if (nameEl)  nameEl.textContent  = user.full_name;
    if (roleEl)  roleEl.textContent  = user.role_name;
    if (imageEl) imageEl.src = imgSrc;

    // Populate dropdown
    if (nameDdEl)  nameDdEl.textContent  = user.full_name;
    if (roleDdEl)  roleDdEl.textContent  = user.role_name;
    if (imageDdEl) imageDdEl.src = imgSrc.replace('40', '48');

    // Wire up dropdown toggle
    const btn      = document.getElementById('user-profile-btn');
    const dropdown = document.getElementById('profile-dropdown');
    const chevron  = document.getElementById('profile-chevron');

    if (btn && dropdown) {
      btn.addEventListener('click', function (e) {
        e.stopPropagation();
        const isOpen = dropdown.classList.toggle('open');
        if (chevron) chevron.style.transform = isOpen ? 'rotate(180deg)' : 'rotate(0deg)';
      });

      // Close when clicking outside
      document.addEventListener('click', function () {
        dropdown.classList.remove('open');
        if (chevron) chevron.style.transform = 'rotate(0deg)';
      });

      // Prevent dropdown itself from closing when clicked inside
      dropdown.addEventListener('click', function (e) {
        e.stopPropagation();
      });
    }
  }

  // ─────────────────────────────────────────────
  //  APPLY NAV ACCESS — lock/unlock sidebar items
  // ─────────────────────────────────────────────

  function applyNavAccess(pageAccess) {
    const navLinks = document.querySelectorAll('[data-page]');

    navLinks.forEach(link => {
      const pageKey = link.getAttribute('data-page');
      if (!pageKey) return;

      const allowed = pageAccess[pageKey];

      if (allowed === false) {
        // Lock the nav item
        link.classList.add('nav-locked');
        link.setAttribute('title', 'Access restricted for your role');

        // Add lock icon if not already there
        if (!link.querySelector('.lock-icon')) {
          const lock = document.createElement('span');
          lock.className = 'lock-icon';
          lock.innerHTML = `<svg xmlns="http://www.w3.org/2000/svg" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"><rect x="3" y="11" width="18" height="11" rx="2" ry="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>`;
          link.appendChild(lock);
        }

        // Prevent navigation
        link.addEventListener('click', function (e) {
          e.preventDefault();
          e.stopPropagation();
          showAccessTooltip(link);
        });
      }
    });
  }

  // ─────────────────────────────────────────────
  //  SHOW TOOLTIP on locked nav click
  // ─────────────────────────────────────────────

  function showAccessTooltip(link) {
    // Remove any existing tooltip
    const existing = document.querySelector('.nav-access-tooltip');
    if (existing) existing.remove();

    const tooltip = document.createElement('div');
    tooltip.className = 'nav-access-tooltip';
    tooltip.textContent = 'Access restricted for your role';
    document.body.appendChild(tooltip);

    const rect = link.getBoundingClientRect();
    tooltip.style.top  = `${rect.top + rect.height / 2 - tooltip.offsetHeight / 2}px`;
    tooltip.style.left = `${rect.right + 12}px`;

    setTimeout(() => tooltip.classList.add('visible'), 10);
    setTimeout(() => {
      tooltip.classList.remove('visible');
      setTimeout(() => tooltip.remove(), 300);
    }, 2000);
  }

  // ─────────────────────────────────────────────
  //  CHECK CURRENT PAGE — show overlay if restricted
  // ─────────────────────────────────────────────

  function checkCurrentPage(pageAccess) {
    const bodyPage = document.body.getAttribute('data-page');
    if (!bodyPage) return;

    const allowed = pageAccess[bodyPage];

    if (allowed === false) {
      showAccessOverlay();
    }
  }

  // ─────────────────────────────────────────────
  //  FULL-SCREEN BLUR OVERLAY
  // ─────────────────────────────────────────────

  function showAccessOverlay() {
    // Blur main content
    const main = document.querySelector('.main-content') || document.querySelector('main') || document.body;
    main.style.filter  = 'blur(6px)';
    main.style.pointerEvents = 'none';
    main.style.userSelect    = 'none';

    const overlay = document.createElement('div');
    overlay.id = 'access-overlay';
    overlay.innerHTML = `
      <div class="access-overlay-card">
        <div class="access-overlay-icon">
          <svg xmlns="http://www.w3.org/2000/svg" width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2" ry="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
        </div>
        <h2 class="access-overlay-title">Access Restricted</h2>
        <p class="access-overlay-msg">You don't have permission to access this module.</p>
        <div class="access-overlay-role">
          <span class="access-overlay-role-label">Your role</span>
          <span class="access-overlay-role-value">${currentUser ? currentUser.role_name : ''}</span>
        </div>
        <button class="access-overlay-btn" onclick="window.location.href='/dashboard.html'">
          Go to Dashboard
        </button>
      </div>
    `;

    document.body.appendChild(overlay);
    setTimeout(() => overlay.classList.add('visible'), 10);
  }

  // ─────────────────────────────────────────────
  //  LOGOUT
  // ─────────────────────────────────────────────

  window.authLogout = async function () {
    try {
      await fetch('/auth/logout', { method: 'POST', credentials: 'include' });
    } catch (e) {}
    redirectToLogin();
  };

  // ─────────────────────────────────────────────
  //  REDIRECT
  // ─────────────────────────────────────────────

  function redirectToLogin() {
    if (!window.location.pathname.includes('login')) {
      window.location.href = '/login';
    }
  }

  // ─────────────────────────────────────────────
  //  EXPOSE current user for other scripts
  // ─────────────────────────────────────────────

  window.getCurrentUser = function () { return currentUser; };

  // ── Run ──
  document.addEventListener('DOMContentLoaded', init);

})();