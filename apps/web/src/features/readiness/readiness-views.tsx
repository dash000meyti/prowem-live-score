"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { apiGet, apiSend } from "@/shared/api/browser";
import type { DimensionDetail, ReadinessCheck, ReadinessSummary } from "@/shared/api/types";
import { READINESS_STATUSES } from "@/shared/domain/enums";
import { useSession } from "@/shared/auth/session-context";
import { canSupport } from "@/shared/auth/roles";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";

export function ReadinessPage() {
  const params = useParams<{ eventId: string }>();
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "readiness"],
    queryFn: () => apiGet<ReadinessSummary>(`/events/${params.eventId}/readiness`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  const data = query.data;
  if (!data) {
    return <p>Loading readiness…</p>;
  }

  const dimensions = data.dimensions ?? [];

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Go-live"
        title="Readiness"
        description={`${data.critical_blockers_count} critical blockers · ${data.actions_required_count} actions required`}
        actions={<Badge value={data.status} />}
      />
      {dimensions.length === 0 ? (
        <EmptyState title="No readiness checks" />
      ) : (
        <div className="grid gap-3 md:grid-cols-3">
          {dimensions.map((dimension) => (
            <Link key={dimension.key} href={`/events/${params.eventId}/readiness/${dimension.key}`}>
              <Card className="h-full hover:border-white/25">
                <div className="flex items-center justify-between">
                  <h2 className="font-semibold">{dimension.label}</h2>
                  <Badge value={dimension.status} />
                </div>
                <p className="mt-2 text-sm text-prowem-muted">
                  {dimension.ready}/{dimension.total} ready · {dimension.actions_required} actions
                </p>
              </Card>
            </Link>
          ))}
        </div>
      )}
    </div>
  );
}

export function DimensionPage() {
  const params = useParams<{ eventId: string; dimension: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "readiness", params.dimension],
    queryFn: () =>
      apiGet<DimensionDetail>(`/events/${params.eventId}/readiness/${params.dimension}`),
  });

  const override = useMutation({
    mutationFn: (payload: { id: number; status: string; reason: string; message: string }) =>
      apiSend<ReadinessCheck>(`/readiness-checks/${payload.id}`, "PATCH", {
        status: payload.status,
        reason: payload.reason,
        message: payload.message,
      }),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
    },
    onError: setError,
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }
  const data = query.data;
  if (!data) {
    return <p>Loading dimension…</p>;
  }

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Readiness"
        title={data.dimension.label}
        description={`${data.summary.ready}/${data.summary.total} ready · ${data.summary.actions_required} actions`}
        actions={<Badge value={data.summary.status} />}
      />
      <ErrorBanner error={error} />
      {data.items.length === 0 ? (
        <EmptyState title="No checks in this dimension" />
      ) : (
        <ul className="space-y-3">
          {data.items.map((item) => {
            const critical = Boolean(item.metadata && item.metadata.is_critical);
            const errorCode =
              item.metadata && typeof item.metadata.error_code === "string"
                ? item.metadata.error_code
                : null;
            return (
              <Card key={item.id}>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="font-medium">{item.label}</p>
                    <p className="text-sm text-prowem-muted">{item.message}</p>
                    <p className="mt-1 text-xs text-prowem-muted">
                      {item.subject.type}
                      {item.subject.id ? ` #${item.subject.id}` : ""}
                      {critical ? " · critical" : ""}
                      {errorCode ? ` · ${errorCode}` : ""}
                    </p>
                  </div>
                  <Badge value={item.status} />
                </div>
                {canSupport(user.role) ? (
                  <form
                    className="mt-3 grid gap-2 md:grid-cols-4"
                    onSubmit={(event) => {
                      event.preventDefault();
                      const form = new FormData(event.currentTarget);
                      override.mutate({
                        id: item.id,
                        status: String(form.get("status")),
                        reason: String(form.get("reason")),
                        message: String(form.get("message")),
                      });
                    }}
                  >
                    <select
                      name="status"
                      defaultValue={item.status}
                      className="input-glass bg-prowem-bg"
                    >
                      {READINESS_STATUSES.map((value) => (
                        <option key={value} value={value}>
                          {value}
                        </option>
                      ))}
                    </select>
                    <input name="message" placeholder="Message" className="input-glass" />
                    <input
                      name="reason"
                      required
                      minLength={5}
                      placeholder="Override reason"
                      className="input-glass"
                    />
                    <Button type="submit" variant="secondary" disabled={override.isPending}>
                      Override
                    </Button>
                  </form>
                ) : null}
              </Card>
            );
          })}
        </ul>
      )}
    </div>
  );
}
