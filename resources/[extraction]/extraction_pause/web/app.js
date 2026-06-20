const root = document.documentElement;
const app = document.getElementById("app");
const toast = document.getElementById("toast");

let toastTimer = null;

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

function open() {
  root.classList.remove("pause-closed");
  app.classList.add("is-open");
  app.setAttribute("aria-hidden", "false");
}

function close() {
  app.classList.remove("is-open");
  app.setAttribute("aria-hidden", "true");
  root.classList.add("pause-closed");
}

window.addEventListener("message", (event) => {
  const { action } = event.data || {};

  if (action === "open") {
    open();
  }

  if (action === "close") {
    close();
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

  post(action);
});

document.addEventListener("keydown", (event) => {
  if (event.key === "Escape") {
    post("close");
  }
});
