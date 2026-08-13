"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { apiGetPaginated, apiSend } from "@/shared/api/browser";
import type { NotificationItem } from "@/shared/api/types";
import { PAGE_SIZE } from "@/shared/domain/enums";
import { formatWhen } from "@/shared/lib/labels";
import { buildQuery } from "@/shared/lib/query";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";
import { PaginationControls } from "@/shared/ui/filters";

export function NotificationsPage() {
  const queryClient = useQueryClient();
  const [page, setPage] = useState(1);
  const queryString = buildQuery({ page, per_page: PAGE_SIZE });
  const query = useQuery({
    queryKey: ["notifications", queryString],
    queryFn: () => apiGetPaginated<NotificationItem>(`/notifications${queryString}`),
  });

  const read = useMutation({
    mutationFn: (id: string) => apiSend(`/notifications/${id}/read`, "PATCH"),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });
  const readAll = useMutation({
    mutationFn: () => apiSend("/notifications/read-all", "POST"),
    onSuccess: () => queryClient.invalidateQueries({ queryKey: ["notifications"] }),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  const items = query.data?.data ?? [];

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Inbox"
        title="Inbox"
        description="Event Care alerts for your account."
        actions={
          <Button
            type="button"
            variant="secondary"
            disabled={readAll.isPending}
            onClick={() => readAll.mutate()}
          >
            Mark all read
          </Button>
        }
      />
      {items.length === 0 && !query.isLoading ? (
        <EmptyState title="Inbox is empty" description="Notifications about tickets and readiness will appear here." />
      ) : (
        <ul className="space-y-3">
          {items.map((item) => (
            <Card key={item.id} className={item.read_at ? "opacity-70" : ""}>
              <div className="flex items-start justify-between gap-3">
                <div>
                  <p className="font-medium">{item.title ?? item.type}</p>
                  <p className="text-sm text-prowem-muted">{item.body}</p>
                  <p className="mt-1 text-xs text-prowem-muted">{formatWhen(item.created_at)}</p>
                  {item.event_id ? (
                    <Link
                      className="text-sm text-prowem-coral hover:underline"
                      href={`/events/${item.event_id}`}
                    >
                      Open event
                    </Link>
                  ) : null}
                </div>
                {!item.read_at ? (
                  <Button
                    type="button"
                    variant="secondary"
                    onClick={() => read.mutate(item.id)}
                  >
                    Read
                  </Button>
                ) : null}
              </div>
            </Card>
          ))}
        </ul>
      )}
      <PaginationControls pagination={query.data?.meta.pagination} onPageChange={setPage} />
    </div>
  );
}
