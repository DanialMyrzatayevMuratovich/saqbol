import { apiPrefix } from "./config";
import {
  clearTokens,
  getAccessToken,
  getRefreshToken,
  saveTokens,
} from "./auth";
import type { AdminMessage, ModelVersion, Overview } from "./types";

export class UnauthorizedError extends Error {}

async function refreshTokens(): Promise<boolean> {
  const refresh = getRefreshToken();
  if (!refresh) return false;

  const response = await fetch(`${apiPrefix}/auth/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refresh_token: refresh }),
  });

  if (!response.ok) {
    clearTokens();
    return false;
  }

  const data = await response.json();
  saveTokens(data.access_token, data.refresh_token);
  return true;
}

async function authorizedFetch(path: string, init: RequestInit = {}, retry = true): Promise<Response> {
  const token = getAccessToken();
  const headers = new Headers(init.headers);
  if (token) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  const response = await fetch(`${apiPrefix}${path}`, { ...init, headers });

  if (response.status === 401 && retry && (await refreshTokens())) {
    return authorizedFetch(path, init, false);
  }
  return response;
}

export async function login(phone: string, password: string): Promise<void> {
  const response = await fetch(`${apiPrefix}/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ phone, password }),
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error ?? "Не удалось войти");
  }

  const data = await response.json();
  saveTokens(data.access_token, data.refresh_token);
}

async function getJson<T>(path: string, errorMessage: string): Promise<T> {
  const response = await authorizedFetch(path);
  if (response.status === 401) {
    throw new UnauthorizedError();
  }
  if (!response.ok) {
    throw new Error(errorMessage);
  }
  return response.json();
}

export async function fetchMetrics(): Promise<Overview> {
  return getJson<Overview>("/admin/metrics", "Не удалось загрузить метрики");
}

export async function fetchFlaggedMessages(verdict = ""): Promise<AdminMessage[]> {
  const query = verdict ? `&verdict=${encodeURIComponent(verdict)}` : "";
  const data = await getJson<{ items: AdminMessage[] }>(
    `/admin/messages?limit=100${query}`,
    "Не удалось загрузить сообщения",
  );
  return data.items;
}

export async function fetchModelVersions(): Promise<ModelVersion[]> {
  const data = await getJson<{ items: ModelVersion[] }>(
    "/admin/model-versions",
    "Не удалось загрузить версии модели",
  );
  return data.items;
}

export async function createModelVersion(name: string, metrics: string): Promise<void> {
  const response = await authorizedFetch("/admin/model-versions", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ name, metrics }),
  });
  if (response.status === 401) {
    throw new UnauthorizedError();
  }
  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error ?? "Не удалось создать версию модели");
  }
}
