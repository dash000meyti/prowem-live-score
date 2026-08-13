"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { apiGet } from "@/shared/api/browser";
import { useEventLookups } from "@/shared/api/lookups";
import type { EventLookups, LiveControl } from "@/shared/api/types";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { fixtureLabel } from "@/shared/lib/labels";
import { Badge } from "@/shared/ui/badge";
import { Card, CardTitle } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { PageHeader } from "@/shared/ui/page-header";
import { EventStatusActions } from "@/features/events/status-actions";

export function LiveControlPage() {
  const params = useParams<{ eventId: string }>();
  const [error, setError] = useState<unknown>(null);
  const lookups = useEventLookups(params.eventId);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "live"],
    queryFn: () => apiGet<LiveControl>(`/events/${params.eventId}/live`),
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
      <PageHeader
        eyebrow="Match day"
        title="Live control"
        description={`${data.progress.completed}/${data.progress.total} matches complete`}
        actions={
          <div className="flex flex-wrap items-center gap-2">
            <Badge value={data.event.status} />
            <EventStatusActions
              eventId={params.eventId}
              status={data.event.status}
              onError={setError}
            />
          </div>
        }
      />
      <ErrorBanner error={error} />
      <Card>
        <CardTitle>System status</CardTitle>
        <div className="flex flex-wrap items-center gap-2">
          <Badge value={data.system_status.status} />
          <span className="text-sm text-prowem-muted">
            Score {data.system_status.score} · {data.system_status.critical_blockers_count}{" "}
            critical blockers · {data.system_status.actions_required_count} actions
          </span>
        </div>
      </Card>
      <div className="grid gap-4 md:grid-cols-3">
        <MatchList title="Live" matches={data.live_matches} lookups={lookups.data} />
        <MatchList title="Next" matches={data.next_matches} lookups={lookups.data} />
        <MatchList title="Delayed" matches={data.delayed_matches} lookups={lookups.data} />
      </div>
      <Card>
        <CardTitle>Operational incidents</CardTitle>
        <ul className="space-y-2 text-sm">
          {data.operational_incidents.map((incident) => (
            <li key={incident.id}>
              <Link
                className="text-prowem-coral hover:underline"
                href={`/events/${params.eventId}/incidents/${incident.id}`}
              >
                <Badge value={incident.severity} /> {incident.title}
              </Link>
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
  lookups,
}: {
  title: string;
  matches: LiveControl["live_matches"];
  lookups?: EventLookups;
}) {
  return (
    <Card>
      <CardTitle>{title}</CardTitle>
      <ul className="space-y-2 text-sm">
        {matches.map((match) => {
          const named = lookups?.fixtures.find((fixture) => fixture.id === match.id);
          return (
            <li key={match.id}>
              {named ? fixtureLabel(named) : `#${match.number}`} · {match.status}
              {match.delay_minutes ? ` · +${match.delay_minutes}m` : ""}
            </li>
          );
        })}
        {matches.length === 0 ? <li className="text-prowem-muted">None.</li> : null}
      </ul>
    </Card>
  );
}
