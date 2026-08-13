"use client";

import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiSend } from "@/shared/api/browser";
import type { EventStatus, LiveControl } from "@/shared/api/types";
import { useSession } from "@/shared/auth/session-context";
import { canManage } from "@/shared/auth/roles";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card, CardTitle } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { useState } from "react";

const transitions: Record<string, EventStatus[]> = {
  preparing: ["ready", "cancelled"],
  ready: ["preparing", "live", "cancelled"],
  live: ["completed", "cancelled"],
  completed: [],
  cancelled: [],
};

export function LiveControlPage() {
  const params = useParams<{ eventId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "live"],
    queryFn: () => apiGet<LiveControl>(`/events/${params.eventId}/live`),
  });

  const transition = useMutation({
    mutationFn: (status: EventStatus) =>
      apiSend(`/events/${params.eventId}/status`, "PATCH", { status }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }
  const data = query.data;
  if (!data) {
    return <p>Loading live control…</p>;
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center justify-between gap-3">
        <div className="flex items-center gap-3">
          <h1 className="font-display text-3xl font-bold uppercase">Live control</h1>
          <Badge value={data.event.status} />
          <span className="text-sm text-prowem-muted">
            {data.progress.completed}/{data.progress.total} matches complete
          </span>
        </div>
        {canManage(user.role) ? (
          <div className="flex gap-2">
            {transitions[data.event.status].map((status) => (
              <Button
                key={status}
                type="button"
                variant={status === "live" ? "primary" : "secondary"}
                onClick={() => transition.mutate(status)}
              >
                {status === "live" ? "Start event" : status}
              </Button>
            ))}
          </div>
        ) : null}
      </div>
      <ErrorBanner error={error} />
      <div className="grid gap-4 md:grid-cols-3">
        <MatchList title="Live" matches={data.live_matches} />
        <MatchList title="Next" matches={data.next_matches} />
        <MatchList title="Delayed" matches={data.delayed_matches} />
      </div>
      <Card>
        <CardTitle>Operational incidents</CardTitle>
        <ul className="space-y-2 text-sm">
          {data.operational_incidents.map((incident) => (
            <li key={incident.id}>
              <Badge value={incident.severity} /> {incident.title}
            </li>
          ))}
          {data.operational_incidents.length === 0 ? (
            <li className="text-prowem-muted">None open.</li>
          ) : null}
        </ul>
      </Card>
    </div>
  );
}

function MatchList({
  title,
  matches,
}: {
  title: string;
  matches: LiveControl["live_matches"];
}) {
  return (
    <Card>
      <CardTitle>{title}</CardTitle>
      <ul className="space-y-2 text-sm">
        {matches.map((match) => (
          <li key={match.id}>
            #{match.number} · {match.status}
            {match.delay_minutes ? ` · +${match.delay_minutes}m` : ""}
          </li>
        ))}
        {matches.length === 0 ? <li className="text-prowem-muted">None.</li> : null}
      </ul>
    </Card>
  );
}
