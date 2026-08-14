"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowRight, CalendarDays, CheckCircle2, CircleDollarSign, Clock3, MapPin, Radio, ShieldAlert, UserCheck } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { apiGet } from "@/shared/api/browser";
import type { CareOverview, LiveControl, ReadinessCheck } from "@/shared/api/types";
import { formatWhen } from "@/shared/lib/labels";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { EventStatusActions } from "@/features/events/status-actions";
import { Badge } from "@/shared/ui/badge";
import { useState } from "react";

export function EventHome() {
  const { eventId } = useParams<{ eventId: string }>();
  useEventRealtime(eventId);
  const query = useQuery({ queryKey: ["event", eventId, "care"], queryFn: () => apiGet<CareOverview>(`/events/${eventId}/care`) });
  const liveQuery = useQuery({ queryKey: ["event", eventId, "live"], queryFn: () => apiGet<LiveControl>(`/events/${eventId}/live`), enabled: query.data?.event.status === "live" });

  if (query.isError) return <ErrorBanner error={query.error} />;
  if (!query.data) return <div className="event-dashboard-state">Loading event care…</div>;
  const data = query.data;

  if (data.event.status === "live") return <LiveEventHome data={data} live={liveQuery.data} eventId={eventId} />;
  if (data.event.status === "completed") return <CompletedEventHome data={data} eventId={eventId} />;

  return (
    <div className="event-dashboard">
      <section className="event-dashboard-hero glass-panel-strong">
        <div className="event-dashboard-identity">
          <EventCrest name={data.event.name} />
          <div>
            <p>{data.event.external_reference ?? "EVENT HOME"}</p>
            <h1>{data.event.name}</h1>
            <div className="event-dashboard-meta"><span><MapPin />{data.event.venue?.name ?? "Venue pending"}</span><span><CalendarDays />{dateRange(data.event.starts_at, data.event.ends_at)}</span></div>
            <span className="event-dashboard-status">{data.event.status}</span>
          </div>
        </div>
        <div className="event-dashboard-readiness">
          <div className="readiness-ring" style={{ "--score": `${data.readiness.score * 3.6}deg` } as React.CSSProperties}><div><b>{data.readiness.score}%</b><small>Readiness</small></div></div>
          <div className="readiness-summary"><strong><ShieldAlert />{data.readiness.status}</strong><p className="is-danger"><AlertTriangle />{data.readiness.critical_blockers_count} critical blockers</p><p className="is-warning"><CheckCircle2 />{data.readiness.actions_required_count} actions required</p></div>
        </div>
      </section>

      {data.event.status === "ready" ? <ReadyEventActions eventId={eventId} /> : null}
      {data.event.status === "preparing" && data.readiness.status === "ready" ? <ConfirmReadyActions eventId={eventId} /> : null}

      <DashboardSection title="Needs attention" href={`/events/${eventId}/readiness`} linkLabel={`View all (${data.needs_attention.length})`}>
        {data.needs_attention.length ? <div className="attention-grid">{data.needs_attention.slice(0, 3).map((item, index) => <AttentionCard key={item.id} item={item} index={index} eventId={eventId} />)}</div> : <EmptyLine text="Everything is on track." />}
      </DashboardSection>

      <div className="event-dashboard-columns">
        <DashboardSection title="Upcoming matches" href={`/events/${eventId}/live`} linkLabel="View all">
          {data.next_matches.length ? <div className="match-list">{data.next_matches.slice(0, 4).map((match) => <Link key={match.id} href={`/events/${eventId}/live`}><time>{matchTime(match.kickoff_at)}</time><div><b>{match.home_team?.name ?? `Team ${match.number}`}</b><span>vs</span><b>{match.away_team?.name ?? "TBC"}</b></div><em>{match.field ?? "Field TBC"}</em><ArrowRight /></Link>)}</div> : <EmptyLine text="No upcoming matches." />}
        </DashboardSection>
        <DashboardSection title="Recent activity" href={`/events/${eventId}/activity`} linkLabel="View all">
          {data.recent_activity.length ? <div className="activity-list">{data.recent_activity.slice(0, 5).map((item) => <Link key={item.id} href={`/events/${eventId}/activity`}><span className={activityTone(item.type)}>{activityIcon(item.type)}</span><div><b>{item.title}</b><small>{item.actor?.name ?? "System"} · {formatWhen(item.occurred_at)}</small></div><time>{shortTime(item.occurred_at)}</time></Link>)}</div> : <EmptyLine text="No recent activity." />}
        </DashboardSection>
      </div>
    </div>
  );
}

function ReadyEventActions({ eventId }: { eventId: string }) {
  const [error, setError] = useState<unknown>(null);
  return <section className="rounded-3xl border border-prowem-success/30 bg-prowem-success/5 p-5"><div className="flex flex-col justify-between gap-4 md:flex-row md:items-center"><div><p className="text-xs font-bold uppercase tracking-[.18em] text-prowem-success">Ready for kickoff</p><h2 className="mt-1 text-2xl font-extrabold">No critical blockers</h2><p className="mt-1 text-sm text-prowem-muted">The Event can now move to Live mode.</p></div><div className="flex flex-wrap items-center gap-2"><Link className="btn-ghost-glass" href={`/events/${eventId}/readiness`}>Review readiness</Link><EventStatusActions eventId={eventId} status="ready" onError={setError} /></div></div><div className="mt-3"><ErrorBanner error={error} /></div></section>;
}

function ConfirmReadyActions({ eventId }: { eventId: string }) {
  const [error, setError] = useState<unknown>(null);
  return <section className="rounded-3xl border border-prowem-success/30 bg-prowem-success/5 p-5"><div className="flex flex-col justify-between gap-4 md:flex-row md:items-center"><div><p className="text-xs font-bold uppercase tracking-[.18em] text-prowem-success">All checks complete</p><h2 className="mt-1 text-2xl font-extrabold">Confirm the Event is ready</h2><p className="mt-1 text-sm text-prowem-muted">This unlocks the Start Event action.</p></div><EventStatusActions eventId={eventId} status="preparing" onError={setError} /></div><div className="mt-3"><ErrorBanner error={error} /></div></section>;
}

function LiveEventHome({ data, live, eventId }: { data: CareOverview; live?: LiveControl; eventId: string }) {
  const incidentMap = new Map([...data.open_critical_incidents, ...(live?.operational_incidents ?? [])].map((item) => [item.id, item]));
  const representedTickets = new Set<number>();
  const incidentIssues = [...incidentMap.values()].map((item) => {
    const ticket = item.ticket && "id" in item.ticket ? item.ticket : null;
    if (ticket) representedTickets.add(ticket.id);
    return { id: `incident-${item.id}`, title: item.title, detail: item.type === "technical" ? "PROWEM Support is handling this" : "Your team needs to handle this", href: ticket ? `/events/${eventId}/tickets/${ticket.id}` : `/events/${eventId}/incidents/${item.id}`, tone: item.type === "technical" ? "text-purple-300" : "text-prowem-danger" };
  });
  const issues = [...incidentIssues, ...data.open_tickets.filter((item) => !representedTickets.has(item.id)).map((item) => ({ id: `ticket-${item.id}`, title: item.subject, detail: `${item.priority.toUpperCase()} · PROWEM Support`, href: `/events/${eventId}/tickets/${item.id}`, tone: "text-purple-300" }))];

  return <div className="space-y-5">
    <header className="flex flex-col justify-between gap-4 lg:flex-row lg:items-end"><div><div className="flex items-center gap-2"><Badge value="live" /><span className="text-xs uppercase tracking-[.18em] text-prowem-muted">{data.event.external_reference}</span></div><h1 className="mt-2 text-3xl font-black md:text-4xl">{data.event.name}</h1><p className="mt-2 text-prowem-muted">Match-day command view</p></div><Link className="btn-primary-glow" href={`/events/${eventId}/live`}>Open Live Control <ArrowRight /></Link></header>
    <section className={`rounded-3xl border p-5 ${issues.length ? "border-prowem-danger/40 bg-prowem-danger/5" : "border-prowem-success/30 bg-prowem-success/5"}`}><div className="flex items-center justify-between"><div><p className={`text-xs font-bold uppercase tracking-[.18em] ${issues.length ? "text-prowem-danger" : "text-prowem-success"}`}>{issues.length ? "Needs action now" : "Event pulse healthy"}</p><h2 className="mt-1 text-2xl font-extrabold">{issues.length ? `${issues.length} critical items visible` : "No critical issue requires action"}</h2></div><AlertTriangle className={issues.length ? "text-prowem-danger" : "text-prowem-success"} /></div>{issues.length ? <div className="mt-4 grid gap-2 md:grid-cols-2">{issues.slice(0, 4).map((item) => <Link key={item.id} href={item.href} className="flex min-h-16 items-center justify-between rounded-2xl border border-white/10 bg-black/20 px-4 py-3"><span><b className={item.tone}>{item.title}</b><small className="mt-1 block text-prowem-muted">{item.detail}</small></span><ArrowRight /></Link>)}</div> : null}</section>
    <div className="grid gap-4 xl:grid-cols-[1fr_1.35fr_.9fr]">
      <DashboardSection title="Operational issues" href={`/events/${eventId}/incidents`} linkLabel="View all">{live?.operational_incidents.length ? <div className="space-y-2">{live.operational_incidents.slice(0, 5).map((item) => <Link className="block rounded-xl border border-white/10 p-3 hover:border-prowem-coral/40" key={item.id} href={`/events/${eventId}/incidents/${item.id}`}><b>{item.title}</b><small className="mt-1 block text-prowem-muted">Organizer-owned · {item.status.replaceAll("_", " ")}</small></Link>)}</div> : <EmptyLine text="No operational incident." />}</DashboardSection>
      <DashboardSection title="Live now" href={`/events/${eventId}/live`} linkLabel="Live Control">{live?.live_matches.length ? <div className="space-y-2">{live.live_matches.slice(0, 6).map((match) => <div className="rounded-xl border border-white/10 p-3" key={match.id}><b>Match #{match.number}</b><span className="ml-2 text-prowem-cyan">{match.status}</span></div>)}</div> : <EmptyLine text="No match is currently live." />}</DashboardSection>
      <div className="space-y-4"><DashboardSection title="Event pulse" href={`/events/${eventId}/tickets`} linkLabel="Support"><div className="space-y-3 text-sm"><p className="flex justify-between"><span className="text-prowem-muted">System</span><b>{live?.system_status.status ?? "loading"}</b></p><p className="flex justify-between"><span className="text-prowem-muted">Delayed</span><b>{live?.delayed_matches.length ?? 0}</b></p><p className="flex justify-between"><span className="text-prowem-muted">Support tickets</span><b>{data.open_tickets.length}</b></p></div></DashboardSection><DashboardSection title="Recent activity" href={`/events/${eventId}/activity`} linkLabel="History">{data.recent_activity.length ? <div className="space-y-2">{data.recent_activity.slice(0, 4).map((item) => <p className="text-sm" key={item.id}>{item.title}<small className="block text-prowem-muted">{formatWhen(item.occurred_at)}</small></p>)}</div> : <EmptyLine text="No recent activity." />}</DashboardSection></div>
    </div>
  </div>;
}

function CompletedEventHome({ data, eventId }: { data: CareOverview; eventId: string }) {
  return <div className="mx-auto max-w-5xl space-y-5"><section className="rounded-3xl border border-white/10 bg-white/[.03] p-6 md:p-8"><Badge value="completed" /><h1 className="mt-4 text-4xl font-black">{data.event.name}</h1><p className="mt-2 text-prowem-muted">The Event Care history is ready for review.</p><div className="mt-6 flex flex-wrap gap-3"><Link className="btn-primary-glow" href={`/events/${eventId}/report`}>View Event Care report <ArrowRight /></Link><Link className="btn-ghost-glass" href={`/events/${eventId}/activity`}>Review timeline</Link></div></section><div className="grid gap-4 md:grid-cols-3"><div className="rounded-2xl border border-white/10 p-4"><small className="text-prowem-muted">Teams</small><b className="mt-2 block text-2xl">{data.event.team_count ?? 0}</b></div><div className="rounded-2xl border border-white/10 p-4"><small className="text-prowem-muted">Critical incidents</small><b className="mt-2 block text-2xl">{data.open_critical_incidents.length} open</b></div><div className="rounded-2xl border border-white/10 p-4"><small className="text-prowem-muted">Support</small><b className="mt-2 block text-2xl">{data.open_tickets.length} open</b></div></div></div>;
}

function DashboardSection({ title, href, linkLabel, children }: { title: string; href: string; linkLabel: string; children: React.ReactNode }) {
  return <section className="dashboard-section"><header><h2>{title}</h2><Link href={href}>{linkLabel}<ArrowRight /></Link></header>{children}</section>;
}

function AttentionCard({ item, index, eventId }: { item: ReadinessCheck; index: number; eventId: string }) {
  const critical = item.status === "blocked" || item.is_critical;
  const action = typeof item.metadata?.action_label === "string" ? item.metadata.action_label : critical ? "Resolve now" : actionLabel(item.check_type);
  const href = item.subject_type === "team" && item.subject_id ? `/events/${eventId}/teams/${item.subject_id}` : `/events/${eventId}/readiness/${item.dimension}`;
  return <article className={`attention-card ${critical ? "is-critical" : "is-warning"}`}><div className="attention-card-icon">{attentionIcon(item.dimension)}<b>{index + 1}</b></div><div className="attention-card-copy"><span>{critical ? "Critical" : "Warning"}</span><h3>{item.message ?? readable(item.check_type)}</h3><p>{typeof item.metadata?.description === "string" ? item.metadata.description : `${readable(item.dimension)} requires attention before kickoff.`}</p><small><Clock3 />{item.last_checked_at ? `Detected ${formatWhen(item.last_checked_at)}` : "Action required"}</small></div><Link href={href}>{action}<ArrowRight /></Link></article>;
}

function EventCrest({ name }: { name: string }) { const initials = name.split(/\s+/).slice(0, 3).map((part) => part[0]).join(""); return <div className="event-dashboard-crest"><span>{initials}</span><small>EVENT CARE</small></div>; }
function EmptyLine({ text }: { text: string }) { return <div className="event-dashboard-empty"><CheckCircle2 />{text}</div>; }
function readable(value: string) { return value.replaceAll("_", " ").replace(/\b\w/g, (letter) => letter.toUpperCase()); }
function actionLabel(type: string) { if (type.includes("payment")) return "Verify payment"; if (type.includes("referee")) return "Request confirmation"; return "Review"; }
function attentionIcon(dimension: string) { if (dimension === "streaming") return <Radio />; if (dimension === "teams") return <CircleDollarSign />; if (dimension === "referees") return <UserCheck />; return <AlertTriangle />; }
function activityIcon(type: string) { return type.includes("incident") || type.includes("issue") ? <AlertTriangle /> : <CheckCircle2 />; }
function activityTone(type: string) { return type.includes("incident") || type.includes("issue") ? "danger" : "success"; }
function shortTime(value: string) { return new Intl.DateTimeFormat("en", { hour: "numeric", minute: "2-digit" }).format(new Date(value)); }
function matchTime(value: string) { return new Intl.DateTimeFormat("en", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" }).format(new Date(value)); }
function dateRange(from: string, to: string) { const format = (value: string) => new Intl.DateTimeFormat("en", { month: "short", day: "numeric", year: "numeric" }).format(new Date(value)); return `${format(from)} – ${format(to)}`; }
