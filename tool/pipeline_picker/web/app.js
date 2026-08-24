const $ = (id) => document.getElementById(id);

const pathInput = $("path");
const recentSelect = $("recent");
const projectStatus = $("project-status");
const groupsEl = $("groups");
const countEl = $("count");
const pickedEl = $("picked");
const submitBtn = $("submit");
const lede = $("lede");
const whatsappInput = $("whatsappNumber");

let mutex = [];
let pathTimer = null;
let lastValidatedPath = "";

async function api(method, url, body) {
  const options = { method, headers: { "Content-Type": "application/json" } };
  if (body) options.body = JSON.stringify(body);
  const response = await fetch(url, options);
  const type = response.headers.get("content-type") || "";
  if (type.includes("application/json")) {
    const data = await response.json();
    if (!response.ok) throw new Error(data.error || "Request failed");
    return data;
  }
  if (!response.ok) throw new Error("Request failed");
  return null;
}

function selectedIds() {
  return [...document.querySelectorAll("[data-step][aria-checked='true']")].map(
    (el) => el.dataset.step,
  );
}

function payload() {
  return {
    path: pathInput.value.trim(),
    selected: selectedIds(),
    version: $("version").value.trim(),
    buildNumber: $("buildNumber").value.trim(),
    gitBranch: $("gitBranch").value.trim() || "master",
    whatsappNumber: whatsappInput.value.trim(),
  };
}

function applyMeta(state, overwriteEmptyOnly) {
  const assign = (id, value) => {
    const el = $(id);
    if (!overwriteEmptyOnly || !el.value.trim()) el.value = value || "";
  };
  assign("version", state.version);
  assign("buildNumber", state.buildNumber);
  assign("gitBranch", state.gitBranch);
  assign("whatsappNumber", state.whatsappNumber);
  if (!overwriteEmptyOnly) {
    pathInput.value = state.projectPath || "";
  }
}

function fillRecents(paths, current) {
  recentSelect.innerHTML = "";
  const blank = document.createElement("option");
  blank.value = "";
  blank.textContent = paths.length ? "Choose a recent app" : "No recent apps yet";
  recentSelect.appendChild(blank);
  for (const path of paths) {
    const option = document.createElement("option");
    option.value = path;
    option.textContent = path;
    if (path === current) option.selected = true;
    recentSelect.appendChild(option);
  }
}

function setProjectStatus(state) {
  projectStatus.className = "status";
  if (state.projectValid) {
    projectStatus.classList.add("ok");
    projectStatus.textContent = "This folder is a Flutter app.";
    return;
  }
  if (state.projectError) {
    projectStatus.classList.add("bad");
    projectStatus.textContent = state.projectError;
    return;
  }
  projectStatus.textContent = "Choose a Flutter app folder to unlock jobs.";
}

function mutexFor(id) {
  return mutex.find((group) => group.includes(id)) || null;
}

function jobBlurb(step) {
  if (!step.enabled && step.reason) {
    return step.savedButBlocked
      ? step.reason + " Last run saved this job."
      : step.reason;
  }
  return step.blurb || "";
}

function makeSwitch(step) {
  const row = document.createElement("div");
  row.className = "job" + (step.enabled ? "" : " is-locked");
  const copy = document.createElement("div");
  copy.className = "job-copy";
  const title = document.createElement("p");
  title.className = "job-title";
  title.textContent = step.title || step.label;
  const blurb = document.createElement("p");
  blurb.className = "job-blurb";
  blurb.textContent = jobBlurb(step);
  copy.append(title, blurb);
  const toggle = document.createElement("button");
  toggle.type = "button";
  toggle.className = "switch";
  toggle.dataset.step = step.id;
  toggle.id = "step-" + step.id;
  toggle.setAttribute("role", "switch");
  toggle.setAttribute("aria-checked", step.checked ? "true" : "false");
  toggle.disabled = !step.enabled;
  toggle.setAttribute("aria-label", step.title || step.label);
  toggle.addEventListener("click", () => onToggle(step.id));
  row.append(copy, toggle);
  return row;
}

function makeChoice(steps) {
  const wrap = document.createElement("div");
  wrap.className = "choice";
  const hint = document.createElement("p");
  hint.className = "choice-hint";
  hint.textContent =
    steps.length > 2 ? "Pick one, or leave all off." : "Pick one, or leave both off.";
  const row = document.createElement("div");
  row.className = "segments";
  for (const step of steps) {
    const segment = document.createElement("button");
    segment.type = "button";
    segment.className = "segment";
    segment.dataset.step = step.id;
    segment.id = "step-" + step.id;
    segment.setAttribute("aria-checked", step.checked ? "true" : "false");
    segment.setAttribute("aria-label", step.title || step.label);
    segment.disabled = !step.enabled;
    segment.textContent = step.title || step.label;
    if (!step.enabled && step.reason) segment.title = step.reason;
    segment.addEventListener("click", () => onToggle(step.id));
    row.appendChild(segment);
  }
  wrap.append(hint, row);
  const locked = steps.find((step) => !step.enabled && step.reason);
  if (locked) {
    const why = document.createElement("p");
    why.className = "reason";
    why.textContent = locked.reason;
    wrap.appendChild(why);
  }
  return wrap;
}

function renderGroups(state) {
  mutex = state.mutex || [];
  groupsEl.innerHTML = "";
  for (const group of state.groups || []) {
    const wrap = document.createElement("section");
    wrap.className = "chapter";
    const head = document.createElement("div");
    head.className = "chapter-head";
    const title = document.createElement("h3");
    title.textContent = group.title;
    const onCount = group.steps.filter((step) => step.checked).length;
    const meta = document.createElement("span");
    meta.className = "chapter-meta";
    meta.textContent = onCount ? onCount + " on" : "Off";
    head.append(title, meta);
    wrap.appendChild(head);

    const used = new Set();
    const list = document.createElement("div");
    for (const step of group.steps) {
      if (used.has(step.id)) continue;
      const groupIds = mutexFor(step.id);
      if (groupIds) {
        const pack = group.steps.filter((item) => groupIds.includes(item.id));
        pack.forEach((item) => used.add(item.id));
        list.appendChild(makeChoice(pack));
      } else {
        used.add(step.id);
        list.appendChild(makeSwitch(step));
      }
    }
    wrap.appendChild(list);
    groupsEl.appendChild(wrap);
  }
  updateFooter();
}

function updateFooter() {
  const ids = selectedIds();
  const n = ids.length;
  countEl.textContent = n + " selected";
  pickedEl.textContent = n
    ? ids
        .map((id) => {
          const el = document.getElementById("step-" + id);
          return el ? el.getAttribute("aria-label") || el.textContent : id;
        })
        .filter(Boolean)
        .join(" · ")
    : "Nothing selected";
  submitBtn.disabled = !pathInput.value.trim() || !lastValidatedPath;
}

async function refresh(fromValidate) {
  const state = await api("POST", fromValidate ? "/api/validate" : "/api/readiness", payload());
  if (fromValidate) {
    lastValidatedPath = state.valid ? (state.projectPath || pathInput.value.trim()) : "";
    if (state.valid) {
      if (state.versionFromPubspec && !$("version").value.trim()) {
        $("version").value = state.versionFromPubspec;
      }
      if (state.buildNumberFromPubspec && !$("buildNumber").value.trim()) {
        $("buildNumber").value = state.buildNumberFromPubspec;
      }
      pathInput.value = state.projectPath || pathInput.value;
    }
  } else if (state.projectValid) {
    lastValidatedPath = state.projectPath || pathInput.value.trim();
  }
  setProjectStatus(state);
  renderGroups(state);
  submitBtn.disabled = !state.projectValid;
  return state;
}

async function onToggle(id) {
  const el = document.getElementById("step-" + id);
  if (!el || el.disabled) return;
  const next = el.getAttribute("aria-checked") !== "true";
  el.setAttribute("aria-checked", next ? "true" : "false");
  if (next) {
    const group = mutexFor(id);
    if (group) {
      for (const other of group) {
        if (other === id) continue;
        const peer = document.getElementById("step-" + other);
        if (peer) peer.setAttribute("aria-checked", "false");
      }
    }
  }
  await refresh(false);
}

function schedulePathRefresh() {
  clearTimeout(pathTimer);
  pathTimer = setTimeout(() => {
    refresh(true).catch((err) => {
      projectStatus.className = "status bad";
      projectStatus.textContent = err.message;
    });
  }, 300);
}

async function boot() {
  const state = await api("GET", "/api/state");
  if (!state.isFirstRun) {
    lede.textContent =
      "This is the last app you used. Turn on the jobs you want, then start.";
  }
  fillRecents(state.recentProjectPaths || [], state.projectPath);
  applyMeta(state, false);
  lastValidatedPath = state.projectValid ? state.projectPath : "";
  setProjectStatus(state);
  renderGroups(state);
  submitBtn.disabled = !state.projectValid;
}

recentSelect.addEventListener("change", async () => {
  if (!recentSelect.value) return;
  pathInput.value = recentSelect.value;
  $("version").value = "";
  $("buildNumber").value = "";
  await refresh(true);
});

pathInput.addEventListener("input", schedulePathRefresh);
whatsappInput.addEventListener("change", () => {
  refresh(false).catch((err) => {
    projectStatus.className = "status bad";
    projectStatus.textContent = err.message;
  });
});
$("validate").addEventListener("click", () => refresh(true));
$("browse").addEventListener("click", async () => {
  try {
    const state = await api("POST", "/api/browse", payload());
    if (state.error && !state.projectPath) {
      projectStatus.className = "status bad";
      projectStatus.textContent = state.error;
      return;
    }
    applyMeta(state, true);
    pathInput.value = state.projectPath || pathInput.value;
    lastValidatedPath = state.valid ? state.projectPath : "";
    fillRecents(state.recentProjectPaths || [], state.projectPath);
    setProjectStatus(state);
    renderGroups(state);
    submitBtn.disabled = !state.projectValid;
  } catch (err) {
    projectStatus.className = "status bad";
    projectStatus.textContent = err.message;
  }
});

$("cancel").addEventListener("click", async () => {
  const response = await fetch("/api/cancel", { method: "POST" });
  document.open();
  document.write(await response.text());
  document.close();
});

$("submit").addEventListener("click", async () => {
  submitBtn.disabled = true;
  try {
    const response = await fetch("/api/submit", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload()),
    });
    if (!response.ok) {
      const data = await response.json();
      throw new Error(data.error || "Submit failed");
    }
    document.open();
    document.write(await response.text());
    document.close();
  } catch (err) {
    projectStatus.className = "status bad";
    projectStatus.textContent = err.message;
    submitBtn.disabled = false;
  }
});

window.addEventListener("pagehide", () => clearTimeout(pathTimer));

boot().catch((err) => {
  projectStatus.className = "status bad";
  projectStatus.textContent = err.message;
});
