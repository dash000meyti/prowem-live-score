"use client";

import { useParams } from "next/navigation";
import { useQuery } from "@tanstack/react-query";
import { apiGet } from "@/shared/api/browser";
import type { CareReport } from "@/shared/api/types";
import { Badge } from "@/shared/ui/badge";
import { Card, CardTitle } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";

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
      <div className="flex items-center gap-3">
        <h1 className="font-display text-3xl font-bold uppercase">Post-event report</h1>
        <Badge value={data.event.status} />
      </div>
      <div className="grid gap-4 md:grid-cols-3">
        <Card>
          <CardTitle>Kickoff readiness</CardTitle>
          <p className="font-display text-4xl font-bold">
            {data.readiness.score_before_kickoff ?? "—"}
          </p>
        </Card>
        <Card>
          <CardTitle>Incidents</CardTitle>
          <p>
            {data.incidents.total} total · {data.incidents.operational} operational ·{" "}
            {data.incidents.technical} technical
          </p>
        </Card>
        <Card>
          <CardTitle>Support</CardTitle>
          <p>
            {data.support.tickets} tickets · {data.support.p1} P1 · SLA{" "}
            {data.support.sla_compliance_percent ?? "n/a"}
          </p>
        </Card>
      </div>
      <Card>
        <CardTitle>Recommendations</CardTitle>
        <ul className="list-disc space-y-1 pl-5 text-sm">
          {data.recommendations.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      </Card>
    </div>
  );
}
