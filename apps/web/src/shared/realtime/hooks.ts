"use client";

import { useQueryClient } from "@tanstack/react-query";
import { useEffect } from "react";
import { getEcho } from "@/shared/realtime/echo";

const EVENT_NAMES = [
  "event.status.changed",
  "event.readiness.changed",
  "team.readiness.changed",
  "incident.created",
  "incident.updated",
  "incident.resolved",
  "ticket.created",
  "ticket.updated",
  "ticket.resolved",
  "ticket.message.created",
  "activity.created",
];

export function useEventRealtime(eventId: number | string | undefined) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!eventId) {
      return;
    }

    const echo = getEcho();
    if (!echo) {
      return;
    }

    const channel = echo.private(`events.${eventId}`);
    const invalidate = () => {
      queryClient.invalidateQueries({ queryKey: ["event", String(eventId)] });
      queryClient.invalidateQueries({ queryKey: ["events"] });
    };

    EVENT_NAMES.forEach((name) => {
      channel.listen(`.${name}`, invalidate);
    });

    return () => {
      EVENT_NAMES.forEach((name) => channel.stopListening(`.${name}`));
      echo.leave(`events.${eventId}`);
    };
  }, [eventId, queryClient]);
}

export function useUserRealtime(userId: number | undefined) {
  const queryClient = useQueryClient();

  useEffect(() => {
    if (!userId) {
      return;
    }

    const echo = getEcho();
    if (!echo) {
      return;
    }

    const channel = echo.private(`App.Models.User.${userId}`);
    const invalidate = () => {
      queryClient.invalidateQueries({ queryKey: ["notifications"] });
    };
    channel.notification(invalidate);
    channel.listen(".Illuminate\\Notifications\\Events\\BroadcastNotificationCreated", invalidate);

    return () => {
      echo.leave(`App.Models.User.${userId}`);
    };
  }, [userId, queryClient]);
}
