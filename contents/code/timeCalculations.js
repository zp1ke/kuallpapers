// timeCalculations.js
// .pragma library

function getDefaultScheduleJson() {
  return JSON.stringify([
    { "time": "01:00", "image": "images/12-Late-Night.png" },
    { "time": "06:30", "image": "images/01-Early-Morning.png" },
    { "time": "07:20", "image": "images/02-Mid-Morning.png" },
    { "time": "09:00", "image": "images/03-Late-Morning.png" },
    { "time": "12:00", "image": "images/04-Early-Afternoon.png" },
    { "time": "14:00", "image": "images/05-Mid-Afternoon.png" },
    { "time": "16:00", "image": "images/06-Late-Afternoon.png" },
    { "time": "17:00", "image": "images/07-Early-Evening.png" },
    { "time": "18:00", "image": "images/08-Mid-Evening.png" },
    { "time": "18:30", "image": "images/09-Late-Evening.png" },
    { "time": "19:30", "image": "images/10-Early-Night.png" },
    { "time": "22:00", "image": "images/11-Mid-Night.png" }
  ]);
}

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

function writeFile(filePath, content) {
  try {
    const request = new XMLHttpRequest();
    request.open("PUT", "file://" + filePath, false);
    request.send(content);
    return true;
  } catch (e) {
    console.error("Error writing file:", e);
    return false;
  }
}

function readFile(filePath) {
  try {
    const request = new XMLHttpRequest();
    request.open("GET", "file://" + filePath, false);
    request.send(null);
    if (request.status === 200 || request.status === 0) {
      return request.responseText;
    }
    return null;
  } catch (e) {
    console.error("Error reading file:", e);
    return null;
  }
}
