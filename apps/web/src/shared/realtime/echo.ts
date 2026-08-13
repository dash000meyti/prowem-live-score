"use client";

import Echo from "laravel-echo";
import Pusher from "pusher-js";

let echo: Echo<"reverb"> | null = null;

export function getEcho() {
  if (typeof window === "undefined") {
    return null;
  }

  if (!echo) {
    window.Pusher = Pusher;
    echo = new Echo({
      broadcaster: "reverb",
      key: process.env.NEXT_PUBLIC_REVERB_APP_KEY ?? "event-care-key",
      wsHost: process.env.NEXT_PUBLIC_REVERB_HOST ?? "127.0.0.1",
      wsPort: Number(process.env.NEXT_PUBLIC_REVERB_PORT ?? 18091),
      wssPort: Number(process.env.NEXT_PUBLIC_REVERB_PORT ?? 18091),
      forceTLS: process.env.NEXT_PUBLIC_REVERB_SCHEME === "https",
      enabledTransports: ["ws", "wss"],
      authEndpoint: "/api/v1/broadcasting/auth",
      authorizer: (channel) => ({
        authorize: (socketId, callback) => {
          fetch("/api/v1/broadcasting/auth", {
            method: "POST",
            credentials: "include",
            headers: {
              Accept: "application/json",
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: new URLSearchParams({
              socket_id: socketId,
              channel_name: channel.name,
            }),
          })
            .then(async (response) => {
              const data = await response.json();
              if (!response.ok) {
                callback(data, null);
                return;
              }
              callback(null, data);
            })
            .catch((error: Error) => callback(error, null));
        },
      }),
    });
  }

  return echo;
}

declare global {
  interface Window {
    Pusher: typeof Pusher;
  }
}
