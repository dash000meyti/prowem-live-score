import { NextRequest, NextResponse } from "next/server";
import { API_INTERNAL_URL, AUTH_COOKIE } from "@/shared/config/env";

export async function POST(request: NextRequest) {
  const token = request.cookies.get(AUTH_COOKIE)?.value;
  if (token) {
    await fetch(`${API_INTERNAL_URL}/api/v1/auth/logout`, {
      method: "POST",
      headers: {
        Accept: "application/json",
        Authorization: `Bearer ${token}`,
      },
    });
  }

  const response = NextResponse.json({
    success: true,
    message: "Logged out successfully.",
    data: null,
  });
  response.cookies.set(AUTH_COOKIE, "", {
    httpOnly: true,
    path: "/",
    maxAge: 0,
  });
  return response;
}
