"use client";

import { useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowRight, Check, Clock3, Headphones, MapPin, MessageSquare, Radio, TicketCheck, UserRound } from "lucide-react";
import Link from "next/link";
import { useParams } from "next/navigation";
import { apiGet } from "@/shared/api/browser";
import type { SupportHome as SupportHomeData, Ticket } from "@/shared/api/types";
import { formatWhen } from "@/shared/lib/labels";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { ErrorBanner } from "@/shared/ui/error-banner";

export function SupportHome() {
  const { eventId } = useParams<{ eventId: string }>();
  useEventRealtime(eventId);
  const query = useQuery({ queryKey: ["event", eventId, "support-home"], queryFn: () => apiGet<SupportHomeData>(`/events/${eventId}/support-home`) });
  if (query.isError) return <ErrorBanner error={query.error} />;
  if (!query.data) return <div className="support-home-state">Loading support…</div>;
  const data = query.data;
  return <div className="support-home">
    <header className="support-home-heading"><div><h1>Welcome</h1><p>How can we help you today?</p></div><Link href={`/events/${eventId}/tickets/new`}><Headphones />Contact PROWEM</Link></header>
    {data.critical ? <CriticalSupport ticket={data.critical} eventId={eventId} /> : <div className="support-clear glass-panel"><Check /><div><h2>No critical support active</h2><p>Your open requests are listed below.</p></div></div>}
    <TicketGroup title="Other open requests" count={data.counts.open} tickets={data.open} eventId={eventId} />
    <TicketGroup title="Resolved" count={data.counts.resolved} tickets={data.resolved} eventId={eventId} resolved />
    <Link id="request-support" className="support-new-request" href={`/events/${eventId}/tickets/new`}><MessageSquare /><span><b>Need help with something else?</b><small>Open a new support request</small></span><ArrowRight /></Link>
  </div>;
}

function CriticalSupport({ ticket, eventId }: { ticket: Ticket; eventId: string }) {
  return <section className="critical-support"><header><span><AlertTriangle />Critical support active</span><b>{ticket.priority}</b></header><div className="critical-support-details"><Detail icon={<AlertTriangle />} label="Issue" value={ticket.subject} /><Detail icon={<MapPin />} label="Location" value={ticket.location ?? "Event wide"} /><Detail icon={<UserRound />} label="Assignment" value={ticket.assignee ? `${ticket.assignee.name} assigned` : "PROWEM Support assigned"} /><Detail icon={<Clock3 />} label="SLA status" value={remaining(ticket)} danger /></div><div className="critical-support-actions"><Link href={`/events/${eventId}/tickets/${ticket.id}`}><TicketCheck />Open ticket</Link><Link href={`/events/${eventId}/tickets/${ticket.id}`} className="secondary"><Headphones />Contact PROWEM</Link></div></section>;
}

function Detail({ icon, label, value, danger }: { icon: React.ReactNode; label: string; value: string; danger?: boolean }) { return <div className="support-detail"><i>{icon}</i><span><small>{label}</small><b className={danger ? "danger" : ""}>{value}</b></span></div>; }

function TicketGroup({ title, count, tickets, eventId, resolved }: { title: string; count: number; tickets: Ticket[]; eventId: string; resolved?: boolean }) {
  return <section className="support-ticket-group"><header><h2>{title}</h2><span>{count} total</span></header><div>{tickets.length ? tickets.slice(0, 5).map((ticket) => <TicketRow key={ticket.id} ticket={ticket} eventId={eventId} resolved={resolved} />) : <p className="support-empty">Nothing to show.</p>}</div></section>;
}

function TicketRow({ ticket, eventId, resolved }: { ticket: Ticket; eventId: string; resolved?: boolean }) {
  const tone = resolved ? "resolved" : ticket.priority;
  return <Link className="support-ticket-row" href={`/events/${eventId}/tickets/${ticket.id}`}><span className={`support-priority ${tone}`}>{resolved ? <Check /> : ticket.priority.toUpperCase()}</span><span className="support-service-icon">{serviceIcon(ticket.affected_service)}</span><div className="support-ticket-copy"><b>{ticket.subject}</b><small>{ticket.location ?? ticket.description}</small></div><div className="support-ticket-state"><b className={tone}>{resolved ? "Resolved" : ticket.status.replaceAll("_", " ")}</b><small>{resolved ? `Resolved ${formatWhen(ticket.resolved_at)}` : `Updated ${formatWhen(ticket.updated_at)}`}</small></div><ArrowRight /></Link>;
}

function serviceIcon(service: string | null) { if (service === "streaming") return <Radio />; if (service === "platform") return <MessageSquare />; return <Headphones />; }
function remaining(ticket: Ticket) { if (ticket.sla_status === "breached") return "SLA breached"; if (ticket.first_response_at) return "Response received"; const minutes = Math.max(0, Math.ceil(ticket.sla_remaining_seconds / 60)); return `SLA ${minutes} min remaining`; }
