"use client";

import Link from "next/link";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { apiGetPaginated } from "@/shared/api/browser";
import type { EventCard } from "@/shared/api/types";
import { EVENT_STATUSES, PAGE_SIZE } from "@/shared/domain/enums";
import { buildQuery } from "@/shared/lib/query";
import { Badge } from "@/shared/ui/badge";
import { GlassCard } from "@/shared/ui/card";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { FilterBar, FilterInput, FilterSelect, PaginationControls } from "@/shared/ui/filters";

export function EventsBoard() {
  const [status, setStatus] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [sort, setSort] = useState("starts_at");
  const [direction, setDirection] = useState("asc");
  const [page, setPage] = useState(1);
  const query = buildQuery({
    status,
    from,
    to,
    sort,
    direction,
    page,
    per_page: PAGE_SIZE,
  });
  const events = useQuery({
    queryKey: ["events", query],
    queryFn: () => apiGetPaginated<EventCard>(`/events${query}`),
  });

  if (events.isError) {
    return <ErrorBanner error={events.error} />;
  }

  const items = events.data?.data ?? [];

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Your calendar"
        title="Events"
        description="Track setup, readiness and match-day status for every tournament."
      />
      <FilterBar>
        <FilterSelect
          label="Status"
          value={status}
          onChange={(event) => {
            setStatus(event.target.value);
            setPage(1);
          }}
        >
          <option value="">All</option>
          {EVENT_STATUSES.map((value) => (
            <option key={value} value={value}>
              {value}
            </option>
          ))}
        </FilterSelect>
        <FilterInput
          label="From"
          type="date"
          value={from}
          onChange={(event) => {
            setFrom(event.target.value);
            setPage(1);
          }}
        />
        <FilterInput
          label="To"
          type="date"
          value={to}
          onChange={(event) => {
            setTo(event.target.value);
            setPage(1);
          }}
        />
        <FilterSelect label="Sort" value={sort} onChange={(event) => setSort(event.target.value)}>
          <option value="starts_at">Starts at</option>
          <option value="created_at">Created at</option>
        </FilterSelect>
        <FilterSelect
          label="Direction"
          value={direction}
          onChange={(event) => setDirection(event.target.value)}
        >
          <option value="asc">Ascending</option>
          <option value="desc">Descending</option>
        </FilterSelect>
      </FilterBar>
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
                  <span className="text-prowem-muted">
                    {event.open_tickets_count} tickets
                  </span>
                </div>
              </GlassCard>
            </Link>
          ))}
        </div>
      )}
      <PaginationControls pagination={events.data?.meta.pagination} onPageChange={setPage} />
    </div>
  );
}
