import { kvGet, kvSet, persistStorage, readSaveMeta } from "./db.js";
import { describePad, watchGamepad } from "./gamepad.js";
import {
  acceptList,
  detectSystem,
  prettyTitle,
  romFilename,
  slugId,
  systemById,
  SYSTEMS,
} from "./systems.js";

const list = document.querySelector("#list");
const search = document.querySelector("#search");
const pad = document.querySelector("#pad");
const padName = document.querySelector("#pad-name");
const fileInput = document.querySelector("#file");
const picker = document.querySelector("#picker");
const pickerName = document.querySelector("#picker-name");
const pickerLead = document.querySelector("#picker-lead");
const pickerSystem = document.querySelector("#picker-system");
const pickerGo = document.querySelector("#picker-go");
const empty = document.querySelector("#empty");

const bundled = SYSTEMS.filter((system) => system.bundled);
fileInput.accept = acceptList();
for (const system of bundled) {
  const option = document.createElement("option");
  option.value = system.id;
  option.textContent = system.label;
  pickerSystem.append(option);
}

const LOCAL_KEY = "local-games";

let games = [];
let localRecords = [];
let query = "";
let pendingFile = null;
const folded = new Set(readFolded());

function readFolded() {
  try {
    return JSON.parse(localStorage.getItem("retro-folded") || "[]");
  } catch {
    return [];
  }
}

function gamesWord(count) {
  return count === 1 ? "1 game" : `${count} games`;
}

function orderOf(systemId) {
  const index = SYSTEMS.findIndex((system) => system.id === systemId);
  return index === -1 ? 99 : index;
}

function shelf() {
  const local = localRecords.map((record) => ({
    id: record.id,
    title: record.title,
    system: record.system,
    local: true,
  }));
  return [...games, ...local];
}

function render() {
  const visible = shelf().filter((game) => {
    const haystack = `${game.title} ${game.system}`.toLowerCase();
    return haystack.includes(query);
  });
  const groups = new Map();
  for (const game of visible) {
    if (!groups.has(game.system)) groups.set(game.system, []);
    groups.get(game.system).push(game);
  }
  const ordered = [...groups.keys()].sort((a, b) => orderOf(a) - orderOf(b));
  list.replaceChildren();
  empty.hidden = visible.length > 0;

  const saved = readSaveMeta();
  for (const systemId of ordered) {
    const system = systemById(systemId);
    const items = groups.get(systemId);
    const section = document.createElement("section");
    section.className = "group";
    if (!query && folded.has(systemId)) section.classList.add("is-folded");

    const head = document.createElement("div");
    head.className = "group-head";
    const title = document.createElement("h2");
    title.textContent = system?.short || systemId;
    const toggle = document.createElement("button");
    toggle.type = "button";
    toggle.className = "group-count";
    toggle.textContent = gamesWord(items.length);
    toggle.setAttribute("aria-expanded", String(!section.classList.contains("is-folded")));
    toggle.addEventListener("click", () => {
      section.classList.toggle("is-folded");
      const closed = section.classList.contains("is-folded");
      toggle.setAttribute("aria-expanded", String(!closed));
      if (closed) folded.add(systemId);
      else folded.delete(systemId);
      localStorage.setItem("retro-folded", JSON.stringify([...folded]));
    });
    head.append(title, toggle);

    const grid = document.createElement("div");
    grid.className = "grid";
    for (const game of items) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "card";
      const cover = document.createElement("span");
      cover.className = "cover";
      cover.dataset.system = game.system;
      if (game.cover) {
        cover.classList.add("has-art");
        const image = document.createElement("img");
        image.alt = "";
        image.src = new URL(`roms/${game.cover}`, document.baseURI).href;
        cover.append(image);
      }
      const kicker = document.createElement("span");
      kicker.className = "cover-kicker";
      kicker.textContent = system?.short || game.system;
      const coverTitle = document.createElement("span");
      coverTitle.className = "cover-title";
      coverTitle.textContent = game.title;
      cover.append(kicker, coverTitle);
      if (saved[game.id]) {
        const pip = document.createElement("span");
        pip.className = "saved-pip";
        cover.append(pip);
      }
      const name = document.createElement("span");
      name.className = "card-name";
      name.textContent = game.title;
      button.append(cover, name);
      button.addEventListener("click", () => {
        void persistStorage();
        const target = game.local
          ? `play.html?local=${encodeURIComponent(game.id)}`
          : `play.html?id=${encodeURIComponent(game.id)}`;
        location.href = target;
      });
      grid.append(button);
    }
    section.append(head, grid);
    list.append(section);
  }
}

async function readLocalGames() {
  const stored = await kvGet(LOCAL_KEY);
  const records = Array.isArray(stored) ? stored.filter((item) => item?.data) : [];
  const single = await kvGet("local-rom");
  if (single?.data && !records.some((item) => item.id === single.key || item.id === single.id)) {
    records.unshift({
      id: single.key || single.id,
      title: single.title || prettyTitle(single.name || "Game"),
      system: single.system,
      core: single.core,
      name: single.name,
      data: single.data,
    });
  }
  return records;
}

async function startLocal(file, system, bytes) {
  const data = bytes || await file.arrayBuffer();
  const filename = romFilename(file.name, system);
  const record = {
    id: `local:${slugId(filename)}`,
    title: prettyTitle(filename),
    system: system.id,
    core: system.core,
    name: filename,
    data,
  };
  const next = localRecords.filter((item) => item.id !== record.id);
  next.unshift(record);
  localRecords = next;
  await kvSet(LOCAL_KEY, next);
  await kvSet("local-rom", { ...record, key: record.id });
  await persistStorage();
  location.href = `play.html?local=${encodeURIComponent(record.id)}`;
}

fileInput.addEventListener("change", () => {
  const file = fileInput.files?.[0];
  fileInput.value = "";
  if (!file) return;
  void file.arrayBuffer().then((bytes) => {
    pendingFile = file;
    pendingFile.bytes = bytes;
    const system = detectSystem(bytes, file.name);
    if (!system || system.bundled === false) {
      pickerLead.textContent = system
        ? "This core is not bundled. Try it as"
        : "Could not tell the console for";
      pickerName.textContent = file.name;
      picker.hidden = false;
      return;
    }
    void startLocal(file, system, bytes);
  });
});

pickerGo.addEventListener("click", () => {
  const system = systemById(pickerSystem.value);
  if (!pendingFile || !system) return;
  picker.hidden = true;
  void startLocal(pendingFile, system, pendingFile.bytes);
});

search.addEventListener("input", () => {
  query = search.value.trim().toLowerCase();
  render();
});

watchGamepad((next) => {
  pad.classList.toggle("on", Boolean(next));
  padName.textContent = next ? describePad(next) : "Gamepad";
});

try {
  localRecords = await readLocalGames();
} catch {
  localRecords = [];
}

try {
  const response = await fetch(new URL("roms/library.json", document.baseURI));
  if (!response.ok) throw new Error(String(response.status));
  const library = await response.json();
  games = library.games || [];
} catch {
  if (!localRecords.length) {
    empty.hidden = false;
    empty.textContent = "Could not read the library. Open the site through a server, not as a file.";
  }
}

render();
void persistStorage();
