"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowRight, CalendarDays, CheckCircle2, CircleDollarSign, Clock3, MapPin, Radio, ShieldAlert, UserCheck } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { apiGet } from "@/shared/api/browser";
import type { CareOverview, ReadinessCheck } from "@/shared/api/types";
import { formatWhen } from "@/shared/lib/labels";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { ErrorBanner } from "@/shared/ui/error-banner";

export function EventHome() {
  const { eventId } = useParams<{ eventId: string }>();
  useEventRealtime(eventId);
  const query = useQuery({ queryKey: ["event", eventId, "care"], queryFn: () => apiGet<CareOverview>(`/events/${eventId}/care`) });

  if (query.isError) return <ErrorBanner error={query.error} />;
  if (!query.data) return <div className="event-dashboard-state">Loading event care…</div>;
  const data = query.data;

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

function DashboardSection({ title, href, linkLabel, children }: { title: string; href: string; linkLabel: string; children: React.ReactNode }) {
  return <section className="dashboard-section"><header><h2>{title}</h2><Link href={href}>{linkLabel}<ArrowRight /></Link></header>{children}</section>;
}

function AttentionCard({ item, index, eventId }: { item: ReadinessCheck; index: number; eventId: string }) {
  const critical = item.status === "blocked" || item.is_critical;
  const action = typeof item.metadata?.action_label === "string" ? item.metadata.action_label : critical ? "Resolve now" : actionLabel(item.check_type);
  return <article className={`attention-card ${critical ? "is-critical" : "is-warning"}`}><div className="attention-card-icon">{attentionIcon(item.dimension)}<b>{index + 1}</b></div><div className="attention-card-copy"><span>{critical ? "Critical" : "Warning"}</span><h3>{item.message ?? readable(item.check_type)}</h3><p>{typeof item.metadata?.description === "string" ? item.metadata.description : `${readable(item.dimension)} requires attention before kickoff.`}</p><small><Clock3 />{item.last_checked_at ? `Detected ${formatWhen(item.last_checked_at)}` : "Action required"}</small></div><Link href={`/events/${eventId}/readiness/${item.dimension}`}>{action}<ArrowRight /></Link></article>;
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
