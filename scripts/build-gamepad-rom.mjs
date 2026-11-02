import { mkdir, writeFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

function buildPrg() {
  const origin = 0xc000;
  const bytes = [];
  const labels = new Map();
  const fixups = [];

  const emit = (...values) => {
    for (const value of values) bytes.push(value & 0xff);
  };
  const label = (name) => labels.set(name, origin + bytes.length);
  const abs = (opcode, address) => emit(opcode, address & 255, address >> 8);
  const rel = (opcode, name) => {
    emit(opcode);
    const at = bytes.length;
    emit(0);
    fixups.push({ at, name, from: origin + bytes.length });
  };

  label("reset");
  emit(0x78, 0xd8);
  emit(0xa2, 0x40);
  abs(0x8e, 0x4017);
  emit(0xa2, 0xff, 0x9a, 0xe8);
  emit(0xa9, 0x00);
  abs(0x8d, 0x2000);
  abs(0x8d, 0x2001);
  abs(0x8d, 0x4010);
  abs(0x2c, 0x2002);
  label("wait1");
  abs(0x2c, 0x2002);
  rel(0x10, "wait1");
  emit(0xa2, 0x00);
  label("clrmem");
  emit(0x95, 0x00);
  abs(0x9d, 0x0100);
  abs(0x9d, 0x0200);
  abs(0x9d, 0x0300);
  abs(0x9d, 0x0400);
  abs(0x9d, 0x0500);
  abs(0x9d, 0x0600);
  abs(0x9d, 0x0700);
  emit(0xe8);
  rel(0xd0, "clrmem");
  label("wait2");
  abs(0x2c, 0x2002);
  rel(0x10, "wait2");

  emit(0xa9, 0x3f);
  abs(0x8d, 0x2006);
  emit(0xa9, 0x00);
  abs(0x8d, 0x2006);
  emit(0xa9, 0x0f);
  abs(0x8d, 0x2007);
  emit(0xa9, 0x80);
  abs(0x8d, 0x2000);
  emit(0xa9, 0x0a);
  abs(0x8d, 0x2001);
  label("forever");
  emit(0x4c);
  fixups.push({ at: bytes.length, name: "forever", type: "abs" });
  emit(0, 0);

  label("nmi");
  emit(0xa9, 0x01);
  abs(0x8d, 0x4016);
  emit(0xa9, 0x00);
  abs(0x8d, 0x4016);
  emit(0xa9, 0x0f, 0x85, 0x10);

  // Later buttons win, so press one at a time. Order is the NES latch order.
  const colors = [0x30, 0x24, 0x16, 0x2c, 0x1a, 0x28, 0x12, 0x27];
  for (const color of colors) {
    abs(0xad, 0x4016);
    emit(0x29, 0x01, 0xf0, 0x04, 0xa9, color, 0x85, 0x10);
  }

  emit(0xa9, 0x3f);
  abs(0x8d, 0x2006);
  emit(0xa9, 0x00);
  abs(0x8d, 0x2006);
  emit(0xa5, 0x10);
  abs(0x8d, 0x2007);
  emit(0xa9, 0x00);
  abs(0x8d, 0x2006);
  abs(0x8d, 0x2006);
  abs(0x8d, 0x2005);
  abs(0x8d, 0x2005);
  emit(0x40);

  label("irq");
  emit(0x40);

  for (const fix of fixups) {
    const target = labels.get(fix.name);
    if (target == null) throw new Error(`Нет метки ${fix.name}`);
    if (fix.type === "abs") {
      bytes[fix.at] = target & 255;
      bytes[fix.at + 1] = (target >> 8) & 255;
      continue;
    }
    const delta = target - fix.from;
    if (delta < -128 || delta > 127) throw new Error(`Ветка ${fix.name} слишком далеко: ${delta}`);
    bytes[fix.at] = delta & 255;
  }

  if (bytes.length > 16384 - 6) throw new Error(`PRG слишком большой: ${bytes.length}`);

  const prg = Buffer.alloc(16384, 0xff);
  Buffer.from(bytes).copy(prg);
  const putVector = (offset, name) => {
    const address = labels.get(name);
    prg[offset] = address & 255;
    prg[offset + 1] = (address >> 8) & 255;
  };
  putVector(0x3ffa, "nmi");
  putVector(0x3ffc, "reset");
  putVector(0x3ffe, "irq");

  const reset = labels.get("reset") - origin;
  const nmi = labels.get("nmi") - origin;
  if (prg[reset] !== 0x78) throw new Error("Reset не начинается с SEI");
  if (prg[nmi] !== 0xa9) throw new Error("NMI не начинается с LDA");
  return prg;
}

const header = Buffer.from([
  0x4e, 0x45, 0x53, 0x1a,
  0x01, 0x01, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00,
  0x00, 0x00, 0x00, 0x00,
]);
const rom = Buffer.concat([header, buildPrg(), Buffer.alloc(8192, 0)]);
const destination = path.join(root, "roms", "nes", "gamepad-test.nes");
await mkdir(path.dirname(destination), { recursive: true });
await writeFile(destination, rom);
console.log(`Записан ${destination} (${rom.length} байт)`);
