const root = document.documentElement;
const app = document.getElementById("app");
const toast = document.getElementById("toast");
const menuView = document.getElementById("menuView");
const mapView = document.getElementById("mapView");
const playerMarker = document.getElementById("playerMarker");
const mapLocation = document.getElementById("mapLocation");
const mapCoords = document.getElementById("mapCoords");
const mapHeading = document.getElementById("mapHeading");
const mapSpeed = document.getElementById("mapSpeed");
const mapGrid = document.getElementById("mapGrid");
const mapLootZones = document.getElementById("mapLootZones");
const mapExtractions = document.getElementById("mapExtractions");
const mapDeathSignals = document.getElementById("mapDeathSignals");
const tabButtons = [...document.querySelectorAll(".view-tabs [data-action='setView']")];

let toastTimer = null;
let currentView = "menu";
let mapPayload = null;

const resourceName =
  typeof GetParentResourceName === "function"
    ? GetParentResourceName()
    : "extraction_pause";

function post(action, payload = {}) {
  return fetch(`https://${resourceName}/${action}`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(payload),
  }).catch(() => {});
}

function showToast(message) {
  toast.textContent = message;
  toast.classList.add("is-visible");
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.remove("is-visible"), 2200);
}

function projectPoint(coords, bounds) {
  if (!coords || !bounds) {
    return { x: 50, y: 50 };
  }

  const width = bounds.maxX - bounds.minX;
  const height = bounds.maxY - bounds.minY;
  const x = ((coords.x - bounds.minX) / width) * 100;
  const y = (1 - (coords.y - bounds.minY) / height) * 100;

  return {
    x: Math.max(0, Math.min(100, x)),
    y: Math.max(0, Math.min(100, y)),
  };
}

function radiusToPercent(radius, bounds) {
  if (!bounds) {
    return 10;
  }

  const width = Math.abs(bounds.maxX - bounds.minX);
  return Math.max(5, Math.min(28, (Number(radius || 350) / width) * 100));
}

function clearLayer(layer) {
  while (layer.firstChild) {
    layer.removeChild(layer.firstChild);
  }
}

function renderLootZones(payload) {
  clearLayer(mapLootZones);

  for (const zone of payload.lootZones || []) {
    const point = projectPoint(zone.center, payload.bounds);
    const size = radiusToPercent(zone.radius, payload.bounds) * 2;
    const node = document.createElement("div");
    node.className = `loot-zone ${zone.tier || "low"}`;
    node.style.left = `${point.x}%`;
    node.style.top = `${point.y}%`;
    node.style.width = `${size}%`;
    node.style.height = `${size}%`;
    node.innerHTML = `<strong>${zone.label || "Loot Zone"}</strong><span>${zone.intel || "Scavenging area"}</span>`;
    mapLootZones.appendChild(node);
  }
}

function renderExtractions(payload) {
  clearLayer(mapExtractions);

  for (const extract of payload.extractions || []) {
    const point = projectPoint(extract.coords, payload.bounds);
    const node = document.createElement("div");
    node.className = "extract-marker";
    node.style.left = `${point.x}%`;
    node.style.top = `${point.y}%`;
    node.innerHTML = `<span></span><strong>${extract.label || "Extract"}</strong>`;
    mapExtractions.appendChild(node);
  }
}

function renderDeathSignals(payload) {
  clearLayer(mapDeathSignals);

  for (const signal of payload.deathSignals || []) {
    const point = projectPoint(signal.coords, payload.bounds);
    const node = document.createElement("div");
    node.className = "death-signal-marker";
    node.style.left = `${point.x}%`;
    node.style.top = `${point.y}%`;
    node.innerHTML = `<span></span><strong>Death Signal</strong>`;
    mapDeathSignals.appendChild(node);
  }
}

function renderMap(payload) {
  mapPayload = payload || mapPayload;

  if (!mapPayload) {
    return;
  }

  const player = mapPayload.player || {};
  const position = projectPoint(player, mapPayload.bounds);
  const location = player.crossing ? `${player.location} / ${player.crossing}` : player.location;

  playerMarker.style.left = `${position.x}%`;
  playerMarker.style.top = `${position.y}%`;
  playerMarker.style.transform = `translate(-50%, -50%) rotate(${Number(player.heading || 0)}deg)`;
  mapLocation.textContent = location || "Unknown Sector";
  mapCoords.textContent = `${Math.floor(player.x || 0)}, ${Math.floor(player.y || 0)}, ${Math.floor(player.z || 0)}`;
  mapHeading.textContent = `${Math.floor(player.heading || 0).toString().padStart(3, "0")}`;
  mapSpeed.textContent = `${Math.floor(player.speed || 0)} km/h`;

  renderLootZones(mapPayload);
  renderExtractions(mapPayload);
  renderDeathSignals(mapPayload);
}

function setView(view) {
  currentView = view || "menu";
  menuView.classList.toggle("hidden", currentView !== "menu");
  mapView.classList.toggle("hidden", currentView !== "map");
  app.dataset.view = currentView;

  for (const button of tabButtons) {
    button.classList.toggle("is-active", button.dataset.view === currentView);
  }

  if (currentView === "map") {
    renderMap(mapPayload);
  }
}

function open(payload = {}) {
  root.classList.remove("pause-closed");
  app.classList.add("is-open");
  app.setAttribute("aria-hidden", "false");
  mapPayload = payload.map || mapPayload;
  setView(payload.view || "menu");
}

function close() {
  app.classList.remove("is-open");
  app.setAttribute("aria-hidden", "true");
  root.classList.add("pause-closed");
}

window.addEventListener("message", (event) => {
  const { action, payload = {} } = event.data || {};

  if (action === "open") {
    open(payload);
  }

  if (action === "close") {
    close();
  }

  if (action === "setView") {
    setView(payload.view);
  }

  if (action === "mapData") {
    renderMap(payload);
  }
});

document.addEventListener("click", (event) => {
  const button = event.target?.closest("[data-action]");
  if (!button) {
    return;
  }

  const action = button.dataset.action;

  if (action === "soon") {
    showToast(`${button.dataset.label || "Feature"} is coming in a future milestone.`);
    return;
  }

  if (action === "setView") {
    post("setView", { view: button.dataset.view || "menu" });
    return;
  }

  post(action);
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    post("close");
  }

  if (event.key.toLowerCase() === "m") {
    post("setView", { view: currentView === "map" ? "menu" : "map" });
  }
});
