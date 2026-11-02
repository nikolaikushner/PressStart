export function padLabel(pad) {
  const raw = (pad?.id || "Gamepad").replace(/\s*\([^)]*\)\s*/g, " ");
  const name = raw.replace(/\s+/g, " ").trim();
  return name || "Gamepad";
}

export function connectedPad() {
  if (!navigator.getGamepads) return null;
  return [...navigator.getGamepads()].find(Boolean) || null;
}

export function watchGamepad(onChange) {
  const read = () => onChange(connectedPad());
  window.addEventListener("gamepadconnected", read);
  window.addEventListener("gamepaddisconnected", read);
  window.addEventListener("pointerdown", read);
  window.addEventListener("keydown", read);
  const timer = window.setInterval(read, 1000);
  read();
  return () => {
    window.clearInterval(timer);
    window.removeEventListener("gamepadconnected", read);
    window.removeEventListener("gamepaddisconnected", read);
    window.removeEventListener("pointerdown", read);
    window.removeEventListener("keydown", read);
  };
}

export function describePad(pad) {
  if (!navigator.getGamepads) return "This browser cannot see gamepads";
  if (!pad) return "Press a button on the GameSir";
  return padLabel(pad);
}

// Standard gamepad index → emulator button. Face buttons follow the letter, so A is A.
const BUTTONS = [
  [0, 8],
  [1, 0],
  [2, 9],
  [3, 1],
  [4, 10],
  [5, 11],
  [8, 2],
  [9, 3],
  [12, 4],
  [13, 5],
  [14, 6],
  [15, 7],
];

const LATCH_MS = 80;

export function driveGamepad(onButton) {
  const latched = new Map();
  let down = new Set();
  let frame = 0;
  const tick = () => {
    frame = requestAnimationFrame(tick);
    const pads = navigator.getGamepads ? navigator.getGamepads() : [];
    const next = new Set();
    for (const pad of pads) {
      if (!pad) continue;
      for (const [from, to] of BUTTONS) {
        const button = pad.buttons[from];
        if (button && (button.pressed || button.value > 0.5)) next.add(to);
      }
      const x = pad.axes?.[0] || 0;
      const y = pad.axes?.[1] || 0;
      if (x < -0.55) next.add(6);
      if (x > 0.55) next.add(7);
      if (y < -0.55) next.add(4);
      if (y > 0.55) next.add(5);
    }
    const now = performance.now();
    for (const index of next) latched.set(index, now + LATCH_MS);
    for (const [index, until] of latched) {
      if (now > until && !next.has(index)) latched.delete(index);
    }
    const active = new Set([...next, ...latched.keys()]);
    for (const index of active) {
      if (!down.has(index)) onButton(index, 1);
    }
    for (const index of down) {
      if (!active.has(index)) onButton(index, 0);
    }
    // Keep a short tap held across the emulator's own slower poll.
    if (active.size) {
      for (const index of active) onButton(index, 1);
    }
    down = active;
  };
  frame = requestAnimationFrame(tick);
  return () => cancelAnimationFrame(frame);
}
