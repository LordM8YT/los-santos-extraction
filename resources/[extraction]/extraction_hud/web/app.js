const raidPanel = document.getElementById("raidPanel");
const raidTimer = document.getElementById("raidTimer");
const bagValue = document.getElementById("bagValue");
const bagWeight = document.getElementById("bagWeight");
const progressPanel = document.getElementById("progressPanel");
const progressLabel = document.getElementById("progressLabel");
const progressPercent = document.getElementById("progressPercent");
const progressFill = document.getElementById("progressFill");
const hintPanel = document.getElementById("hintPanel");
const profilePanel = document.getElementById("profilePanel");
const toastStack = document.getElementById("toastStack");

let profileTimer = null;
let raidVisible = false;
let progressVisible = false;
let hintVisible = false;
let profileVisible = false;
let toastCount = 0;

function updateRootVisibility() {
  const shouldShow = raidVisible || progressVisible || hintVisible || profileVisible || toastCount > 0;
  document.documentElement.classList.toggle("hud-closed", !shouldShow);
}

function setVisible(element, visible) {
  element.classList.toggle("hidden", !visible);
}

function formatTime(seconds) {
  const mins = Math.floor((seconds || 0) / 60);
  const secs = Math.max(0, seconds || 0) % 60;
  return `${String(mins).padStart(2, "0")}:${String(secs).padStart(2, "0")}`;
}

function showToast({ message, variant = "info" }) {
  if (!message) return;

  const toast = document.createElement("div");
  toast.className = `toast ${variant}`;
  toast.textContent = message;
  toastStack.prepend(toast);
  toastCount += 1;
  updateRootVisibility();

  setTimeout(() => {
    toast.style.opacity = "0";
    toast.style.transform = "translateX(18px)";
  }, 4400);

  setTimeout(() => {
    toast.remove();
    toastCount = Math.max(0, toastCount - 1);
    updateRootVisibility();
  }, 4900);
}

function showProfile(payload) {
  const title = payload.title || "Extraction Profile";
  const lines = payload.lines || [];

  profilePanel.innerHTML = `
    <h2>${title}</h2>
    ${lines.map((line) => `<p>${line}</p>`).join("")}
  `;

  setVisible(profilePanel, true);
  profileVisible = true;
  updateRootVisibility();
  clearTimeout(profileTimer);
  profileTimer = setTimeout(() => {
    setVisible(profilePanel, false);
    profileVisible = false;
    updateRootVisibility();
  }, payload.duration || 15000);
}

window.addEventListener("message", (event) => {
  const { action, payload = {} } = event.data || {};

  if (action === "raid") {
    raidVisible = Boolean(payload.active);
    setVisible(raidPanel, raidVisible);
    raidTimer.textContent = formatTime(payload.secondsLeft);
    bagValue.textContent = payload.carryValueText || "$0";
    bagWeight.textContent = payload.carryWeightText || "0 / 0";
    updateRootVisibility();
  }

  if (action === "progress") {
    progressVisible = Boolean(payload.active);
    setVisible(progressPanel, progressVisible);
    progressLabel.textContent = payload.label || "Working";
    progressPercent.textContent = `${payload.percent || 0}%`;
    progressFill.style.width = `${Math.max(0, Math.min(100, payload.percent || 0))}%`;
    updateRootVisibility();
  }

  if (action === "hint") {
    hintPanel.textContent = payload.text || "";
    hintVisible = Boolean(payload.text);
    setVisible(hintPanel, hintVisible);
    updateRootVisibility();
  }

  if (action === "notify") {
    showToast(payload);
  }

  if (action === "profile") {
    showProfile(payload);
  }
});
