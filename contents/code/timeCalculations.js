// timeCalculations.js
// .pragma library

function timeToMinutes(timeDecimal) {
  const hours = Math.floor(timeDecimal);
  const minutes = (timeDecimal - hours) * 60;
  return hours * 60 + minutes;
}

function getCurrentTimeMinutes() {
  const now = new Date();
  return now.getHours() * 60 + now.getMinutes();
}

function parseTimeString(timeStr) {
  const parts = (timeStr || "00:00").split(":");
  const h = Math.max(0, Math.min(23, parseInt(parts[0] || 0)));
  const m = Math.max(0, Math.min(59, parseInt(parts[1] || 0)));
  return h + m / 60;
}

function normalizeTimeString(timeStr) {
  const parts = (timeStr || "00:00").split(":");
  const h = Math.max(0, Math.min(23, parseInt(parts[0] || 0)));
  const m = Math.max(0, Math.min(59, parseInt(parts[1] || 0)));
  return h.toString().padStart(2, "0") + ":" + m.toString().padStart(2, "0");
}

function parseScheduleInput(scheduleInput) {
  let data = scheduleInput;

  if (typeof scheduleInput === "string") {
    try {
      data = JSON.parse(scheduleInput);
    } catch (e) {
      data = null;
    }
  }

  let entries = [];

  if (Array.isArray(data)) {
    entries = data
      .map(function (item) {
        if (!item) return null;
        const time = normalizeTimeString(item.time || item.t || "00:00");
        const image = item.image || item.path || item.file || "";
        if (!image) return null;
        return { time: time, image: image };
      })
      .filter(Boolean);
  } else if (data && typeof data === "object") {
    for (const key in data) {
      if (!data.hasOwnProperty(key)) continue;
      const image = data[key];
      if (!image) continue;
      entries.push({ time: normalizeTimeString(key), image: image });
    }
  }

  // Sort by time ascending
  entries.sort(function (a, b) {
    return timeToMinutes(parseTimeString(a.time)) - timeToMinutes(parseTimeString(b.time));
  });

  return entries;
}

function getWallpaperForSchedule(scheduleInput) {
  const entries = parseScheduleInput(scheduleInput);
  if (!entries.length) return "";

  const currentMinutes = getCurrentTimeMinutes();

  let currentEntry = entries[entries.length - 1];
  for (let i = 0; i < entries.length; i++) {
    const entryMinutes = timeToMinutes(parseTimeString(entries[i].time));
    if (currentMinutes < entryMinutes) {
      break;
    }
    currentEntry = entries[i];
  }

  return currentEntry.image;
}

function getNextUpdateTimeSchedule(scheduleInput) {
  const entries = parseScheduleInput(scheduleInput);
  if (!entries.length) return 60 * 60 * 1000;

  const currentMinutes = getCurrentTimeMinutes();
  for (let i = 0; i < entries.length; i++) {
    const entryMinutes = timeToMinutes(parseTimeString(entries[i].time));
    if (entryMinutes > currentMinutes) {
      return (entryMinutes - currentMinutes) * 60 * 1000;
    }
  }

  // Next day for the first entry
  const firstMinutes = timeToMinutes(parseTimeString(entries[0].time));
  return (24 * 60 - currentMinutes + firstMinutes) * 60 * 1000;
}
