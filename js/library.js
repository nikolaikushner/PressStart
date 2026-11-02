import { kvSet, persistStorage, readSaveMeta } from "./db.js";
import { describePad, watchGamepad } from "./gamepad.js";
import {
  acceptList,
  prettyTitle,
  slugId,
  systemById,
  systemFromPath,
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

let games = [];
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
  const mod10 = count % 10;
  const mod100 = count % 100;
  if (mod10 === 1 && mod100 !== 11) return `${count} игра`;
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) return `${count} игры`;
  return `${count} игр`;
}

function orderOf(systemId) {
  const index = SYSTEMS.findIndex((system) => system.id === systemId);
  return index === -1 ? 99 : index;
}

function render() {
  const visible = games.filter((game) => {
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
        location.href = `play.html?id=${encodeURIComponent(game.id)}`;
      });
      grid.append(button);
    }
    section.append(head, grid);
    list.append(section);
  }
}

async function startLocal(file, system) {
  const title = prettyTitle(file.name);
  await kvSet("local-rom", {
    key: `local:${slugId(file.name)}`,
    title,
    system: system.id,
    core: system.core,
    name: file.name,
    data: await file.arrayBuffer(),
  });
  await persistStorage();
  location.href = "play.html?local=1";
}

fileInput.addEventListener("change", () => {
  const file = fileInput.files?.[0];
  fileInput.value = "";
  if (!file) return;
  const system = systemFromPath(file.name);
  if (!system || system.bundled === false) {
    pendingFile = file;
    pickerLead.textContent = system
      ? "Это ядро не встроено. Можно попробовать как"
      : "Не узналась приставка для";
    pickerName.textContent = file.name;
    picker.hidden = false;
    return;
  }
  void startLocal(file, system);
});

pickerGo.addEventListener("click", () => {
  const system = systemById(pickerSystem.value);
  if (!pendingFile || !system) return;
  picker.hidden = true;
  void startLocal(pendingFile, system);
});

search.addEventListener("input", () => {
  query = search.value.trim().toLowerCase();
  render();
});

watchGamepad((next) => {
  pad.classList.toggle("on", Boolean(next));
  padName.textContent = next ? describePad(next) : "Геймпад";
});

let libraryReady = false;
try {
  const response = await fetch(new URL("roms/library.json", document.baseURI));
  if (!response.ok) throw new Error(String(response.status));
  const library = await response.json();
  games = library.games || [];
  libraryReady = true;
} catch {
  empty.hidden = false;
  empty.textContent = "Не удалось прочитать библиотеку. Открой сайт через сервер, не как файл.";
}

if (libraryReady) render();
void persistStorage();
