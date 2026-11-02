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

const GB_LOGO = [0xce, 0xed, 0x66, 0x66, 0xcc, 0x0d, 0x00, 0x0b, 0x03, 0x73, 0x00, 0x83, 0x00, 0x0c, 0x00, 0x0d];
const GBA_LOGO = [0x24, 0xff, 0xae, 0x51, 0x69, 0x9a, 0xa2, 0x21, 0x3d, 0x84, 0x82, 0x0a];

function bytesAt(bytes, offset, signature) {
  if (offset < 0 || offset + signature.length > bytes.length) return false;
  for (let i = 0; i < signature.length; i += 1) {
    if (bytes[offset + i] !== signature[i]) return false;
  }
  return true;
}

function textAt(bytes, offset, length) {
  if (offset < 0 || offset + length > bytes.length) return "";
  let text = "";
  for (let i = 0; i < length; i += 1) {
    const code = bytes[offset + i];
    text += code >= 32 && code < 127 ? String.fromCharCode(code) : " ";
  }
  return text;
}

function looksLikeSnes(bytes) {
  for (const offset of [0x7fc0, 0xffc0, 0x81c0, 0x101c0]) {
    if (offset + 0x20 > bytes.length) continue;
    const complement = bytes[offset + 0x1c] | (bytes[offset + 0x1d] << 8);
    const checksum = bytes[offset + 0x1e] | (bytes[offset + 0x1f] << 8);
    if ((complement ^ checksum) === 0xffff && checksum !== 0 && checksum !== 0xffff) return true;
  }
  return false;
}

function looksLikeSms(bytes) {
  for (const offset of [0x7ff0, 0x3ff0, 0x1ff0]) {
    if (textAt(bytes, offset, 8) !== "TMR SEGA") continue;
    const kind = bytes[offset + 0x0f] >> 4;
    return kind >= 5 ? "segaGG" : "segaMS";
  }
  return "";
}

function zipInnerName(bytes) {
  if (!bytesAt(bytes, 0, [0x50, 0x4b, 0x03, 0x04])) return "";
  const nameLength = bytes[26] | (bytes[27] << 8);
  return textAt(bytes, 30, nameLength).trim();
}

function detectFromBytes(bytes) {
  if (bytesAt(bytes, 0, [0x4e, 0x45, 0x53, 0x1a])) return systemById("nes");
  if (
    bytesAt(bytes, 0, [0x80, 0x37, 0x12, 0x40])
    || bytesAt(bytes, 0, [0x37, 0x80, 0x40, 0x12])
    || bytesAt(bytes, 0, [0x40, 0x12, 0x37, 0x80])
  ) return systemById("n64");
  if (bytesAt(bytes, 0x04, GBA_LOGO)) return systemById("gba");
  if (bytesAt(bytes, 0x104, GB_LOGO)) {
    const flag = bytes[0x143];
    return systemById(flag === 0x80 || flag === 0xc0 ? "gbc" : "gb");
  }
  if (textAt(bytes, 0x100, 4) === "SEGA") return systemById("segaMD");
  const sms = looksLikeSms(bytes);
  if (sms) return systemById(sms);
  if (looksLikeSnes(bytes)) return systemById("snes");
  return null;
}

export function detectSystem(data, filename = "") {
  const bytes = data instanceof Uint8Array ? data : new Uint8Array(data || []);
  const fromBytes = detectFromBytes(bytes);
  if (fromBytes) return fromBytes;
  const inner = zipInnerName(bytes);
  return systemFromPath(inner || filename);
}

export function romFilename(filename, system) {
  const extension = system?.extensions?.[0] || "rom";
  const cleaned = String(filename || "game").replace(/(\.(heic|jpg|jpeg|png|webp|gif))+$/i, "");
  const stem = cleaned.replace(/\.[^.]+$/, "") || "game";
  return `${stem}.${extension}`;
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
  let name = String(filename).replace(/(\.(heic|jpg|jpeg|png|webp|gif))+(?=\.|$)/gi, "");
  name = name.replace(/\.[^.]+$/, "");
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
  if (size < 1024) return `${size} B`;
  if (size < 1024 * 1024) return `${Math.max(1, Math.round(size / 1024))} KB`;
  const mb = size / (1024 * 1024);
  return `${mb >= 10 ? mb.toFixed(0) : mb.toFixed(1)} MB`;
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
