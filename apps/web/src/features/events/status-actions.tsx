"use client";

import { useMutation, useQueryClient } from "@tanstack/react-query";
import { apiSend } from "@/shared/api/browser";
import type { EventStatus } from "@/shared/api/types";
import { eventStatusLabel } from "@/shared/domain/enums";
import { canManage } from "@/shared/auth/roles";
import { useSession } from "@/shared/auth/session-context";
import { Button } from "@/shared/ui/button";
import { ConfirmationDialog } from "@/shared/ui/confirmation-dialog";
import { useState } from "react";

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
  const [selected, setSelected] = useState<EventStatus | null>(null);
  const queryClient = useQueryClient();
  const transition = useMutation({
    mutationFn: (next: EventStatus) =>
      apiSend(`/events/${eventId}/status`, "PATCH", { status: next }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", eventId] });
      queryClient.invalidateQueries({ queryKey: ["events"] });
      onError(null);
      setSelected(null);
    },
    onError,
  });

  if (!canManage(user.role)) {
    return null;
  }

  const options: EventStatus[] = status === "preparing" ? ["ready"] : status === "ready" ? ["live"] : status === "live" ? ["completed"] : [];
  if (options.length === 0) {
    return null;
  }

  return (
    <>
    <div className="flex flex-wrap gap-2">
      {options.map((next) => (
        <Button
          key={next}
          type="button"
          variant={next === "live" ? "primary" : "secondary"}
          disabled={transition.isPending}
          onClick={() => setSelected(next)}
        >
          {next === "ready" ? "Confirm ready" : next === "live" ? "Start event" : eventStatusLabel(next)}
        </Button>
      ))}
    </div>
    <ConfirmationDialog
      open={selected !== null}
      title={selected === "ready" ? "Confirm Event ready?" : selected === "live" ? "Start event?" : `Move event to ${selected ? eventStatusLabel(selected) : "next status"}?`}
      description={selected === "ready" ? "All readiness checks are complete. Confirm that the Event is ready for kickoff." : selected === "live" ? "The Event will move to Live mode. Confirm only when match-day operations are ready." : "The Event will be marked completed and its Event Care report will remain available."}
      confirmLabel={selected === "ready" ? "Confirm ready" : selected === "live" ? "Start event" : "Confirm transition"}
      pending={transition.isPending}
      destructive={selected === "cancelled"}
      onCancel={() => setSelected(null)}
      onConfirm={() => { if (selected) transition.mutate(selected); }}
    />
    </>
  );
}
