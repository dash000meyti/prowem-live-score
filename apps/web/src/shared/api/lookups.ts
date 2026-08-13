"use client";

import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@/shared/api/browser";
import type { EventLookups } from "@/shared/api/types";

export function useEventLookups(eventId: string) {
  return useQuery({
    queryKey: ["event", eventId, "lookups"],
    queryFn: () => apiGet<EventLookups>(`/events/${eventId}/lookups`),
  });
}
