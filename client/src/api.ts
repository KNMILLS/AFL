/**
 * Small helper to pick the correct API base.
 * - In Tauri (desktop): backend sidecar listens on 127.0.0.1:8787
 * - In web/dev server mode: uvicorn listens on 127.0.0.1:8000
 */
export const API_BASE =
  (window as any).__TAURI_IPC__ ? "http://127.0.0.1:8787/api" : "http://127.0.0.1:8000/api";

export async function apiGet<T>(path: string): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`);
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json() as Promise<T>;
}

export async function apiPost<T>(path: string, body?: any): Promise<T> {
  const res = await fetch(`${API_BASE}${path}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: body ? JSON.stringify(body) : undefined,
  });
  if (!res.ok) throw new Error(`${res.status} ${res.statusText}`);
  return res.json() as Promise<T>;
}
