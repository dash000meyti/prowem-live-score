"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useMemo, useState } from "react";
import { apiGet, apiGetPaginated, apiSend } from "@/shared/api/browser";
import { useEventLookups } from "@/shared/api/lookups";
import type {
  Incident,
  IncidentStatus,
  IncidentType,
  Ticket,
} from "@/shared/api/types";
import {
  ALL_INCIDENT_CATEGORIES,
  INCIDENT_SEVERITIES,
  INCIDENT_STATUSES,
  INCIDENT_TRANSITIONS,
  INCIDENT_TYPES,
  OPERATIONAL_CATEGORIES,
  PAGE_SIZE,
  TECHNICAL_CATEGORIES,
  humanize,
} from "@/shared/domain/enums";
import { canManage, canSupport } from "@/shared/auth/roles";
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

function linkedTicket(incident: Incident): Ticket | null {
  const ticket = incident.ticket;
  if (!ticket || typeof ticket !== "object" || !("id" in ticket) || !ticket.id) {
    return null;
  }
  return ticket as Ticket;
}

export function IncidentsList() {
  const params = useParams<{ eventId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const lookups = useEventLookups(params.eventId);
  const [error, setError] = useState<unknown>(null);
  const [status, setStatus] = useState("");
  const [type, setType] = useState("");
  const [category, setCategory] = useState("");
  const [severity, setSeverity] = useState("");
  const [sort, setSort] = useState("started_at");
  const [page, setPage] = useState(1);
  const [createType, setCreateType] = useState<IncidentType>(
    canManage(user.role) ? "operational" : "technical",
  );
  useEventRealtime(params.eventId);

  const queryString = buildQuery({
    status,
    type,
    category,
    severity,
    sort,
    direction: "desc",
    page,
    per_page: PAGE_SIZE,
  });
  const query = useQuery({
    queryKey: ["event", params.eventId, "incidents", queryString],
    queryFn: () =>
      apiGetPaginated<Incident>(`/events/${params.eventId}/incidents${queryString}`),
  });

  const categories = useMemo(
    () => (createType === "technical" ? TECHNICAL_CATEGORIES : OPERATIONAL_CATEGORIES),
    [createType],
  );
  const canCreateOperational = canManage(user.role);
  const createTypes = canCreateOperational ? INCIDENT_TYPES : (["technical"] as const);

  const create = useMutation({
    mutationFn: (payload: Record<string, unknown>) =>
      apiSend(`/events/${params.eventId}/incidents`, "POST", payload),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Match day"
        title="Incidents"
        description="Report operational or technical issues and track them through resolution."
      />
      <ErrorBanner error={error} />
      <Card>
        <CardTitle>Report incident</CardTitle>
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
              fixture_id: optionalNumber(form.get("fixture_id")),
              venue_id: optionalNumber(form.get("venue_id")),
              correlation_key: optionalString(form.get("correlation_key")),
            });
            event.currentTarget.reset();
            setCreateType(canCreateOperational ? "operational" : "technical");
          }}
        >
          <select
            name="type"
            className="input-glass bg-prowem-bg"
            value={createType}
            onChange={(event) => setCreateType(event.target.value as IncidentType)}
          >
            {createTypes.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
          <select name="category" className="input-glass bg-prowem-bg" required>
            {categories.map((value) => (
              <option key={value} value={value}>
                {humanize(value)}
              </option>
            ))}
          </select>
          <select name="severity" className="input-glass bg-prowem-bg">
            {INCIDENT_SEVERITIES.map((value) => (
              <option key={value} value={value}>
                {value}
              </option>
            ))}
          </select>
          <input name="title" required placeholder="Title" className="input-glass bg-prowem-bg" />
          <select name="fixture_id" className="input-glass bg-prowem-bg">
            <option value="">No fixture</option>
            {(lookups.data?.fixtures ?? []).map((fixture) => (
              <option key={fixture.id} value={fixture.id}>
                {fixtureLabel(fixture)}
              </option>
            ))}
          </select>
          <select name="venue_id" className="input-glass bg-prowem-bg">
            <option value="">No venue</option>
            {(lookups.data?.venues ?? []).map((venue) => (
              <option key={venue.id} value={venue.id}>
                {venue.name}
              </option>
            ))}
          </select>
          <input
            name="correlation_key"
            placeholder="Correlation key (optional)"
            className="input-glass bg-prowem-bg md:col-span-2"
          />
          <textarea
            name="description"
            required
            placeholder="Description"
            className="input-glass md:col-span-2"
          />
          <Button type="submit" disabled={create.isPending}>
            Report incident
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
          {INCIDENT_STATUSES.map((value) => (
            <option key={value} value={value}>
              {humanize(value)}
            </option>
          ))}
        </FilterSelect>
        <FilterSelect
          label="Type"
          value={type}
          onChange={(event) => {
            setType(event.target.value);
            setPage(1);
          }}
        >
          <option value="">All</option>
          {INCIDENT_TYPES.map((value) => (
            <option key={value} value={value}>
              {value}
            </option>
          ))}
        </FilterSelect>
        <FilterSelect
          label="Category"
          value={category}
          onChange={(event) => {
            setCategory(event.target.value);
            setPage(1);
          }}
        >
          <option value="">All</option>
          {ALL_INCIDENT_CATEGORIES.map((value) => (
            <option key={value} value={value}>
              {humanize(value)}
            </option>
          ))}
        </FilterSelect>
        <FilterSelect
          label="Severity"
          value={severity}
          onChange={(event) => {
            setSeverity(event.target.value);
            setPage(1);
          }}
        >
          <option value="">All</option>
          {INCIDENT_SEVERITIES.map((value) => (
            <option key={value} value={value}>
              {value}
            </option>
          ))}
        </FilterSelect>
        <FilterSelect label="Sort" value={sort} onChange={(event) => setSort(event.target.value)}>
          <option value="started_at">Started</option>
          <option value="severity">Severity</option>
          <option value="status">Status</option>
        </FilterSelect>
      </FilterBar>
      {(query.data?.data ?? []).length === 0 && !query.isLoading ? (
        <EmptyState title="No incidents" description="Reported issues will appear here." />
      ) : (
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
                <p className="mt-1 text-sm text-prowem-muted">{humanize(incident.category)}</p>
              </Card>
            </Link>
          ))}
        </ul>
      )}
      <PaginationControls pagination={query.data?.meta.pagination} onPageChange={setPage} />
    </div>
  );
}

export function IncidentDetail() {
  const params = useParams<{ eventId: string; incidentId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const lookups = useEventLookups(params.eventId);
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
  const next = INCIDENT_TRANSITIONS[incident.status] ?? [];
  const ticket = linkedTicket(incident);
  const fixture = lookups.data?.fixtures.find((item) => item.id === incident.fixture_id);
  const venue = lookups.data?.venues.find((item) => item.id === incident.venue_id);

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow={humanize(incident.category)}
        title={incident.title}
        description={incident.description}
        actions={
          <div className="flex flex-wrap gap-2">
            <Badge value={incident.type} />
            <Badge value={incident.severity} />
            <Badge value={incident.status} />
          </div>
        }
      />
      <ErrorBanner error={error} />
      <Card>
        <CardTitle>Details</CardTitle>
        <dl className="grid gap-2 text-sm md:grid-cols-2">
          <div>
            <dt className="text-prowem-muted">Started</dt>
            <dd>{formatWhen(incident.started_at)}</dd>
          </div>
          <div>
            <dt className="text-prowem-muted">Acknowledged</dt>
            <dd>{formatWhen(incident.acknowledged_at)}</dd>
          </div>
          <div>
            <dt className="text-prowem-muted">Resolved</dt>
            <dd>{formatWhen(incident.resolved_at)}</dd>
          </div>
          <div>
            <dt className="text-prowem-muted">Fixture</dt>
            <dd>{fixture ? fixtureLabel(fixture) : "—"}</dd>
          </div>
          <div>
            <dt className="text-prowem-muted">Venue</dt>
            <dd>{venue?.name ?? "—"}</dd>
          </div>
          <div>
            <dt className="text-prowem-muted">Resolution</dt>
            <dd>{incident.resolution ?? "—"}</dd>
          </div>
        </dl>
        {ticket ? (
          <p className="mt-3 text-sm">
            Linked ticket{" "}
            <Link
              className="text-prowem-coral hover:underline"
              href={`/events/${params.eventId}/tickets/${ticket.id}`}
            >
              {ticket.reference ?? `Ticket ${ticket.id}`}
            </Link>
          </p>
        ) : null}
        {incident.metadata && Object.keys(incident.metadata).length > 0 ? (
          <pre className="mt-3 overflow-x-auto rounded-xl bg-black/30 p-3 text-xs text-prowem-muted">
            {JSON.stringify(incident.metadata, null, 2)}
          </pre>
        ) : null}
      </Card>
      {canUpdate && next.length > 0 ? (
        <Card>
          <CardTitle>Update status</CardTitle>
          <form
            className="grid gap-2 md:grid-cols-3"
            onSubmit={(event) => {
              event.preventDefault();
              const form = new FormData(event.currentTarget);
              const status = String(form.get("status")) as IncidentStatus;
              update.mutate({
                status,
                resolution: optionalString(form.get("resolution")),
              });
            }}
          >
            <select name="status" className="input-glass bg-prowem-bg">
              {next.map((value) => (
                <option key={value} value={value}>
                  {humanize(value)}
                </option>
              ))}
            </select>
            <input
              name="resolution"
              placeholder="Resolution (required when resolving)"
              className="input-glass"
            />
            <Button type="submit" disabled={update.isPending}>
              Update
            </Button>
          </form>
        </Card>
      ) : null}
    </div>
  );
}
