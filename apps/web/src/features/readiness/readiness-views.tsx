"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiSend } from "@/shared/api/browser";
import type { DimensionDetail, ReadinessCheck, ReadinessSummary } from "@/shared/api/types";
import { useSession } from "@/shared/auth/session-context";
import { canSupport } from "@/shared/auth/roles";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { useState } from "react";

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

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <h1 className="font-display text-3xl font-bold uppercase">Readiness</h1>
        <Badge value={data.status} />
        <span className="text-sm text-prowem-muted">
          Score {data.score} · {data.critical_blockers_count} critical blockers
        </span>
      </div>
      <div className="grid gap-3 md:grid-cols-3">
        {(data.dimensions ?? []).map((dimension) => (
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
      <div className="flex items-center gap-3">
        <h1 className="font-display text-3xl font-bold uppercase">{data.dimension.label}</h1>
        <Badge value={data.summary.status} />
      </div>
      <ErrorBanner error={error} />
      <ul className="space-y-3">
        {data.items.map((item) => (
          <Card key={item.id}>
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="font-medium">{item.label}</p>
                <p className="text-sm text-prowem-muted">{item.message}</p>
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
                <select name="status" defaultValue={item.status} className="input-glass bg-prowem-bg">
                  <option value="ready">ready</option>
                  <option value="warning">warning</option>
                  <option value="blocked">blocked</option>
                </select>
                <input name="message" placeholder="Message" className="input-glass" />
                <input name="reason" required placeholder="Override reason" className="input-glass" />
                <Button type="submit" variant="secondary">
                  Override
                </Button>
              </form>
            ) : null}
          </Card>
        ))}
      </ul>
    </div>
  );
}
