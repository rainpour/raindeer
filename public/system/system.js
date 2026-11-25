// Refreshes the dashboard's numbers and interval pills each second from /system/stats, while the page is in view.
const numbers = document.querySelectorAll('[data-stat]');
const pills = document.querySelectorAll('[data-pill]');

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
    pills.forEach((pill) => {
      const outcome = stats.intervals?.[pill.dataset.pill];
      if (!outcome) return;
      pill.dataset.status = outcome.status;
      pill.dataset.tooltip = outcome.tip;
    });
  } catch {
    // The next second tries again, like after a restart.
  }
}

if (numbers.length > 0) setInterval(refreshStats, 1000);

// Steps each interval dial's line to the server's second or minute or hour or weekday from Monday. The offset keeps hours in the server's zone.
const dials = document.querySelector('.dials');
const clockReaders = {
  seconds: (now) => now.getUTCSeconds(),
  minutes: (now) => now.getUTCMinutes(),
  hours: (now) => now.getUTCHours(),
  days: (now) => (now.getUTCDay() + 6) % 7,
};

function moveDialLines() {
  const now = new Date(Date.now() + Number(dials.dataset.offset) * 1000);
  dials.querySelectorAll('.dial').forEach((dial) => {
    dial.style.setProperty('--now', clockReaders[dial.dataset.unit](now));
  });
}

if (dials) {
  moveDialLines();
  setInterval(moveDialLines, 1000);
}
