"use client";

import Link from "next/link";
import { useParams } from "next/navigation";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useState } from "react";
import { apiGet, apiGetPaginated, apiSend } from "@/shared/api/browser";
import type { TeamOperation, TeamPassport } from "@/shared/api/types";
import { PAGE_SIZE, READINESS_STATUSES, humanize } from "@/shared/domain/enums";
import { useSession } from "@/shared/auth/session-context";
import { canManage } from "@/shared/auth/roles";
import { formatWhen } from "@/shared/lib/labels";
import { buildQuery } from "@/shared/lib/query";
import { useEventRealtime } from "@/shared/realtime/hooks";
import { Badge } from "@/shared/ui/badge";
import { Button } from "@/shared/ui/button";
import { Card } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";
import { FilterBar, FilterInput, FilterSelect, PaginationControls } from "@/shared/ui/filters";
import { ConfirmationDialog } from "@/shared/ui/confirmation-dialog";

export function TeamsList() {
  const params = useParams<{ eventId: string }>();
  const [status, setStatus] = useState("");
  const [search, setSearch] = useState("");
  const [page, setPage] = useState(1);
  useEventRealtime(params.eventId);
  const queryString = buildQuery({
    status,
    search,
    page,
    per_page: PAGE_SIZE,
  });
  const query = useQuery({
    queryKey: ["event", params.eventId, "teams", queryString],
    queryFn: () =>
      apiGetPaginated<TeamPassport>(`/events/${params.eventId}/teams/readiness${queryString}`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }

  const items = query.data?.data ?? [];

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Passports"
        title="Team passports"
        description="Complete payment, check-in, roster, eligibility and document checks."
      />
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
          {READINESS_STATUSES.map((value) => (
            <option key={value} value={value}>
              {value}
            </option>
          ))}
        </FilterSelect>
        <FilterInput
          label="Search"
          value={search}
          placeholder="Team name"
          onChange={(event) => {
            setSearch(event.target.value);
            setPage(1);
          }}
        />
      </FilterBar>
      {items.length === 0 && !query.isLoading ? (
        <EmptyState title="No teams" description="Team projections for this event will appear here." />
      ) : (
        <div className="grid gap-3 md:grid-cols-2">
          {items.map((team) => (
            <Link key={team.team.id} href={`/events/${params.eventId}/teams/${team.team.id}`}>
              <Card className="hover:border-white/25">
                <div className="flex items-center justify-between">
                  <h2 className="font-semibold">{team.team.name}</h2>
                  <Badge value={team.status} />
                </div>
                <p className="mt-2 text-sm text-prowem-muted">
                  Score {team.score} · {team.blockers_count} blockers ·{" "}
                  {team.actions_required_count} actions
                </p>
              </Card>
            </Link>
          ))}
        </div>
      )}
      <PaginationControls pagination={query.data?.meta.pagination} onPageChange={setPage} />
    </div>
  );
}

export function TeamDetail() {
  const params = useParams<{ eventId: string; teamId: string }>();
  const user = useSession();
  const queryClient = useQueryClient();
  const [error, setError] = useState<unknown>(null);
  const [pendingOperation, setPendingOperation] = useState<TeamOperation | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  useEventRealtime(params.eventId);
  const query = useQuery({
    queryKey: ["event", params.eventId, "teams", params.teamId],
    queryFn: () =>
      apiGet<TeamPassport>(`/events/${params.eventId}/teams/${params.teamId}/readiness`),
  });

  const action = useMutation({
    mutationFn: (operation: TeamOperation) =>
      apiSend<TeamPassport>(`/events/${params.eventId}/teams/${params.teamId}/actions/${operation}`, "POST"),
    onSuccess: (updated) => {
      const previous = query.data?.score;
      queryClient.setQueryData(["event", params.eventId, "teams", params.teamId], updated);
      queryClient.invalidateQueries({ queryKey: ["event", params.eventId] });
      setError(null);
      setPendingOperation(null);
      setSuccess(`Check completed. Team readiness ${previous === undefined ? `${updated.score}%` : `${previous}% → ${updated.score}%`}. Event readiness updated automatically.`);
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

  const unresolved = data.checks.filter((check) => check.status !== "ready");
  const completed = data.checks.filter((check) => check.status === "ready");

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow="Team passport"
        title={data.team.name}
        description={`Manager ${data.manager.name ?? "—"} · ${data.manager.phone ?? "no phone"}`}
        actions={<Badge value={data.status} />}
      />
      <p className="text-sm text-prowem-muted">
        First match {data.first_match?.field ?? "TBC"}
        {data.first_match ? ` · ${formatWhen(data.first_match.kickoff_at)}` : ""}
      </p>
      <ErrorBanner error={error} />
      {success ? <div role="status" className="rounded-2xl border border-prowem-success/30 bg-prowem-success/10 px-4 py-3 text-sm text-prowem-success">✓ {success}</div> : null}
      {unresolved.length ? <><h2 className="text-sm font-bold uppercase tracking-[.16em] text-prowem-warning">Needs attention</h2><ul className="space-y-3">
        {unresolved.map((check) => (
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
                    disabled={action.isPending}
                    onClick={() => setPendingOperation(check.action as TeamOperation)}
                  >
                    {humanize(check.action)}
                  </Button>
                ) : null}
              </div>
            </div>
          </Card>
        ))}
      </ul></> : null}
      <details className="rounded-2xl border border-white/10 bg-white/[.03] p-4" open={unresolved.length === 0}><summary className="cursor-pointer font-semibold">Completed checks ({completed.length})</summary><ul className="mt-3 grid gap-2 md:grid-cols-2">{completed.map((check) => <li key={check.id} className="flex min-h-12 items-center justify-between rounded-xl border border-white/10 px-3"><span>{check.label}</span><Badge value="ready" /></li>)}</ul></details>
      <ConfirmationDialog
        open={pendingOperation !== null}
        title={pendingOperation ? humanize(pendingOperation) : "Confirm team action"}
        description="Confirm this team check. Team and Event readiness will update automatically."
        confirmLabel={pendingOperation ? humanize(pendingOperation) : "Confirm"}
        pending={action.isPending}
        onCancel={() => setPendingOperation(null)}
        onConfirm={() => { if (pendingOperation) action.mutate(pendingOperation); }}
      />
    </div>
  );
}
