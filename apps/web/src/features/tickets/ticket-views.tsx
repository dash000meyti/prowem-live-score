"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { apiGet, apiGetPaginated, apiSend } from "@/shared/api/browser";
import { useEventLookups } from "@/shared/api/lookups";
import type { Ticket, TicketMessage, TicketStatus } from "@/shared/api/types";
import {
  AFFECTED_SERVICES,
  PAGE_SIZE,
  TICKET_CATEGORIES,
  TICKET_PRIORITIES,
  TICKET_STATUSES,
  TICKET_TRANSITIONS,
  TICKET_URGENCIES,
  humanize,
} from "@/shared/domain/enums";
import { canSupport } from "@/shared/auth/roles";
import { useSession } from "@/shared/auth/session-context";
import { fixtureLabel, formatWhen } from "@/shared/lib/labels";
import { buildQuery, optionalNumber, optionalString } from "@/shared/lib/query";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card, CardTitle } from "@/shared/ui/card";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { FilterBar, FilterSelect, PaginationControls } from "@/shared/ui/filters";

export function TicketsList() {
  const params = useParams<{ eventId: string }>();
  const queryClient = useQueryClient();
  const lookups = useEventLookups(params.eventId);
  const [error, setError] = useState<unknown>(null);
  const [status, setStatus] = useState("");
  const [priority, setPriority] = useState("");
  const [sort, setSort] = useState("sla_due_at");
  const [page, setPage] = useState(1);
  useEventRealtime(params.eventId);
  const queryString = buildQuery({
    status,
    priority,
    sort,
    direction: "asc",
    page,
    per_page: PAGE_SIZE,
  });
  const query = useQuery({
    queryKey: ["event", params.eventId, "tickets", queryString],
    queryFn: () =>
      apiGetPaginated<Ticket>(`/events/${params.eventId}/tickets${queryString}`),
  });

  const create = useMutation({
    mutationFn: (payload: Record<string, unknown>) =>
      apiSend(`/events/${params.eventId}/tickets`, "POST", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Support"
        title="Support tickets"
        description="Request help. Priority and SLA are calculated by the API."
      />
      <ErrorBanner error={error} />
      <Card>
        <CardTitle>Request support</CardTitle>
        <form
          className="grid gap-2 md:grid-cols-2"
          onSubmit={(event) => {
            event.preventDefault();
            const form = new FormData(event.currentTarget);
            create.mutate({
              category: String(form.get("category")),
              requested_urgency: String(form.get("requested_urgency")),
              subject: String(form.get("subject")),
              description: String(form.get("description")),
              affected_service: String(form.get("affected_service")),
              fixture_id: optionalNumber(form.get("fixture_id")),
              venue_id: optionalNumber(form.get("venue_id")),
            });
            event.currentTarget.reset();
          }}
        >
          <select name="category" required className="input-glass">
            {TICKET_CATEGORIES.map((value) => (
              <option key={value} value={value}>
                {humanize(value)}
              </option>
            ))}
          </select>
          <select name="requested_urgency" className="input-glass">
            {TICKET_URGENCIES.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
          <select name="affected_service" className="input-glass">
            {AFFECTED_SERVICES.map((value) => (
              <option key={value} value={value}>
                {humanize(value)}
              </option>
            ))}
          </select>
          <input name="subject" required placeholder="Subject" className="input-glass" />
          <select name="fixture_id" className="input-glass">
            <option value="">No fixture</option>
            {(lookups.data?.fixtures ?? []).map((fixture) => (
              <option key={fixture.id} value={fixture.id}>
                {fixtureLabel(fixture)}
              </option>
            ))}
          </select>
          <select name="venue_id" className="input-glass">
            <option value="">No venue</option>
            {(lookups.data?.venues ?? []).map((venue) => (
              <option key={venue.id} value={venue.id}>
                {venue.name}
              </option>
            ))}
          </select>
          <textarea
            name="description"
            required
            placeholder="Description"
            className="input-glass md:col-span-2"
          />
          <Button type="submit" disabled={create.isPending}>
            Request support
          </Button>
        </form>
      </Card>
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
          {TICKET_STATUSES.map((value) => (
            <option key={value} value={value}>
              {humanize(value)}
            </option>
          ))}
        </FilterSelect>
        <FilterSelect
          label="Priority"
          value={priority}
          onChange={(event) => {
            setPriority(event.target.value);
            setPage(1);
          }}
        >
          <option value="">All</option>
          {TICKET_PRIORITIES.map((value) => (
            <option key={value} value={value}>
              {value}
            </option>
          ))}
        </FilterSelect>
        <FilterSelect label="Sort" value={sort} onChange={(event) => setSort(event.target.value)}>
          <option value="sla_due_at">SLA due</option>
          <option value="created_at">Created</option>
          <option value="priority">Priority</option>
          <option value="status">Status</option>
        </FilterSelect>
      </FilterBar>
      {(query.data?.data ?? []).length === 0 && !query.isLoading ? (
        <EmptyState title="No tickets" description="Support requests for this event will appear here." />
      ) : (
        <ul className="space-y-3">
          {(query.data?.data ?? []).map((ticket) => (
            <Link key={ticket.id} href={`/events/${params.eventId}/tickets/${ticket.id}`}>
              <Card className="hover:border-white/25">
                <div className="flex items-center justify-between gap-3">
                  <div>
                    <p className="text-xs text-prowem-muted">{ticket.reference}</p>
                    <p className="font-medium">{ticket.subject}</p>
                  </div>
                  <div className="flex gap-2">
                    <Badge value={ticket.priority} />
                    <Badge value={ticket.status} />
                    <Badge value={ticket.sla_status} />
                  </div>
                </div>
              </Card>
            </Link>
          ))}
        </ul>
      )}
      <PaginationControls pagination={query.data?.meta.pagination} onPageChange={setPage} />
    </div>
  );
}

export function TicketDetail() {
  const params = useParams<{ eventId: string; ticketId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const lookups = useEventLookups(params.eventId);
  const [error, setError] = useState<unknown>(null);
  const [messagePage, setMessagePage] = useState(1);
  const [messageBody, setMessageBody] = useState("");
  useEventRealtime(params.eventId);
  const ticket = useQuery({
    queryKey: ["event", params.eventId, "tickets", params.ticketId],
    queryFn: () => apiGet<Ticket>(`/tickets/${params.ticketId}`),
  });
  const messages = useQuery({
    queryKey: ["event", params.eventId, "tickets", params.ticketId, "messages", messagePage],
    queryFn: () =>
      apiGetPaginated<TicketMessage>(
        `/tickets/${params.ticketId}/messages${buildQuery({ page: messagePage, per_page: PAGE_SIZE })}`,
      ),
  });

  const send = useMutation({
    mutationFn: (payload: { body: string; visibility?: string }) =>
      apiSend(`/tickets/${params.ticketId}/messages`, "POST", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["event", params.eventId, "tickets", params.ticketId],
      });
      setError(null);
      setMessageBody("");
    },
    onError: setError,
  });

  const admin = useMutation({
    mutationFn: (payload: Record<string, unknown>) =>
      apiSend(`/tickets/${params.ticketId}`, "PATCH", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  if (ticket.isError) {
    return <ErrorBanner error={ticket.error} />;
  }
  const data = ticket.data;
  if (!data) {
    return <p>Loading ticket…</p>;
  }

  const nextStatuses = [data.status, ...(TICKET_TRANSITIONS[data.status] ?? [])].filter(
    (value, index, all) => all.indexOf(value) === index,
  ) as TicketStatus[];

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow={data.reference}
        title={data.subject}
        description={data.description}
        actions={
          <div className="flex flex-wrap gap-2">
            <Badge value={data.priority} />
            <Badge value={data.status} />
            <Badge value={data.sla_status} />
          </div>
        }
      />
      <p className="text-sm text-prowem-muted">
        SLA due {formatWhen(data.sla_due_at)}
        {data.assignee ? ` · Assigned to ${data.assignee.name}` : ""}
        {data.affected_service ? ` · ${humanize(data.affected_service)}` : ""}
      </p>
      <div className="grid gap-3 md:grid-cols-3"><Card><p className="text-xs uppercase tracking-wide text-prowem-muted">Support owner</p><p className="mt-2 font-semibold">{data.assignee?.name ?? "PROWEM Support assigned"}</p></Card><Card><p className="text-xs uppercase tracking-wide text-prowem-muted">Affected service</p><p className="mt-2 font-semibold">{data.affected_service ? humanize(data.affected_service) : "Event Care"}</p></Card><Card><p className="text-xs uppercase tracking-wide text-prowem-muted">SLA</p><p className="mt-2 font-semibold">{humanize(data.sla_status)}</p></Card></div>
      {data.incident ? (
        <p className="text-sm">
          Linked incident{" "}
          <Link
            className="text-prowem-coral hover:underline"
            href={`/events/${params.eventId}/incidents/${data.incident.id}`}
          >
            {data.incident.title}
          </Link>
        </p>
      ) : null}
      <ErrorBanner error={error} />
      {data.status === "resolved" ? <div role="status" className="rounded-2xl border border-prowem-success/30 bg-prowem-success/10 p-4"><p className="font-bold text-prowem-success">✓ Resolved</p><p className="mt-1 text-sm text-white">{data.resolution ?? "PROWEM Support resolved this request."}</p><p className="mt-1 text-xs text-prowem-muted">Resolved {formatWhen(data.resolved_at)}</p></div> : null}

      {canSupport(user.role) ? (
        <Card>
          <CardTitle>Support administration</CardTitle>
          <form
            className="grid gap-2 md:grid-cols-2"
            onSubmit={(event) => {
              event.preventDefault();
              const form = new FormData(event.currentTarget);
              const status = String(form.get("status")) as TicketStatus;
              const assignee = optionalNumber(form.get("assignee_id"));
              admin.mutate({
                ...(status === data.status ? {} : { status }),
                priority: String(form.get("priority")),
                assignee_id: assignee ?? null,
                resolution: optionalString(form.get("resolution")),
                resolution_code: optionalString(form.get("resolution_code")),
              });
            }}
          >
            <select name="status" defaultValue={data.status} className="input-glass">
              {nextStatuses.map((value) => (
                <option key={value} value={value}>
                  {humanize(value)}
                </option>
              ))}
            </select>
            <select name="priority" defaultValue={data.priority} className="input-glass">
              {TICKET_PRIORITIES.map((value) => (
                <option key={value} value={value}>
                  {value}
                </option>
              ))}
            </select>
            <select
              name="assignee_id"
              defaultValue={data.assignee?.id ? String(data.assignee.id) : ""}
              className="input-glass"
            >
              <option value="">Unassigned</option>
              {(lookups.data?.staff ?? []).map((person) => (
                <option key={person.id} value={person.id}>
                  {person.name}
                </option>
              ))}
            </select>
            <input
              name="resolution_code"
              defaultValue={data.resolution_code ?? ""}
              placeholder="Resolution code"
              className="input-glass"
            />
            <textarea
              name="resolution"
              defaultValue={data.resolution ?? ""}
              placeholder="Resolution (required when resolving)"
              className="input-glass md:col-span-2"
            />
            <Button type="submit" disabled={admin.isPending}>
              Update ticket
            </Button>
          </form>
        </Card>
      ) : null}

      <Card>
        <CardTitle>Conversation</CardTitle>
        <ul className="space-y-3">
          {(messages.data?.data ?? []).map((message) => {
            const supportUser = canSupport(user.role);
            const authoredBySupport = message.author?.role !== "organizer";
            const outgoing = supportUser ? authoredBySupport : !authoredBySupport;
            const internal = message.visibility === "internal";
            return <li key={message.id} className={`max-w-[85%] rounded-2xl border p-3 text-sm ${internal ? "mr-auto border-amber-400/30 bg-amber-400/5" : outgoing ? "ml-auto border-prowem-coral/30 bg-prowem-coral/10" : "mr-auto border-purple-400/20 bg-purple-400/5"}`}><p className={`flex items-center gap-2 text-xs ${internal ? "text-amber-300" : outgoing ? "text-prowem-coral" : "text-purple-300"}`}><span>{outgoing ? "You" : message.author?.name ?? (supportUser ? "Customer" : "PROWEM Support")} · {formatWhen(message.created_at)}</span>{internal ? <b className="rounded-full border border-amber-400/30 px-2 py-0.5 uppercase tracking-wide">Internal</b> : null}</p><p className="mt-1 leading-6">{message.body}</p></li>;
          })}
          {!messages.isLoading && (messages.data?.data ?? []).length === 0 ? <li className="py-8 text-center text-sm text-prowem-muted">No conversation messages yet.</li> : null}
        </ul>
        <PaginationControls
          pagination={messages.data?.meta.pagination}
          onPageChange={setMessagePage}
        />
        <form
          className="mt-3 space-y-2"
          onSubmit={(event) => {
            event.preventDefault();
            send.mutate({
              body: messageBody.trim(),
              ...(canSupport(user.role)
                ? { visibility: String(new FormData(event.currentTarget).get("visibility")) }
                : {}),
            });
          }}
        >
          <textarea name="body" required value={messageBody} onChange={(event) => setMessageBody(event.target.value)} placeholder="Write a message…" className="input-glass" />
          {canSupport(user.role) ? (
            <select name="visibility" className="input-glass" aria-label="Message visibility">
              <option value="customer">Customer-visible reply</option>
              <option value="internal">Internal support note</option>
            </select>
          ) : null}
          <Button type="submit" disabled={send.isPending || !messageBody.trim()}>
            {send.isPending ? "Sending…" : "Send"}
          </Button>
        </form>
      </Card>
    </div>
  );
}
