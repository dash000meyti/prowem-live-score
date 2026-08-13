import { NextRequest, NextResponse } from "next/server";
import { API_INTERNAL_URL, AUTH_COOKIE } from "@/shared/config/env";

const cookieOptions = {
  httpOnly: true,
  sameSite: "lax" as const,
  secure: process.env.AUTH_COOKIE_SECURE === "true",
  path: "/",
  maxAge: 60 * 60 * 24 * 7,
};

export async function POST(request: NextRequest) {
  const contentType = request.headers.get("content-type") ?? "";
  const isJsonRequest = contentType.includes("application/json");
  const payload = isJsonRequest
    ? await request.json()
    : Object.fromEntries(await request.formData());

  let response: Response;
  try {
    response = await fetch(`${API_INTERNAL_URL}/api/v1/auth/login`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        email: payload.email,
        password: payload.password,
        device_name: "event-care-web",
      }),
    });
  } catch {
    if (!isJsonRequest) {
      return NextResponse.redirect(new URL("/login?error=service_unavailable", request.url), 303);
    }

    return NextResponse.json(
      {
        success: false,
        message: "Unable to reach the authentication service.",
        error: { code: "AUTH_SERVICE_UNAVAILABLE" },
      },
      { status: 503 },
    );
  }

  const json = await response.json().catch(() => ({
    success: false,
    message: "The authentication service returned an invalid response.",
    error: { code: "INVALID_AUTH_RESPONSE" },
  }));
  if (!response.ok || json.success !== true) {
    if (!isJsonRequest) {
      return NextResponse.redirect(new URL("/login?error=invalid_credentials", request.url), 303);
    }

    return NextResponse.json(json, { status: response.status });
  }

  const nextResponse = isJsonRequest
    ? NextResponse.json({
        success: true,
        message: json.message,
        data: json.data.user,
      })
    : NextResponse.redirect(new URL("/events", request.url), 303);
  nextResponse.cookies.set(AUTH_COOKIE, json.data.token, cookieOptions);
  return nextResponse;
}
