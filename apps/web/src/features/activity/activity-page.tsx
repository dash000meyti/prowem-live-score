"use client";

import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { apiGetPaginated } from "@/shared/api/browser";
import type { Activity } from "@/shared/api/types";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";

export function ActivityPage() {
  const params = useParams<{ eventId: string }>();
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "activity"],
    queryFn: () =>
      apiGetPaginated<Activity>(`/events/${params.eventId}/activity?per_page=50`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  return (
    <div className="space-y-4">
      <h1 className="font-display text-3xl font-bold uppercase">Activity</h1>
      <ul className="space-y-3">
        {(query.data?.data ?? []).map((item) => (
          <Card key={item.id}>
            <p className="text-xs uppercase tracking-wide text-prowem-coral">{item.title}</p>
            <p>{item.description}</p>
            <p className="mt-1 text-xs text-prowem-muted">
              {item.actor?.name ?? "System"} · {new Date(item.occurred_at).toLocaleString()}
            </p>
          </Card>
        ))}
      </ul>
    </div>
  );
}
