"use client";

import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@/shared/api/browser";
import type { CareReport } from "@/shared/api/types";
import { Badge } from "@/shared/ui/badge";
import { Card, CardTitle } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { EmptyState, PageHeader } from "@/shared/ui/page-header";

export function ReportPage() {
  const params = useParams<{ eventId: string }>();
  const query = useQuery({
    queryKey: ["event", params.eventId, "report"],
    queryFn: () => apiGet<CareReport>(`/events/${params.eventId}/care-report`),
  });

  if (query.isError) {
    return <ErrorBanner error={query.error} />;
  }
  const data = query.data;
  if (!data) {
    return <p>Loading report…</p>;
  }

  return (
    <div className="space-y-4">
      <PageHeader
        eyebrow={data.event.name}
        title="Post-event report"
        description={`${data.team_count} teams · ${data.match_count} matches`}
        actions={<Badge value={data.event.status} />}
      />
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardTitle>Kickoff readiness</CardTitle>
          <p className="font-display text-4xl font-bold">
            {data.readiness.score_before_kickoff ?? "—"}
          </p>
          <p className="text-sm text-prowem-muted">
            {data.readiness.status_before_kickoff ?? "No kickoff snapshot"}
          </p>
        </Card>
        <Card>
          <CardTitle>Incidents</CardTitle>
          <p>
            {data.incidents.total} total · {data.incidents.operational} operational ·{" "}
            {data.incidents.technical} technical
          </p>
          <p className="mt-2 text-sm text-prowem-muted">
            {data.cancelled_matches} cancelled matches · avg delay{" "}
            {data.average_delay_minutes} min
          </p>
        </Card>
        <Card>
          <CardTitle>Support</CardTitle>
          <p>
            {data.support.tickets} tickets · {data.support.p1} P1 · SLA{" "}
            {data.support.sla_compliance_percent ?? "n/a"}%
          </p>
          <p className="mt-2 text-sm text-prowem-muted">
            Avg resolution {data.support.average_resolution_minutes ?? "n/a"} min
          </p>
        </Card>
      </div>
      <Card>
        <CardTitle>Major blockers</CardTitle>
        {data.major_blockers.length === 0 ? (
          <EmptyState title="No major blockers recorded" />
        ) : (
          <ul className="space-y-2 text-sm">
            {data.major_blockers.map((item) => (
              <li key={item.key}>
                <span className="font-medium">{item.key}</span>
                {item.error_code ? ` (${item.error_code})` : ""}
                {item.message ? ` — ${item.message}` : ""}
              </li>
            ))}
          </ul>
        )}
      </Card>
      <Card>
        <CardTitle>Recommendations</CardTitle>
        {data.recommendations.length === 0 ? (
          <p className="text-sm text-prowem-muted">No recommendations.</p>
        ) : (
          <ul className="list-disc space-y-1 pl-5 text-sm">
            {data.recommendations.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ul>
        )}
      </Card>
    </div>
  );
}
