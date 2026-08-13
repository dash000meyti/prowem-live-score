"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { apiGetPaginated } from "@/shared/api/browser";
import type { EventCard } from "@/shared/api/types";
import { Badge } from "@/shared/ui/badge";
import { GlassCard } from "@/shared/ui/card";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";
import { ErrorBanner } from "@/shared/ui/error-banner";

export function EventsBoard() {
  const events = useQuery({
    queryKey: ["events"],
    queryFn: () => apiGetPaginated<EventCard>("/events?per_page=50"),
  });

  if (events.isError) {
    return <ErrorBanner error={events.error} />;
  }

  const items = events.data?.data ?? [];

  return (
    <div>
      <PageHeader
        eyebrow="Your calendar"
        title="Events"
        description="Track setup, readiness and match-day status for every tournament."
      />
      {items.length === 0 && !events.isLoading ? (
        <EmptyState title="No events yet" description="When a tournament is scheduled, it will appear here." />
      ) : (
        <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {items.map((event) => (
            <Link key={event.id} href={`/events/${event.id}`} className="block h-full">
              <GlassCard
                glow={
                  event.status === "live"
                    ? "coral"
                    : event.readiness.status === "blocked"
                      ? "orange"
                      : "green"
                }
                className="flex h-full flex-col gap-4 transition hover:border-white/25"
              >
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-xs uppercase tracking-wide text-prowem-muted">
                      {event.external_reference}
                    </p>
                    <p className="mt-1 font-display text-xl font-bold uppercase tracking-wide">
                      {event.name}
                    </p>
                  </div>
                  <Badge value={event.status} />
                </div>
                <p className="text-sm text-prowem-muted">
                  {event.venue?.name ?? "No venue"} · {event.teams_count} teams ·{" "}
                  {event.fields_count} fields
                </p>
                <div className="mt-auto flex flex-wrap items-center gap-2 text-sm">
                  <Badge value={event.readiness.status} />
                  <span className="text-prowem-muted">Score {event.readiness.score}</span>
                  <span className="text-prowem-muted">
                    {event.open_incidents_count} incidents
                  </span>
                </div>
              </GlassCard>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}
