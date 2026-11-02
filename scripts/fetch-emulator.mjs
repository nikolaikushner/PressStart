import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const dest = path.join(root, "vendor", "emulatorjs");
const base = "https://cdn.emulatorjs.org/stable/data/";

const files = [
  "loader.js",
  "emulator.min.js",
  "emulator.min.css",
  "compression/extract7z.js",
  "compression/extractzip.js",
  "cores/reports/gambatte.json",
  "cores/reports/mgba.json",
  "cores/reports/fceumm.json",
  "cores/reports/snes9x.json",
  "cores/reports/genesis_plus_gx.json",
  "cores/reports/smsplus.json",
  "cores/gambatte-wasm.data",
  "cores/gambatte-legacy-wasm.data",
  "cores/mgba-wasm.data",
  "cores/mgba-legacy-wasm.data",
  "cores/fceumm-wasm.data",
  "cores/fceumm-legacy-wasm.data",
  "cores/snes9x-wasm.data",
  "cores/snes9x-legacy-wasm.data",
  "cores/genesis_plus_gx-wasm.data",
  "cores/genesis_plus_gx-legacy-wasm.data",
  "cores/smsplus-wasm.data",
  "cores/smsplus-legacy-wasm.data",
];

for (const file of files) {
  const target = path.join(dest, file);
  await mkdir(path.dirname(target), { recursive: true });
  const response = await fetch(base + file, { headers: { "User-Agent": "retro-games" } });
  if (!response.ok) throw new Error(`${response.status} ${file}`);
  const bytes = Buffer.from(await response.arrayBuffer());
  await writeFile(target, bytes);
  console.log(`${(bytes.length / 1024).toFixed(0)} KB  ${file}`);
}

const notice = `EmulatorJS 4.2.3
https://github.com/EmulatorJS/EmulatorJS
License: GPL-3.0-or-later

The files in this folder are the EmulatorJS runtime and the RetroArch cores it loads
for Game Boy, Game Boy Color, Game Boy Advance, NES, SNES, Mega Drive, Master System
and Game Gear. Each core keeps the license it was released under upstream.
`;
await writeFile(path.join(dest, "NOTICE"), notice);
console.log("Ядра лежат в vendor/emulatorjs");
