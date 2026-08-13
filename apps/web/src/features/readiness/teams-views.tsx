"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { apiGet, apiGetPaginated, apiSend } from "@/shared/api/browser";
import type { TeamOperation, TeamPassport } from "@/shared/api/types";
import { useSession } from "@/shared/auth/session-context";
import { canManage } from "@/shared/auth/roles";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { useState } from "react";

export function TeamsList() {
  const params = useParams<{ eventId: string }>();
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "teams"],
    queryFn: () =>
      apiGetPaginated<TeamPassport>(`/events/${params.eventId}/teams/readiness?per_page=50`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  return (
    <div className="space-y-4">
      <h1 className="font-display text-3xl font-bold uppercase">Team passports</h1>
      <div className="grid gap-3 md:grid-cols-2">
        {(query.data?.data ?? []).map((team) => (
          <Link key={team.team.id} href={`/events/${params.eventId}/teams/${team.team.id}`}>
            <Card className="hover:border-white/25">
              <div className="flex items-center justify-between">
                <h2 className="font-semibold">{team.team.name}</h2>
                <Badge value={team.status} />
              </div>
              <p className="mt-2 text-sm text-prowem-muted">
                Score {team.score} · {team.blockers_count} blockers
              </p>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}

export function TeamDetail() {
  const params = useParams<{ eventId: string; teamId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "teams", params.teamId],
    queryFn: () =>
      apiGet<TeamPassport>(`/events/${params.eventId}/teams/${params.teamId}/readiness`),
  });

  const action = useMutation({
    mutationFn: (operation: TeamOperation) =>
      apiSend(`/events/${params.eventId}/teams/${params.teamId}/actions/${operation}`, "POST"),
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
    return <p>Loading team…</p>;
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center gap-3">
        <h1 className="font-display text-3xl font-bold uppercase">{data.team.name}</h1>
        <Badge value={data.status} />
      </div>
      <p className="text-sm text-prowem-muted">
        Manager {data.manager.name ?? "—"} · {data.manager.phone ?? "no phone"} · first match{" "}
        {data.first_match?.field ?? "TBC"}
      </p>
      <ErrorBanner error={error} />
      <ul className="space-y-3">
        {data.checks.map((check) => (
          <Card key={check.id}>
            <div className="flex items-center justify-between gap-3">
              <div>
                <p className="font-medium">{check.label}</p>
                <p className="text-sm text-prowem-muted">{check.message}</p>
              </div>
              <div className="flex items-center gap-2">
                <Badge value={check.status} />
                {canManage(user.role) && check.action && check.status !== "ready" ? (
                  <Button
                    type="button"
                    onClick={() => action.mutate(check.action as TeamOperation)}
                  >
                    {check.action.replaceAll("_", " ")}
                  </Button>
                ) : null}
              </div>
            </div>
          </Card>
        ))}
      </ul>
    </div>
  );
}
