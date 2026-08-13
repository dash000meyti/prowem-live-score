"use client";

import { ApiError, parseApiResponse, parsePaginated } from "@/shared/api/client";
import type { Paginated } from "@/shared/api/types";

async function browserFetch(path: string, init: RequestInit = {}) {
  const headers = new Headers(init.headers);
  if (!headers.has("Accept")) {
    headers.set("Accept", "application/json");
  }
  if (init.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  return fetch(`/api/v1${path}`, {
    ...init,
    headers,
    credentials: "include",
  });
}

export async function apiGet<T>(path: string): Promise<T> {
  return parseApiResponse<T>(await browserFetch(path));
}

export async function apiGetPaginated<T>(path: string): Promise<Paginated<T>> {
  return parsePaginated<T>(await browserFetch(path));
}

export async function apiSend<T>(
  path: string,
  method: string,
  body?: unknown,
): Promise<T> {
  const response = await browserFetch(path, {
    method,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  return parseApiResponse<T>(response);
}

export { ApiError };
