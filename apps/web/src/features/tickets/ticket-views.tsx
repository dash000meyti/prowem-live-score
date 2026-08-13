"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiGetPaginated, apiSend } from "@/shared/api/browser";
import type { Ticket, TicketMessage, TicketStatus } from "@/shared/api/types";
import { useSession } from "@/shared/auth/session-context";
import { canSupport } from "@/shared/auth/roles";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card, CardTitle } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { useState } from "react";

export function TicketsList() {
  const params = useParams<{ eventId: string }>();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "tickets"],
    queryFn: () =>
      apiGetPaginated<Ticket>(`/events/${params.eventId}/tickets?per_page=50`),
  });

  const create = useMutation({
    mutationFn: (payload: Record<string, string>) =>
      apiSend(`/events/${params.eventId}/tickets`, "POST", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  return (
    <div className="space-y-4">
      <h1 className="font-display text-3xl font-bold uppercase">Support tickets</h1>
      <ErrorBanner error={error} />
      <Card>
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
            });
            event.currentTarget.reset();
          }}
        >
          <input name="category" required placeholder="Category" className="input-glass" />
          <select name="requested_urgency" className="input-glass">
            <option value="normal">normal</option>
            <option value="low">low</option>
            <option value="high">high</option>
            <option value="critical">critical</option>
          </select>
          <select name="affected_service" className="input-glass">
            <option value="other">other</option>
            <option value="live_score">live_score</option>
            <option value="streaming">streaming</option>
            <option value="graphics">graphics</option>
            <option value="platform">platform</option>
          </select>
          <input name="subject" required placeholder="Subject" className="input-glass" />
            <textarea name="description" required placeholder="Description" className="input-glass md:col-span-2" />
          <Button type="submit">Request support</Button>
        </form>
      </Card>
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
    </div>
  );
}

export function TicketDetail() {
  const params = useParams<{ eventId: string; ticketId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const ticket = useQuery({
    queryKey: ["event", params.eventId, "tickets", params.ticketId],
    queryFn: () => apiGet<Ticket>(`/tickets/${params.ticketId}`),
  });
  const messages = useQuery({
    queryKey: ["event", params.eventId, "tickets", params.ticketId, "messages"],
    queryFn: () =>
      apiGetPaginated<TicketMessage>(`/tickets/${params.ticketId}/messages?per_page=50`),
  });

  const send = useMutation({
    mutationFn: (payload: { body: string; visibility?: string }) =>
      apiSend(`/tickets/${params.ticketId}/messages`, "POST", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({
        queryKey: ["event", params.eventId, "tickets", params.ticketId],
      });
      setError(null);
    },
    onError: setError,
  });

  const admin = useMutation({
    mutationFn: (payload: Record<string, string>) =>
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

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        <h1 className="font-display text-3xl font-bold uppercase">{data.subject}</h1>
        <Badge value={data.priority} />
        <Badge value={data.status} />
        <Badge value={data.sla_status} />
      </div>
      <p className="text-sm text-prowem-muted">
        {data.reference} · SLA due {new Date(data.sla_due_at).toLocaleString()}
      </p>
      <p>{data.description}</p>
      <ErrorBanner error={error} />

      {canSupport(user.role) ? (
        <Card>
          <CardTitle>Support administration</CardTitle>
          <form
            className="grid gap-2 md:grid-cols-4"
            onSubmit={(event) => {
              event.preventDefault();
              const form = new FormData(event.currentTarget);
              admin.mutate({
                status: String(form.get("status")),
                priority: String(form.get("priority")),
                resolution: String(form.get("resolution")),
              });
            }}
          >
            <select name="status" defaultValue={data.status} className="input-glass">
              {(["open", "in_progress", "waiting", "resolved", "reopened"] as TicketStatus[]).map(
                (status) => (
                  <option key={status} value={status}>
                    {status}
                  </option>
                ),
              )}
            </select>
            <select name="priority" defaultValue={data.priority} className="input-glass">
              <option value="p1">p1</option>
              <option value="p2">p2</option>
              <option value="p3">p3</option>
              <option value="p4">p4</option>
            </select>
            <input name="resolution" placeholder="Resolution" className="input-glass" />
            <Button type="submit">Update ticket</Button>
          </form>
        </Card>
      ) : null}

      <Card>
        <CardTitle>Conversation</CardTitle>
        <ul className="space-y-3">
          {(messages.data?.data ?? []).map((message) => (
            <li key={message.id} className="rounded-xl border border-white/10 bg-white/5 p-3 text-sm">
              <p className="text-xs text-prowem-muted">
                {message.author?.name} · {message.visibility}
              </p>
              <p>{message.body}</p>
            </li>
          ))}
        </ul>
        <form
          className="mt-3 space-y-2"
          onSubmit={(event) => {
            event.preventDefault();
            const form = new FormData(event.currentTarget);
            send.mutate({
              body: String(form.get("body")),
              ...(canSupport(user.role)
                ? { visibility: String(form.get("visibility")) }
                : {}),
            });
            event.currentTarget.reset();
          }}
        >
          <textarea name="body" required className="input-glass" />
          {canSupport(user.role) ? (
            <select name="visibility" className="input-glass">
              <option value="customer">customer</option>
              <option value="internal">internal</option>
            </select>
          ) : null}
          <Button type="submit">Send</Button>
        </form>
      </Card>
    </div>
  );
}
