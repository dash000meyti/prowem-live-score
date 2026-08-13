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
  const payload = await request.json();
  const response = await fetch(`${API_INTERNAL_URL}/api/v1/auth/login`, {
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

  const json = await response.json();
  if (!response.ok || json.success !== true) {
    return NextResponse.json(json, { status: response.status });
  }

  const nextResponse = NextResponse.json({
    success: true,
    message: json.message,
    data: json.data.user,
  });
  nextResponse.cookies.set(AUTH_COOKIE, json.data.token, cookieOptions);
  return nextResponse;
}
