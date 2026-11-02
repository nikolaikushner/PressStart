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

export function bindPad(root, onPress) {
  root.querySelectorAll("[data-btn]").forEach((button) => {
    const index = PAD[button.dataset.btn];
    if (index == null) return;
    const down = (event) => {
      if (event.pointerType === "mouse" && event.button !== 0) return;
      event.preventDefault();
      button.classList.add("is-down");
      button.setPointerCapture?.(event.pointerId);
      onPress(index, 1);
    };
    const up = (event) => {
      if (!button.classList.contains("is-down")) return;
      event.preventDefault();
      button.classList.remove("is-down");
      onPress(index, 0);
    };
    button.addEventListener("pointerdown", down);
    button.addEventListener("pointerup", up);
    button.addEventListener("pointercancel", up);
    button.addEventListener("contextmenu", (event) => event.preventDefault());
  });
}
