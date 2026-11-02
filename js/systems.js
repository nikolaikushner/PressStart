export const SYSTEMS = [
  { id: "gba", core: "gba", label: "Game Boy Advance", short: "GBA", skin: "advance", bundled: true, folders: ["gba"], extensions: ["gba"] },
  { id: "gbc", core: "gb", label: "Game Boy Color", short: "GBC", skin: "pocket", bundled: true, folders: ["gbc"], extensions: ["gbc"] },
  { id: "gb", core: "gb", label: "Game Boy", short: "GB", skin: "pocket", bundled: true, folders: ["gb", "gameboy"], extensions: ["gb"] },
  { id: "nes", core: "nes", label: "NES", short: "NES", skin: "pocket", bundled: true, folders: ["nes", "famicom"], extensions: ["nes", "unf", "unif", "fds"] },
  { id: "snes", core: "snes", label: "SNES", short: "SNES", skin: "advance", bundled: true, folders: ["snes", "sfc"], extensions: ["sfc", "smc", "fig"] },
  { id: "segaMD", core: "segaMD", label: "Mega Drive", short: "MD", skin: "advance", bundled: true, folders: ["genesis", "megadrive", "md"], extensions: ["md", "gen", "smd"] },
  { id: "segaMS", core: "segaMS", label: "Master System", short: "SMS", skin: "advance", bundled: true, folders: ["mastersystem", "sms"], extensions: ["sms"] },
  { id: "segaGG", core: "segaGG", label: "Game Gear", short: "GG", skin: "pocket", bundled: true, folders: ["gamegear", "gg"], extensions: ["gg"] },
  { id: "segaCD", core: "segaCD", label: "Sega CD", short: "SCD", skin: "advance", bundled: true, folders: ["segacd", "megacd"], extensions: ["chd"] },
  { id: "n64", core: "n64", label: "Nintendo 64", short: "N64", skin: "advance", bundled: false, folders: ["n64"], extensions: ["z64", "n64", "v64"] },
  { id: "nds", core: "nds", label: "Nintendo DS", short: "DS", skin: "advance", bundled: false, folders: ["nds", "ds"], extensions: ["nds"] },
  { id: "psx", core: "psx", label: "PlayStation", short: "PS1", skin: "advance", bundled: false, folders: ["psx", "ps1", "playstation"], extensions: ["cue", "pbp"] },
  { id: "pce", core: "pce", label: "PC Engine", short: "PCE", skin: "advance", bundled: false, folders: ["pce", "tg16"], extensions: ["pce"] },
  { id: "ngp", core: "ngp", label: "Neo Geo Pocket", short: "NGP", skin: "pocket", bundled: false, folders: ["ngp"], extensions: ["ngp", "ngc"] },
  { id: "ws", core: "ws", label: "WonderSwan", short: "WS", skin: "pocket", bundled: false, folders: ["ws", "wonderswan"], extensions: ["ws", "wsc"] },
  { id: "atari2600", core: "atari2600", label: "Atari 2600", short: "2600", skin: "pocket", bundled: false, folders: ["atari2600", "a2600"], extensions: ["a26"] },
  { id: "lynx", core: "lynx", label: "Lynx", short: "LYNX", skin: "pocket", bundled: false, folders: ["lynx"], extensions: ["lnx"] },
];

export function skinFor(systemId) {
  return systemById(systemId)?.skin || "advance";
}

export const BIOS_FILES = {
  "gba_bios.bin": "gba",
  "scph5501.bin": "psx",
  "scph5500.bin": "psx",
  "scph5502.bin": "psx",
  "bios_CD_U.bin": "segaCD",
  "bios_CD_E.bin": "segaCD",
  "bios_CD_J.bin": "segaCD",
};

const PREFERRED_BIOS = {
  psx: "scph5501.bin",
  segaCD: "bios_CD_U.bin",
  gba: "gba_bios.bin",
};

export function extensionOf(filename) {
  const match = String(filename).toLowerCase().match(/\.([a-z0-9]+)$/);
  return match ? match[1] : "";
}

export function systemById(id) {
  return SYSTEMS.find((system) => system.id === id) || null;
}

export function systemFromPath(relativePath) {
  const parts = String(relativePath).split(/[/\\]/).filter(Boolean);
  const file = parts.at(-1) || "";
  const ext = extensionOf(file);
  const folder = parts.length > 1 ? parts[0].toLowerCase() : "";
  if (folder === "bios") return null;

  const byFolder = SYSTEMS.find((system) => system.folders.includes(folder)) || null;
  const byExt = SYSTEMS.filter((system) => system.extensions.includes(ext));

  if (ext === "zip" || ext === "7z" || ext === "bin") return byFolder;
  if (byFolder && byExt.includes(byFolder)) return byFolder;
  if (byExt.length === 1) return byExt[0];
  if (byFolder && byExt.length === 0 && byFolder.extensions.includes(ext)) return byFolder;
  if (ext === "chd") return byFolder || null;
  return byFolder && byExt.length === 0 ? null : byExt[0] || null;
}

export function prettyTitle(filename) {
  let name = String(filename).replace(/\.[^.]+$/, "");
  name = name.replace(/\s*[([].*?[)\]]/g, "");
  name = name.replace(/[._]+/g, " ");
  name = name.replace(/\s+/g, " ").trim();
  return name || filename;
}

export function slugId(relativePath) {
  const stem = String(relativePath).replace(/\.[^.]+$/, "");
  const slug = stem
    .toLowerCase()
    .replace(/[^\p{L}\p{N}]+/gu, "-")
    .replace(/^-|-$/g, "");
  return slug || "rom";
}

export function numericGameId(key) {
  let hash = 2166136261;
  const text = String(key);
  for (let i = 0; i < text.length; i += 1) {
    hash ^= text.charCodeAt(i);
    hash = Math.imul(hash, 16777619);
  }
  return (hash >>> 0) % 2147483646 + 1;
}

export function formatBytes(bytes) {
  const size = Number(bytes) || 0;
  if (size < 1024) return `${size} Б`;
  if (size < 1024 * 1024) return `${Math.max(1, Math.round(size / 1024))} КБ`;
  const mb = size / (1024 * 1024);
  return `${mb >= 10 ? mb.toFixed(0) : mb.toFixed(1)} МБ`;
}

export function acceptList() {
  const extensions = new Set(["zip"]);
  for (const system of SYSTEMS) {
    for (const ext of system.extensions) extensions.add(ext);
  }
  return [...extensions].map((ext) => `.${ext}`).join(",");
}

export function chooseBios(filesBySystem) {
  const chosen = {};
  for (const [systemId, files] of Object.entries(filesBySystem)) {
    const preferred = PREFERRED_BIOS[systemId];
    const file = files.find((name) => name === preferred) || files[0];
    if (file) chosen[systemId] = `bios/${file}`;
  }
  return chosen;
}
