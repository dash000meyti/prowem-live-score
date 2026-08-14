"use client";

import { useState } from "react";
import {
  AlertTriangle,
  CheckCircle2,
  Circle,
  LoaderCircle,
} from "lucide-react";
import { cn } from "@/shared/lib/cn";
import { Button } from "@/shared/ui/button";
import { GlassCard } from "@/shared/ui/card";

type ScenarioId = "ready" | "checking" | "issue" | "resolved";

const scenarios: {
  id: ScenarioId;
  topic: string;
  label: string;
  score: number;
  tone: string;
  bar: string;
  glow: "green" | "orange" | "coral" | "cyan";
  notice: string;
  actions?: string[];
}[] = [
  {
    id: "ready",
    topic: "Referees",
    label: "Ready",
    score: 100,
    tone: "text-prowem-accent",
    bar: "bg-prowem-accent",
    glow: "green",
    notice:
      "Referee number 1 for the first match was followed up and announced readiness.",
  },
  {
    id: "checking",
    topic: "Teams",
    label: "Checking...",
    score: 64,
    tone: "text-prowem-warning",
    bar: "bg-prowem-warning",
    glow: "orange",
    notice:
      "2 teams (numbers 7 and 11) have not confirmed their readiness. Follow-up messages have been sent.",
  },
  {
    id: "issue",
    topic: "Equipment",
    label: "Issue!",
    score: 41,
    tone: "text-prowem-coral",
    bar: "bg-prowem-coral",
    glow: "coral",
    notice:
      "Equipment and infrastructure: the filming team has announced they need two more cameras and storage.",
    actions: [
      "Request a proforma invoice",
      "Refer to the finance team",
      "Ask the originating team why this is needed",
    ],
  },
  {
    id: "resolved",
    topic: "Tickets",
    label: "Completed / Resolved",
    score: 100,
    tone: "text-prowem-cyan",
    bar: "bg-prowem-cyan",
    glow: "cyan",
    notice: "All tickets sold and the invitation message was sent to contacts.",
    actions: [
      "Open limited competitive capacity",
      "Refer to the media team to announce sold out",
    ],
  },
];

export function VisibilitySection() {
  const [activeId, setActiveId] = useState<ScenarioId>("ready");
  const [queued, setQueued] = useState<string | null>(null);
  const active = scenarios.find((item) => item.id === activeId) ?? scenarios[0];

  function select(id: ScenarioId) {
    setActiveId(id);
    setQueued(null);
  }

  return (
    <section className="relative mx-auto max-w-7xl px-4 py-16 sm:px-6 sm:py-24 lg:px-10">
      <div className="mx-auto max-w-3xl text-center">
        <h2 className="font-display text-3xl font-bold leading-tight tracking-wide text-white sm:text-4xl md:text-5xl">
          Complete Visibility Into Every Detail of Your Event
        </h2>
        <p className="mx-auto mt-4 max-w-2xl text-sm leading-relaxed text-white/70 sm:text-base">
          Connect different parts of your operations, monitor their status in real
          time, and immediately follow up on the next steps.
        </p>
      </div>

      <GlassCard glow={active.glow} strong className="mx-auto mt-12 max-w-3xl p-5 sm:p-8">
        <div className="flex flex-wrap items-start justify-between gap-4">
          <div>
            <p className="text-[10px] font-bold uppercase tracking-[0.22em] text-prowem-muted">
              VSC-2026 · Event Home
            </p>
            <h3 className="mt-1 font-display text-2xl font-bold uppercase sm:text-3xl">
              Vienna Youth Cup
            </h3>
            <p className="mt-1 text-sm text-white/55">Pitch A · Semi Final</p>
          </div>
          <div className="text-right">
            <p className={cn("font-display text-4xl font-bold tabular-nums", active.tone)}>
              {active.score}%
            </p>
            <p className={cn("mt-1 flex items-center justify-end gap-1.5 text-sm font-semibold", active.tone)}>
              <StatusIcon id={active.id} />
              {active.label}
            </p>
          </div>
        </div>

        <div className="mt-5 h-2 overflow-hidden rounded-full bg-white/10">
          <div
            className={cn("h-full rounded-full transition-all duration-500", active.bar)}
            style={{ width: `${active.score}%` }}
          />
        </div>

        <div
          role="tablist"
          aria-label="Event operation status"
          className="mt-6 grid grid-cols-2 gap-2 sm:grid-cols-4"
        >
          {scenarios.map((item) => {
            const selected = item.id === activeId;
            return (
              <button
                key={item.id}
                type="button"
                role="tab"
                aria-selected={selected}
                onClick={() => select(item.id)}
                className={cn(
                  "rounded-2xl border px-3 py-3 text-left transition",
                  selected
                    ? "border-white/25 bg-white/10"
                    : "border-white/10 bg-black/20 hover:border-white/20 hover:bg-white/5",
                )}
              >
                <span className={cn("flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wide", item.tone)}>
                  <StatusIcon id={item.id} />
                  {item.label === "Completed / Resolved" ? "Resolved" : item.label}
                </span>
                <span className="mt-1 block text-sm font-semibold text-white">{item.topic}</span>
                <span className="mt-0.5 block text-[11px] text-white/45">{item.score}%</span>
              </button>
            );
          })}
        </div>

        <div className="mt-6 rounded-2xl border border-white/10 bg-black/25 p-4 sm:p-5">
          <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-muted">
            Latest
          </p>
          <p className="mt-2 text-sm leading-relaxed text-white/90">{active.notice}</p>
        </div>

        {active.actions ? (
          <div className="mt-5">
            <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-muted">
              Suggested next step
            </p>
            <div className="mt-3 flex flex-col gap-2">
              {active.actions.map((action) => {
                const chosen = queued === action;
                return (
                  <Button
                    key={action}
                    type="button"
                    variant={chosen ? "accent" : "ghost"}
                    className="h-auto w-full justify-start whitespace-normal py-3 text-left text-sm"
                    onClick={() => setQueued(action)}
                  >
                    {chosen ? (
                      <CheckCircle2 className="h-4 w-4 shrink-0" />
                    ) : (
                      <Circle className="h-4 w-4 shrink-0" />
                    )}
                    {chosen ? `Queued · ${action}` : action}
                  </Button>
                );
              })}
            </div>
          </div>
        ) : (
          <p className="mt-5 text-sm text-white/50">
            No action needed — this part of the event is under control.
          </p>
        )}
      </GlassCard>
    </section>
  );
}

function StatusIcon({ id }: { id: ScenarioId }) {
  if (id === "ready") return <CheckCircle2 className="h-3.5 w-3.5" />;
  if (id === "checking") return <LoaderCircle className="h-3.5 w-3.5 animate-spin" />;
  if (id === "issue") return <AlertTriangle className="h-3.5 w-3.5" />;
  return <Circle className="h-3.5 w-3.5 fill-current" />;
}
