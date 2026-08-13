"use client";

import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { useState } from "react";
import { apiGetPaginated } from "@/shared/api/browser";
import type { Activity } from "@/shared/api/types";
import { ACTIVITY_TYPES, PAGE_SIZE, humanize } from "@/shared/domain/enums";
import { formatWhen } from "@/shared/lib/labels";
import { buildQuery } from "@/shared/lib/query";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";
import { FilterBar, FilterInput, FilterSelect, PaginationControls } from "@/shared/ui/filters";

export function ActivityPage() {
  const params = useParams<{ eventId: string }>();
  const [type, setType] = useState("");
  const [from, setFrom] = useState("");
  const [to, setTo] = useState("");
  const [page, setPage] = useState(1);
  useEventRealtime(params.eventId);
  const queryString = buildQuery({
    type,
    from,
    to,
    page,
    per_page: PAGE_SIZE,
  });
  const query = useQuery({
    queryKey: ["event", params.eventId, "activity", queryString],
    queryFn: () =>
      apiGetPaginated<Activity>(`/events/${params.eventId}/activity${queryString}`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  const items = query.data?.data ?? [];

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Audit"
        title="Activity"
        description="Immutable Event Care timeline for this tournament."
      />
      <FilterBar>
        <FilterSelect
          label="Type"
          value={type}
          onChange={(event) => {
            setType(event.target.value);
            setPage(1);
          }}
        >
          <option value="">All</option>
          {ACTIVITY_TYPES.map((value) => (
            <option key={value} value={value}>
              {humanize(value)}
            </option>
          ))}
        </FilterSelect>
        <FilterInput
          label="From"
          type="date"
          value={from}
          onChange={(event) => {
            setFrom(event.target.value);
            setPage(1);
          }}
        />
        <FilterInput
          label="To"
          type="date"
          value={to}
          onChange={(event) => {
            setTo(event.target.value);
            setPage(1);
          }}
        />
      </FilterBar>
      {items.length === 0 && !query.isLoading ? (
        <EmptyState title="No activity" description="Actions on this event will appear here." />
      ) : (
        <ul className="space-y-3">
          {items.map((item) => (
            <Card key={item.id}>
              <p className="text-xs uppercase tracking-wide text-prowem-coral">{item.title}</p>
              <p>{item.description}</p>
              <p className="mt-1 text-xs text-prowem-muted">
                {item.actor?.name ?? "System"} · {formatWhen(item.occurred_at)}
                {item.entity.type
                  ? ` · ${humanize(item.entity.type)}${item.entity.id ? ` #${item.entity.id}` : ""}`
                  : ""}
              </p>
            </Card>
          ))}
        </ul>
      )}
      <PaginationControls pagination={query.data?.meta.pagination} onPageChange={setPage} />
    </div>
  );
}
