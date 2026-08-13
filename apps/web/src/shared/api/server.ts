import { cookies } from "next/headers";
import { redirect } from "next/navigation";
import { AUTH_COOKIE, API_INTERNAL_URL } from "@/shared/config/env";
import { ApiError, parseApiResponse, parsePaginated } from "@/shared/api/client";
import type { Paginated, SessionUser } from "@/shared/api/types";

async function serverFetch(path: string, init: RequestInit = {}) {
  const token = (await cookies()).get(AUTH_COOKIE)?.value;
  const headers = new Headers(init.headers);
  headers.set("Accept", "application/json");
  if (token) {
    headers.set("Authorization", `Bearer ${token}`);
  }

  return fetch(`${API_INTERNAL_URL}/api/v1${path}`, {
    ...init,
    headers,
    cache: "no-store",
  });
}

export async function apiGet<T>(path: string): Promise<T> {
  const response = await serverFetch(path);
  return parseApiResponse<T>(response);
}

export async function apiGetPaginated<T>(path: string): Promise<Paginated<T>> {
  const response = await serverFetch(path);
  return parsePaginated<T>(response);
}

export async function getSessionUser(): Promise<SessionUser | null> {
  const token = (await cookies()).get(AUTH_COOKIE)?.value;
  if (!token) {
    return null;
  }

  try {
    return await apiGet<SessionUser>("/me");
  } catch (error) {
    if (error instanceof ApiError && (error.status === 401 || error.status === 403)) {
      return null;
    }
    throw error;
  }
}

export async function requireSessionUser(): Promise<SessionUser> {
  const user = await getSessionUser();
  if (!user) {
    redirect("/login");
  }
  return user;
}
