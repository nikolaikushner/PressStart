export const PAD = {
  b: 0,
  y: 1,
  select: 2,
  start: 3,
  up: 4,
  down: 5,
  left: 6,
  right: 7,
  a: 8,
  x: 9,
  l: 10,
  r: 11,
};

const HOLD_MS = 90;

export function bindPad(root, onPress) {
  root.querySelectorAll("[data-btn]").forEach((button) => {
    const index = PAD[button.dataset.btn];
    if (index == null) return;
    let pressedAt = 0;
    let releaseTimer = 0;
    const down = (event) => {
      if (event.pointerType === "mouse" && event.button !== 0) return;
      event.preventDefault();
      window.clearTimeout(releaseTimer);
      button.classList.add("is-down");
      button.setPointerCapture?.(event.pointerId);
      pressedAt = performance.now();
      onPress(index, 1);
    };
    const up = (event) => {
      if (!button.classList.contains("is-down")) return;
      event.preventDefault();
      const wait = Math.max(0, HOLD_MS - (performance.now() - pressedAt));
      window.clearTimeout(releaseTimer);
      releaseTimer = window.setTimeout(() => {
        button.classList.remove("is-down");
        onPress(index, 0);
      }, wait);
    };
    button.addEventListener("pointerdown", down);
    button.addEventListener("pointerup", up);
    button.addEventListener("pointercancel", up);
    button.addEventListener("contextmenu", (event) => event.preventDefault());
    button.addEventListener("selectstart", (event) => event.preventDefault());
  });
}
