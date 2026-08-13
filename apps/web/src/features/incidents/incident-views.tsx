"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiGetPaginated, apiSend } from "@/shared/api/browser";
import type { Incident, IncidentStatus } from "@/shared/api/types";
import { useSession } from "@/shared/auth/session-context";
import { canManage, canSupport } from "@/shared/auth/roles";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { useState } from "react";

const nextStatuses: Record<string, IncidentStatus[]> = {
  open: ["acknowledged", "in_progress", "resolved"],
  acknowledged: ["in_progress", "resolved"],
  in_progress: ["resolved"],
  resolved: [],
};

export function IncidentsList() {
  const params = useParams<{ eventId: string }>();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "incidents"],
    queryFn: () =>
      apiGetPaginated<Incident>(`/events/${params.eventId}/incidents?per_page=50`),
  });

  const create = useMutation({
    mutationFn: (payload: Record<string, string>) =>
      apiSend(`/events/${params.eventId}/incidents`, "POST", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  return (
    <div className="space-y-4">
      <h1 className="font-display text-3xl font-bold uppercase">Incidents</h1>
      <ErrorBanner error={error} />
      <Card>
          <form
            className="grid gap-2 md:grid-cols-2"
            onSubmit={(event) => {
              event.preventDefault();
              const form = new FormData(event.currentTarget);
              create.mutate({
                type: String(form.get("type")),
                category: String(form.get("category")),
                severity: String(form.get("severity")),
                title: String(form.get("title")),
                description: String(form.get("description")),
              });
              event.currentTarget.reset();
            }}
          >
            <select name="type" className="input-glass bg-prowem-bg">
              <option value="operational">operational</option>
              <option value="technical">technical</option>
            </select>
            <input name="category" required placeholder="category" className="input-glass bg-prowem-bg" />
            <select name="severity" className="input-glass bg-prowem-bg">
              <option value="low">low</option>
              <option value="medium">medium</option>
              <option value="high">high</option>
              <option value="critical">critical</option>
            </select>
            <input name="title" required placeholder="Title" className="input-glass bg-prowem-bg" />
            <textarea name="description" required placeholder="Description" className="input-glass md:col-span-2" />
            <Button type="submit">Report incident</Button>
          </form>
        </Card>
      <ul className="space-y-3">
        {(query.data?.data ?? []).map((incident) => (
          <Link key={incident.id} href={`/events/${params.eventId}/incidents/${incident.id}`}>
            <Card className="hover:border-white/25">
              <div className="flex items-center justify-between gap-3">
                <p className="font-medium">{incident.title}</p>
                <div className="flex gap-2">
                  <Badge value={incident.type} />
                  <Badge value={incident.severity} />
                  <Badge value={incident.status} />
                </div>
              </div>
            </Card>
          </Link>
        ))}
      </ul>
    </div>
  );
}

export function IncidentDetail() {
  const params = useParams<{ eventId: string; incidentId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "incidents", params.incidentId],
    queryFn: () => apiGet<Incident>(`/incidents/${params.incidentId}`),
  });

  const update = useMutation({
    mutationFn: (payload: { status: IncidentStatus; resolution?: string }) =>
      apiSend(`/incidents/${params.incidentId}`, "PATCH", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }
  const incident = query.data;
  if (!incident) {
    return <p>Loading incident…</p>;
  }

  const canUpdate =
    incident.type === "technical" ? canSupport(user.role) : canManage(user.role);

  return (
    <div className="space-y-4">
      <div className="flex flex-wrap items-center gap-2">
        <h1 className="font-display text-3xl font-bold uppercase">{incident.title}</h1>
        <Badge value={incident.type} />
        <Badge value={incident.severity} />
        <Badge value={incident.status} />
      </div>
      <p className="text-sm text-prowem-muted">{incident.description}</p>
      <ErrorBanner error={error} />
      {canUpdate && nextStatuses[incident.status].length > 0 ? (
        <form
          className="flex flex-wrap gap-2"
          onSubmit={(event) => {
            event.preventDefault();
            const form = new FormData(event.currentTarget);
            update.mutate({
              status: String(form.get("status")) as IncidentStatus,
              resolution: String(form.get("resolution") ?? "") || undefined,
            });
          }}
        >
          <select name="status" className="input-glass bg-prowem-bg">
            {nextStatuses[incident.status].map((status) => (
              <option key={status} value={status}>
                {status}
              </option>
            ))}
          </select>
          <input name="resolution" placeholder="Resolution (required when resolving)" className="input-glass min-w-64" />
          <Button type="submit">Update</Button>
        </form>
      ) : null}
    </div>
  );
}
