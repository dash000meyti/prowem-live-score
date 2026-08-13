"use client";

import { apiGet, apiGetPaginated } from "@/shared/api/browser";
import type { EventCard, EventStatus, EventSummary } from "@/shared/api/types";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowRight, Ban, CalendarDays, Check, ChevronRight, MapPin, Search, SlidersHorizontal } from "lucide-react";
import Link from "next/link";
import { useMemo, useState } from "react";

type Filter = "all" | "needs_attention" | EventStatus;

const filters: { key: Filter; label: string }[] = [
  { key: "all", label: "All Events" },
  { key: "needs_attention", label: "Needs Attention" },
  { key: "preparing", label: "Preparing" },
  { key: "ready", label: "Ready" },
  { key: "completed", label: "Completed" },
  { key: "cancelled", label: "Cancelled" },
];

const groupOrder: EventStatus[] = ["live", "preparing", "ready", "completed", "cancelled"];

export function EventsBoard() {
  const [filter, setFilter] = useState<Filter>("all");
  const [search, setSearch] = useState("");
  const params = new URLSearchParams({ per_page: "100", sort: "starts_at", direction: "asc" });
  if (filter === "needs_attention") params.set("needs_attention", "1");
  else if (filter !== "all") params.set("status", filter);
  if (search.trim()) params.set("search", search.trim());

  const events = useQuery({ queryKey: ["events", filter, search], queryFn: () => apiGetPaginated<EventCard>(`/events?${params}`) });
  const summary = useQuery({ queryKey: ["events-summary"], queryFn: () => apiGet<EventSummary>("/events/summary") });
  const grouped = useMemo(() => groupOrder.map((status) => ({ status, items: (events.data?.data ?? []).filter((event) => event.status === status) })).filter((group) => group.items.length), [events.data]);

  return (
    <div className="events-page">
      <header className="events-heading">
        <div><h1>My Events</h1><p>Monitor event readiness and act on what needs attention.</p></div>
        <div className="events-tools">
          <label><Search aria-hidden="true" /><input value={search} onChange={(event) => setSearch(event.target.value)} placeholder="Search events…" /></label>
          <button type="button" className="events-filter-button" aria-label="Filter events"><SlidersHorizontal /></button>
        </div>
      </header>

      <nav className="events-tabs" aria-label="Event filters">
        {filters.map((item) => <button key={item.key} type="button" className={filter === item.key ? "is-active" : ""} onClick={() => setFilter(item.key)}><span>{item.label}</span><b>{summary.data?.[item.key] ?? 0}</b></button>)}
      </nav>

      {events.isError ? <ErrorBanner error={events.error} /> : null}
      {events.isLoading ? <div className="events-loading">Loading events…</div> : null}
      {!events.isLoading && grouped.length === 0 ? <div className="events-empty">No events match these filters.</div> : null}

      <div className="event-groups">
        {grouped.map((group) => (
          <section key={group.status} className={`event-group event-group--${group.status}`}>
            <h2>{group.status === "preparing" ? "Upcoming" : group.status}</h2>
            <div className="event-group__list">{group.items.map((event) => <EventRow key={event.id} event={event} />)}</div>
          </section>
        ))}
      </div>
    </div>
  );
}

function EventRow({ event }: { event: EventCard }) {
  const date = `${formatDate(event.starts_at)} – ${formatDate(event.ends_at)}`;
  const issueCount = event.open_incidents_count + event.open_tickets_count;
  const tone = event.status === "live" ? "red" : event.status === "preparing" ? "amber" : event.status === "ready" ? "green" : "neutral";

  return (
    <article className={`event-row event-row--${tone}`}>
      <div className="event-identity">
        <EventCrest event={event} />
        <div className="event-copy">
          <div className="event-title"><h3>{event.name}</h3><span>{event.status}</span></div>
          <p><MapPin />{event.venue?.name ?? "Venue pending"}</p>
          <p><CalendarDays />{date}</p>
        </div>
      </div>
      <div className="event-health">
        {event.status === "live" ? <><Metric value={event.critical_incidents_count} label="Critical" icon={<AlertTriangle />} /><Metric value={issueCount} label="Open issues" /></> : null}
        {event.status === "preparing" ? <><Progress value={event.readiness.score} tone="amber" /><Metric value={event.readiness.critical_blockers_count} label="Blockers" /></> : null}
        {event.status === "ready" ? <><Progress value={event.readiness.score} tone="green" /><div className="event-message"><strong>Ready for kickoff</strong><span>All tasks complete</span></div></> : null}
        {event.status === "completed" ? <><span className="event-state-icon"><Check /></span><div className="event-message"><strong>Event completed</strong><span>Thank you for a great event!</span></div></> : null}
        {event.status === "cancelled" ? <><span className="event-state-icon"><Ban /></span><div className="event-message"><strong>Event cancelled</strong><span>No further actions required.</span></div></> : null}
      </div>
      <div className="event-actions">
        <Link href={`/events/${event.id}`} className="event-primary-action">{event.status === "live" ? "Open issues" : event.status === "preparing" ? "Continue prep" : event.status === "completed" ? "View report" : "View details"}<ArrowRight /></Link>
        <Link href={`/events/${event.id}`} className="event-secondary-action">View event <ChevronRight /></Link>
      </div>
    </article>
  );
}

function EventCrest({ event }: { event: EventCard }) {
  const words = event.name.toUpperCase().split(" ").slice(0, 3);
  return <div className={`event-crest event-crest--${event.status}`}><span>{words.map((word) => <b key={word}>{word}</b>)}</span><i>⚽</i></div>;
}

function Metric({ value, label, icon }: { value: number; label: string; icon?: React.ReactNode }) {
  return <div className="event-metric"><b>{value}</b><span>{label}</span>{icon}</div>;
}

function Progress({ value, tone }: { value: number; tone: string }) {
  return <div className={`event-progress event-progress--${tone}`} style={{ "--progress": `${Math.max(0, Math.min(100, value)) * 3.6}deg` } as React.CSSProperties}><span>{value}%</span></div>;
}

function formatDate(value: string) { return new Intl.DateTimeFormat("en", { month: "short", day: "numeric", year: "numeric" }).format(new Date(value)); }
