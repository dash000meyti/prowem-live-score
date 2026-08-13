"use client";

import Link from "next/link";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGetPaginated, apiSend } from "@/shared/api/browser";
import type { NotificationItem } from "@/shared/api/types";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";

export function NotificationsPage() {
  const queryClient = useQueryClient();
  const query = useQuery({
    queryKey: ["notifications"],
    queryFn: () => apiGetPaginated<NotificationItem>("/notifications?per_page=50"),
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

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="font-display text-3xl font-bold uppercase">Inbox</h1>
        <Button type="button" variant="secondary" onClick={() => readAll.mutate()}>
          Mark all read
        </Button>
      </div>
      <ul className="space-y-3">
        {(query.data?.data ?? []).map((item) => (
          <Card key={item.id} className={item.read_at ? "opacity-70" : ""}>
            <div className="flex items-start justify-between gap-3">
              <div>
                <p className="font-medium">{item.title ?? item.type}</p>
                <p className="text-sm text-prowem-muted">{item.body}</p>
                {item.event_id ? (
                  <Link className="text-sm text-prowem-coral hover:underline" href={`/events/${item.event_id}`}>
                    Open event
                  </Link>
                ) : null}
              </div>
              {!item.read_at ? (
                <Button type="button" variant="secondary" onClick={() => read.mutate(item.id)}>
                  Read
                </Button>
              ) : null}
            </div>
          </Card>
        ))}
      </ul>
    </div>
  );
}
