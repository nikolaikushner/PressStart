import { kvGet, kvSet, persistStorage, stateKey, writeSaveMeta } from "./db.js";
import { bindPad } from "./controls.js";
import { watchGamepad } from "./gamepad.js";
import { numericGameId, romFilename, skinFor, systemById } from "./systems.js";

const startButton = document.querySelector("#start");
const toast = document.querySelector("#toast");
const params = new URLSearchParams(location.search);
let fresh = params.get("fresh") === "1";
let game = null;
let started = false;
let resumeLoaded = false;
let leaving = false;
let ready = false;
let toastTimer = 0;

function showToast(message) {
  toast.textContent = message;
  toast.hidden = false;
  window.clearTimeout(toastTimer);
  toastTimer = window.setTimeout(() => {
    toast.hidden = true;
  }, 1800);
}

function toBytes(data) {
  if (data instanceof Uint8Array) return data;
  if (ArrayBuffer.isView(data)) return new Uint8Array(data.buffer, data.byteOffset, data.byteLength);
  if (data instanceof ArrayBuffer) return new Uint8Array(data);
  if (Array.isArray(data)) return Uint8Array.from(data);
  return null;
}

async function existingState() {
  if (!game) return null;
  const bytes = toBytes(await kvGet(stateKey(game.key)));
  return bytes?.byteLength ? bytes : null;
}

async function saveNow(reason) {
  if (!started || !game) return false;
  const manager = window.EJS_emulator?.gameManager;
  if (!manager?.getState) return false;
  try {
    manager.functions?.saveSaveFiles?.();
  } catch {
    // Battery RAM can be missing until the core has written it. The snapshot still counts.
  }
  let bytes = null;
  try {
    bytes = toBytes(manager.getState());
  } catch {
    bytes = null;
  }
  if (!bytes?.byteLength) return false;
  await kvSet(stateKey(game.key), bytes);
  writeSaveMeta(game.key, Date.now());
  if (reason) showToast(reason);
  return true;
}

async function loadSnapshot() {
  const manager = window.EJS_emulator?.gameManager;
  const bytes = await existingState();
  if (!manager?.loadState || !bytes) return false;
  manager.loadState(bytes);
  return true;
}

function goLibrary() {
  if (leaving) return;
  leaving = true;
  location.href = "./";
}

async function leave() {
  try {
    await saveNow("");
  } catch {
    // The last automatic snapshot stays if this flush fails.
  }
  const emulator = window.EJS_emulator;
  if (typeof emulator?.exit === "function") {
    try {
      emulator.exit();
    } catch {
      goLibrary();
      return;
    }
    window.setTimeout(goLibrary, 700);
    return;
  }
  goLibrary();
}

function press(index, value) {
  const manager = window.EJS_emulator?.gameManager;
  if (!started || !manager?.simulateInput) {
    if (value === 1) showToast("Press Play first");
    return;
  }
  manager.simulateInput(0, index, value);
}

async function resolveLocal() {
  const wanted = params.get("local");
  const stored = await kvGet("local-games");
  const records = Array.isArray(stored) ? stored : [];
  let record = records.find((item) => item?.id === wanted) || null;
  if (!record) {
    const single = await kvGet("local-rom");
    if (single && (wanted === "1" || single.key === wanted || single.id === wanted)) record = single;
  }
  if (!record?.data) return null;
  const system = systemById(record.system);
  const filename = romFilename(record.name || record.title, system);
  return {
    key: record.id || record.key,
    title: record.title || record.name,
    core: record.core || system?.core,
    system: record.system,
    url: new File([record.data], filename),
    biosUrl: "",
  };
}

async function resolveGame() {
  if (params.has("local")) return resolveLocal();
  const id = params.get("id");
  if (!id) return null;
  const response = await fetch(new URL("roms/library.json", document.baseURI));
  if (!response.ok) throw new Error("library");
  const library = await response.json();
  const entry = (library.games || []).find((item) => item.id === id);
  if (!entry) return null;
  const biosPath = library.bios?.[entry.system];
  return {
    key: entry.id,
    title: entry.title,
    core: entry.core,
    system: entry.system,
    url: new URL(`roms/${entry.file}`, document.baseURI).href,
    biosUrl: biosPath ? new URL(`roms/${biosPath}`, document.baseURI).href : "",
  };
}

function mount(entry, hasSave) {
  window.EJS_player = "#game";
  window.EJS_core = entry.core;
  window.EJS_gameName = entry.title;
  window.EJS_gameUrl = entry.url;
  window.EJS_gameID = numericGameId(entry.key);
  window.EJS_pathtodata = new URL("vendor/emulatorjs/", document.baseURI).href;
  window.EJS_startOnLoaded = true;
  window.EJS_startButtonName = "Play";
  window.EJS_language = "en-US";
  window.EJS_disableAutoLang = false;
  window.EJS_color = "#e23d78";
  window.EJS_backgroundColor = "#070707";
  window.EJS_fixedSaveInterval = 15000;
  window.EJS_askBeforeExit = false;
  window.EJS_biosUrl = entry.biosUrl || "";
  window.EJS_defaultOptions = { "save-state-location": "browser" };
  window.EJS_Buttons = {
    playPause: false,
    restart: false,
    mute: false,
    settings: false,
    fullscreen: false,
    saveState: false,
    loadState: false,
    screenRecord: false,
    gamepad: false,
    cheat: false,
    volume: false,
    saveSavFiles: false,
    loadSavFiles: false,
    quickSave: false,
    quickLoad: false,
    screenshot: false,
    cacheManager: false,
    exitEmulation: false,
  };
  window.EJS_ready = () => {
    ready = true;
    startButton.hidden = true;
    document.querySelector(".ejs_start_button")?.click();
  };
  window.EJS_onGameStart = () => {
    started = true;
    startButton.hidden = true;
    if (!fresh && !resumeLoaded) {
      resumeLoaded = true;
      window.setTimeout(() => {
        void loadSnapshot().then((loaded) => {
          if (loaded) showToast("Resuming");
        });
      }, 800);
    }
  };
  window.EJS_onExit = () => goLibrary();
  const script = document.createElement("script");
  script.src = new URL("vendor/emulatorjs/loader.js", document.baseURI).href;
  document.body.appendChild(script);
}

const hits = document.querySelector("#hits");
const actions = document.querySelector("#actions");

async function applySkin(kind) {
  const response = await fetch(new URL(`skins/${kind}.json`, document.baseURI));
  const layout = await response.json();
  document.querySelector("#shell").src = new URL(layout.image, document.baseURI).href;
  hits.replaceChildren();
  for (const button of layout.buttons) {
    const el = document.createElement("button");
    el.type = "button";
    el.className = "hit";
    el.style.left = `${button.x * 100}%`;
    el.style.top = `${button.y * 100}%`;
    el.style.width = `${button.w * 100}%`;
    el.style.height = `${button.h * 100}%`;
    if (button.btn === "menu") {
      el.dataset.action = "menu";
      el.setAttribute("aria-label", "Menu");
      el.addEventListener("click", () => {
        actions.hidden = false;
      });
    } else {
      el.dataset.btn = button.btn;
      el.setAttribute("aria-label", button.btn);
    }
    hits.appendChild(el);
  }
  bindPad(hits, press);
}

watchGamepad((next) => {
  document.body.classList.toggle("pad-on", Boolean(next));
});
document.querySelector("#actions-close").addEventListener("click", () => {
  actions.hidden = true;
});
actions.addEventListener("click", (event) => {
  if (event.target === actions) actions.hidden = true;
});

document.querySelector("#back").addEventListener("click", () => {
  actions.hidden = true;
  void leave();
});
document.querySelector("#save").addEventListener("click", () => {
  actions.hidden = true;
  void saveNow("Saved").then((ok) => {
    if (!ok) showToast("Press Play first");
  });
});
document.querySelector("#load").addEventListener("click", () => {
  actions.hidden = true;
  if (!started) {
    showToast("Press Play first");
    return;
  }
  void loadSnapshot().then((ok) => showToast(ok ? "Loaded" : "No save"));
});
document.querySelector("#restart").addEventListener("click", () => {
  actions.hidden = true;
  fresh = true;
  resumeLoaded = true;
  startButton.textContent = "Play";
  const manager = window.EJS_emulator?.gameManager;
  if (started && manager?.restart) manager.restart();
});
startButton.addEventListener("click", () => {
  const inner = document.querySelector(".ejs_start_button");
  if (!ready || !inner) {
    showToast("The emulator is still loading");
    return;
  }
  inner.click();
});

document.addEventListener("visibilitychange", () => {
  if (document.visibilityState === "hidden") void saveNow("");
});
window.addEventListener("pagehide", () => {
  void saveNow("");
});
window.setInterval(() => {
  void saveNow("");
}, 45000);

try {
  game = await resolveGame();
} catch {
  game = null;
}

const kind = game ? skinFor(game.system) : "pocket";
await applySkin(kind);

if (!game) {
  startButton.textContent = "No game";
} else {
  const system = systemById(game.system);
  const ratio = { gb: [10, 9], gbc: [10, 9], gba: [3, 2] }[game.system] || [4, 3];
  document.documentElement.style.setProperty("--rw", String(ratio[0]));
  document.documentElement.style.setProperty("--rh", String(ratio[1]));
  document.title = game.title;
  if (system && system.bundled === false) {
    startButton.textContent = "No core";
    showToast("This core is not bundled with the site");
  } else {
    const bytes = await existingState();
    mount(game, Boolean(bytes));
  }
}

void persistStorage();
