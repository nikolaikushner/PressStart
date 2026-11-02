const DB_NAME = "retro-cabinet";
const STORE = "kv";

function openDb() {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, 1);
    request.onupgradeneeded = () => {
      const db = request.result;
      if (!db.objectStoreNames.contains(STORE)) db.createObjectStore(STORE);
    };
    request.onsuccess = () => resolve(request.result);
    request.onerror = () => reject(request.error);
  });
}

export async function kvGet(key) {
  const db = await openDb();
  try {
    return await new Promise((resolve, reject) => {
      const request = db.transaction(STORE, "readonly").objectStore(STORE).get(key);
      request.onsuccess = () => resolve(request.result);
      request.onerror = () => reject(request.error);
    });
  } finally {
    db.close();
  }
}

export async function kvSet(key, value) {
  const db = await openDb();
  try {
    await new Promise((resolve, reject) => {
      const tx = db.transaction(STORE, "readwrite");
      tx.objectStore(STORE).put(value, key);
      tx.oncomplete = () => resolve();
      tx.onerror = () => reject(tx.error);
      tx.onabort = () => reject(tx.error);
    });
  } finally {
    db.close();
  }
}

export async function persistStorage() {
  try {
    if (!navigator.storage?.persist) return false;
    return await navigator.storage.persist();
  } catch {
    return false;
  }
}

const META_KEY = "retro-save-meta";

export function readSaveMeta() {
  try {
    return JSON.parse(localStorage.getItem(META_KEY) || "{}");
  } catch {
    return {};
  }
}

export function writeSaveMeta(gameKey, savedAt) {
  try {
    const meta = readSaveMeta();
    meta[gameKey] = savedAt;
    localStorage.setItem(META_KEY, JSON.stringify(meta));
  } catch {
    // Private mode can reject localStorage. The save itself still lives in IndexedDB.
  }
}

export function stateKey(gameKey) {
  return `state:${gameKey}`;
}
