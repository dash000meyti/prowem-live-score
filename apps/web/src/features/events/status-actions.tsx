"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiSend } from "@/shared/api/browser";
import type { EventStatus } from "@/shared/api/types";
import { EVENT_TRANSITIONS, eventStatusLabel } from "@/shared/domain/enums";
import { canManage } from "@/shared/auth/roles";
import { useSession } from "@/shared/auth/session-context";
import { Button } from "@/shared/ui/button";

export function EventStatusActions({
  eventId,
  status,
  onError,
}: {
  eventId: string;
  status: EventStatus;
  onError: (error: unknown) => void;
}) {
  const user = useSession();
  const queryClient = useQueryClient();
  const transition = useMutation({
    mutationFn: (next: EventStatus) =>
      apiSend(`/events/${eventId}/status`, "PATCH", { status: next }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", eventId] });
      queryClient.invalidateQueries({ queryKey: ["events"] });
      onError(null);
    },
    onError,
  });

  if (!canManage(user.role)) {
    return null;
  }

  const options = EVENT_TRANSITIONS[status];
  if (options.length === 0) {
    return null;
  }

  return (
    <div className="flex flex-wrap gap-2">
      {options.map((next) => (
        <Button
          key={next}
          type="button"
          variant={next === "live" ? "primary" : "secondary"}
          disabled={transition.isPending}
          onClick={() => transition.mutate(next)}
        >
          {eventStatusLabel(next)}
        </Button>
      ))}
    </div>
  );
}
