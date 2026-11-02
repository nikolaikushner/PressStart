import { readdir, readFile, stat, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import {
  BIOS_FILES,
  chooseBios,
  prettyTitle,
  slugId,
  systemById,
  systemFromPath,
} from "../js/systems.js";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const romRoot = path.join(root, "roms");

async function walk(dir) {
  let entries = [];
  try {
    entries = await readdir(dir, { withFileTypes: true });
  } catch (error) {
    if (error.code === "ENOENT") return [];
    throw error;
  }
  const files = [];
  for (const entry of entries) {
    if (entry.name.startsWith(".")) continue;
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) files.push(...await walk(full));
    else if (entry.isFile()) files.push(full);
  }
  return files;
}

function relative(full) {
  return path.relative(romRoot, full).split(path.sep).join("/");
}

const skip = new Set(["library.json", "overrides.json"]);
const imageExt = new Set(["png", "jpg", "jpeg", "webp"]);
const files = await walk(romRoot);
const coverByStem = new Map();
for (const full of files) {
  const rel = relative(full);
  const ext = path.posix.extname(rel).slice(1).toLowerCase();
  if (!imageExt.has(ext)) continue;
  coverByStem.set(rel.slice(0, -(ext.length + 1)), rel);
}
let overrides = {};
try {
  overrides = JSON.parse(await readFile(path.join(romRoot, "overrides.json"), "utf8"));
} catch (error) {
  if (error.code !== "ENOENT") throw error;
}

const biosFound = {};
const games = [];
const usedIds = new Set();

for (const full of files) {
  const rel = relative(full);
  const base = path.posix.basename(rel);
  if (skip.has(base)) continue;
  if (base === ".gitkeep") continue;

  const biosSystem = rel.startsWith("bios/") ? BIOS_FILES[base.toLowerCase()] : null;
  if (biosSystem) {
    biosFound[biosSystem] ??= [];
    biosFound[biosSystem].push(base);
    continue;
  }

  const override = overrides[rel] || {};
  const system = (override.system && systemById(override.system)) || systemFromPath(rel);
  if (!system) continue;

  const info = await stat(full);
  const stem = rel.replace(/\.[^.]+$/, "");
  const cover = override.cover || coverByStem.get(stem) || "";
  const baseId = override.id || slugId(rel);
  let id = baseId;
  let suffix = 2;
  while (usedIds.has(id)) {
    id = `${baseId}-${suffix}`;
    suffix += 1;
  }
  usedIds.add(id);

  games.push({
    id,
    title: override.title || prettyTitle(base),
    blurb: override.blurb || "",
    system: system.id,
    core: override.core || system.core || system.id,
    file: rel,
    bytes: info.size,
    ...(cover ? { cover } : {}),
  });
}

games.sort((a, b) => a.title.localeCompare(b.title, "ru") || a.system.localeCompare(b.system));

const library = {
  games,
  bios: chooseBios(biosFound),
};

await writeFile(path.join(romRoot, "library.json"), `${JSON.stringify(library, null, 2)}\n`);
console.log(`Library has ${games.length} ROM${games.length === 1 ? "" : "s"}`);
