import { NextRequest, NextResponse } from "next/server";
import { API_INTERNAL_URL, AUTH_COOKIE } from "@/shared/config/env";

async function proxy(
  request: NextRequest,
  context: { params: Promise<{ path: string[] }> },
) {
  const { path } = await context.params;
  const token = request.cookies.get(AUTH_COOKIE)?.value;
  const target = `${API_INTERNAL_URL}/api/v1/${path.join("/")}${request.nextUrl.search}`;
  const headers = new Headers();
  const contentType = request.headers.get("content-type");
  if (contentType) {
    headers.set("content-type", contentType);
  }
  headers.set("accept", request.headers.get("accept") ?? "application/json");
  if (token) {
    headers.set("authorization", `Bearer ${token}`);
  }

  const method = request.method;
  const body =
    method === "GET" || method === "HEAD" ? undefined : await request.arrayBuffer();

  const upstream = await fetch(target, { method, headers, body });
  const responseHeaders = new Headers();
  const upstreamType = upstream.headers.get("content-type");
  if (upstreamType) {
    responseHeaders.set("content-type", upstreamType);
  }

  return new NextResponse(upstream.body, {
    status: upstream.status,
    headers: responseHeaders,
  });
}

export const GET = proxy;
export const POST = proxy;
export const PATCH = proxy;
export const PUT = proxy;
export const DELETE = proxy;
