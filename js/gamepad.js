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
