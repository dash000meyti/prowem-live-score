"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@/shared/api/browser";
import type { CareOverview } from "@/shared/api/types";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Card, CardTitle } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { PageHeader } from "@/shared/ui/page-header";

export function EventHome() {
  const params = useParams<{ eventId: string }>();
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "care"],
    queryFn: () => apiGet<CareOverview>(`/events/${params.eventId}/care`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  const data = query.data;
  if (!data) {
    return <p className="text-prowem-muted">Loading event care…</p>;
  }

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow={data.event.external_reference ?? "Event hub"}
        title={data.event.name}
        description={`${data.event.venue?.name ?? "No venue"} · ${data.event.team_count ?? 0} teams`}
        actions={
          <div className="flex gap-2">
            <Badge value={data.event.status} />
            <Badge value={data.readiness.status} />
          </div>
        }
      />

      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardTitle>Readiness</CardTitle>
          <p className="font-display text-4xl font-bold">{data.readiness.score}</p>
          <p className="text-sm text-prowem-muted">
            {data.readiness.critical_blockers_count} critical blockers ·{" "}
            {data.readiness.actions_required_count} actions
          </p>
        </Card>
        <Card>
          <CardTitle>Needs attention</CardTitle>
          <ul className="space-y-2 text-sm">
            {data.needs_attention.map((item) => (
              <li key={item.id}>
                <Badge value={item.status} /> {item.message ?? item.check_type}
              </li>
            ))}
            {data.needs_attention.length === 0 ? (
              <li className="text-prowem-muted">Nothing blocked.</li>
            ) : null}
          </ul>
        </Card>
        <Card>
          <CardTitle>Next matches</CardTitle>
          <ul className="space-y-2 text-sm">
            {data.next_matches.map((match) => (
              <li key={match.id}>
                #{match.number} · {match.field ?? "TBC"} · {match.status}
              </li>
            ))}
            {data.next_matches.length === 0 ? (
              <li className="text-prowem-muted">No upcoming matches.</li>
            ) : null}
          </ul>
        </Card>
      </div>

      <div className="grid gap-4 md:grid-cols-2">
        <Card>
          <CardTitle>Critical incidents</CardTitle>
          <ul className="space-y-2 text-sm">
            {data.open_critical_incidents.map((incident) => (
              <li key={incident.id}>
                <Link className="text-prowem-coral hover:underline" href={`/events/${params.eventId}/incidents/${incident.id}`}>
                  {incident.title}
                </Link>
              </li>
            ))}
            {data.open_critical_incidents.length === 0 ? (
              <li className="text-prowem-muted">None open.</li>
            ) : null}
          </ul>
        </Card>
        <Card>
          <CardTitle>Open tickets</CardTitle>
          <ul className="space-y-2 text-sm">
            {data.open_tickets.map((ticket) => (
              <li key={ticket.id}>
                <Link className="text-prowem-coral hover:underline" href={`/events/${params.eventId}/tickets/${ticket.id}`}>
                  {ticket.reference} · {ticket.subject}
                </Link>
                <Badge className="ml-2" value={ticket.sla_status} />
              </li>
            ))}
            {data.open_tickets.length === 0 ? (
              <li className="text-prowem-muted">None open.</li>
            ) : null}
          </ul>
        </Card>
      </div>
    </div>
  );
}
