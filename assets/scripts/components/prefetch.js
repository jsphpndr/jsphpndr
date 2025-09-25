// Helpers
const sameOrigin = url => {
  const u = new URL(url, location.href);
  return u.origin === location.origin;
};

const canPrefetchNow = () =>
  !('connection' in navigator && (
     navigator.connection.saveData ||
     (navigator.connection.effectiveType && /2g/.test(navigator.connection.effectiveType))
  ));

// Core
function prefetch(url) {
  const href = new URL(url, location.href).toString();
  if (!sameOrigin(href) || !canPrefetchNow()) return;
  if (!document.querySelector(`link[rel="prefetch"][href="${href}"]`)) {
    const link = document.createElement('link');
    link.rel = 'prefetch';
    link.as = 'document';
    link.href = href;
    document.head.appendChild(link);
  }
}

// Mouse & touch (what you already had)
document.querySelectorAll('a[data-prefetch]').forEach(a => {
  const handler = () => prefetch(a.href);
  a.addEventListener('mouseenter', handler);
  a.addEventListener('mousedown', handler);
  a.addEventListener('touchstart', handler, { passive: true });
});

// Keyboard focus (Tabbing)
let focusTimer = null;
document.addEventListener('focusin', e => {
  const a = e.target.closest('a[data-prefetch]');
  if (!a) return;
  // Small delay so rapid tabbing doesn’t queue many prefetches
  clearTimeout(focusTimer);
  focusTimer = setTimeout(() => prefetch(a.href), 120);
});

// Optional: prefetch on Arrow navigation within menus using Enter/Space fallback
document.addEventListener('keydown', e => {
  if ((e.key === 'Enter' || e.key === ' ') && e.target instanceof HTMLAnchorElement) {
    const a = e.target.closest('a[data-prefetch]');
    if (a) prefetch(a.href);
  }
});
