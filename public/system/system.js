// Refreshes the dashboard's numbers each second from /system/stats, while the page is in view.
const numbers = document.querySelectorAll('[data-stat]');

async function refreshStats() {
  if (document.hidden) return;

  try {
    const response = await fetch('/system/stats', { headers: { accept: 'application/json' }, cache: 'no-store' });
    if (!response.ok) return;

    const stats = await response.json();
    numbers.forEach((number) => {
      const value = stats[number.dataset.stat];
      if (value !== undefined) number.textContent = value;
    });
  } catch {
    // The next second tries again, like after a restart.
  }
}

if (numbers.length > 0) setInterval(refreshStats, 1000);
