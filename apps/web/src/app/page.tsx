import Link from "next/link";
import {
  Activity,
  CheckCircle2,
  Headphones,
  LineChart,
  Radio,
  Shield,
  Sparkles,
} from "lucide-react";
import { getSessionUser } from "@/shared/api/server";
import { ButtonLink } from "@/shared/ui/button";
import { GlassCard } from "@/shared/ui/card";
import { LandingHero } from "@/features/marketing/hero";

const beforeDuringAfter = [
  {
    phase: "BEFORE",
    color: "text-prowem-orange",
    items: ["Setup", "Testing", "Training", "Readiness"],
    promise: "We test.",
  },
  {
    phase: "DURING",
    color: "text-prowem-coral",
    items: ["Monitoring", "Live Support", "Incident Response"],
    promise: "We monitor. We respond.",
  },
  {
    phase: "AFTER",
    color: "text-prowem-cyan",
    items: ["Reports", "Feedback", "Optimization", "Renewal"],
    promise: "We help you improve.",
  },
];

const careFeatures = [
  "Dedicated account coverage",
  "Pre-event technical check",
  "Team passport operations",
  "Match-day monitoring",
  "Priority support SLAs",
  "Post-event performance report",
];

const previews = [
  { title: "Event Home", note: "Health, blockers and next actions" },
  { title: "Readiness", note: "Visual readiness by dimension" },
  { title: "Live Control", note: "Start event and live operations" },
  { title: "Incidents", note: "Operational and technical issues" },
  { title: "Support", note: "Tickets, SLA and conversation" },
  { title: "Post-Event Report", note: "Insights and recommendations" },
];

export default async function LandingPage() {
  let user = null;
  try {
    user = await getSessionUser();
  } catch {
    user = null;
  }
  const enterHref = user ? "/events" : "/login";

  return (
    <div className="relative overflow-hidden">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-black/70 backdrop-blur-xl supports-backdrop-filter:bg-black/55">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-3 sm:px-6 sm:py-4 lg:px-10">
          <Link href="/" className="font-display text-lg font-bold tracking-wide sm:text-xl">
            PROWEM <span className="text-prowem-coral">Event Care</span>
          </Link>
          <div className="flex items-center gap-2 sm:gap-3">
            <Link
              href={enterHref}
              className="hidden text-sm text-prowem-muted hover:text-white sm:inline"
            >
              {user ? "Dashboard" : "Login"}
            </Link>
            <ButtonLink href={enterHref} className="px-4 py-2 text-xs sm:px-5 sm:text-sm">
              {user ? "Open dashboard" : "Enter Event Care"}
            </ButtonLink>
          </div>
        </div>
      </header>

      <LandingHero enterHref={enterHref} signedIn={Boolean(user)} />

      <section className="mx-auto max-w-[1440px] px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <p className="text-center text-xs font-bold uppercase tracking-[0.25em] text-prowem-coral">
          Why Event Care
        </p>
        <h2 className="mt-3 text-center font-display text-2xl font-bold uppercase sm:text-3xl md:text-5xl">
          Never left alone after go-live
        </h2>
        <div className="mt-12 grid gap-5 md:grid-cols-3">
          {[
            {
              icon: Shield,
              title: "Operational clarity",
              body: "See readiness, blockers and next actions in seconds — not buried in tables.",
            },
            {
              icon: Radio,
              title: "Match-day confidence",
              body: "Live monitoring, incident context, and transparent support updates.",
            },
            {
              icon: LineChart,
              title: "Continuous improvement",
              body: "Post-event reports explain what happened and how to run the next one better.",
            },
          ].map((item) => (
            <GlassCard key={item.title}>
              <item.icon className="h-6 w-6 text-prowem-coral" />
              <h3 className="mt-4 font-display text-xl font-bold uppercase">{item.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-prowem-muted">{item.body}</p>
            </GlassCard>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-[1440px] px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <p className="text-center text-xs font-bold uppercase tracking-[0.25em] text-prowem-coral">
          Event lifecycle
        </p>
        <h2 className="mt-3 text-center font-display text-2xl font-bold uppercase sm:text-3xl md:text-5xl">
          Before · During · After
        </h2>
        <div className="mt-12 grid gap-5 lg:grid-cols-3">
          {beforeDuringAfter.map((block) => (
            <GlassCard key={block.phase} strong className="min-h-[280px]">
              <p className={`text-xs font-bold uppercase tracking-[0.2em] ${block.color}`}>
                {block.phase}
              </p>
              <p className="mt-3 font-display text-2xl font-bold uppercase text-white">
                {block.promise}
              </p>
              <ul className="mt-6 space-y-3">
                {block.items.map((item) => (
                  <li key={item} className="flex items-center gap-2 text-sm text-white/85">
                    <CheckCircle2 className="h-4 w-4 text-prowem-accent" />
                    {item}
                  </li>
                ))}
              </ul>
            </GlassCard>
          ))}
        </div>
      </section>

      <section className="mx-auto max-w-[1440px] px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <div className="grid gap-6 lg:grid-cols-2">
          <GlassCard glow="orange">
            <Activity className="h-6 w-6 text-prowem-orange" />
            <h3 className="mt-4 font-display text-2xl font-bold uppercase">Event Readiness</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              Teams, fixtures, venues, live score, streaming and graphics — scored so
              organizers know what is ready and what needs attention.
            </p>
          </GlassCard>
          <GlassCard glow="coral">
            <Headphones className="h-6 w-6 text-prowem-coral" />
            <h3 className="mt-4 font-display text-2xl font-bold uppercase">Match-Day Support</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              When something breaks, context is already attached: event, fixture, service
              and active incidents.
            </p>
          </GlassCard>
          <GlassCard glow="cyan">
            <Sparkles className="h-6 w-6 text-prowem-cyan" />
            <h3 className="mt-4 font-display text-2xl font-bold uppercase">Live Control</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              Start the event only when critical blockers are clear. Monitor live, next and
              delayed matches from one board.
            </p>
          </GlassCard>
          <GlassCard glow="purple">
            <LineChart className="h-6 w-6 text-prowem-purple" />
            <h3 className="mt-4 font-display text-2xl font-bold uppercase">Insights</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              SLA performance, incident mix and recommendations that turn every event into
              a better next event.
            </p>
          </GlassCard>
        </div>
      </section>

      <section className="mx-auto max-w-[1440px] px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <GlassCard strong className="overflow-hidden p-5 sm:p-8 md:p-12">
          <div className="pointer-events-none absolute -right-10 -top-10 h-56 w-56 rounded-full bg-prowem-coral/20 blur-[80px]" />
          <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-prowem-coral sm:text-xs">
            PROWEM Event Care
          </p>
          <h2 className="mt-3 max-w-3xl font-display text-2xl font-bold uppercase sm:text-3xl md:text-5xl">
            Premium operational support for high-value football events
          </h2>
          <p className="mt-4 max-w-2xl text-prowem-muted">
            Dedicated people and technology that stay with you before, during and after
            match day.
          </p>
          <div className="mt-8 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
            {careFeatures.map((feature) => (
              <div
                key={feature}
                className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-sm font-medium"
              >
                {feature}
              </div>
            ))}
          </div>
        </GlassCard>
      </section>

      <section className="mx-auto max-w-[1440px] px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <p className="text-center text-xs font-bold uppercase tracking-[0.25em] text-prowem-coral">
          Platform preview
        </p>
        <h2 className="mt-3 text-center font-display text-2xl font-bold uppercase sm:text-3xl md:text-5xl">
          One connected story
        </h2>
        <div className="mt-12 grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {previews.map((preview, index) => (
            <GlassCard key={preview.title} className="min-h-[140px]">
              <p className="text-xs text-prowem-muted">0{index + 1}</p>
              <h3 className="mt-2 font-display text-xl font-bold uppercase">{preview.title}</h3>
              <p className="mt-1 text-sm text-prowem-muted">{preview.note}</p>
            </GlassCard>
          ))}
        </div>
      </section>

      <section className="relative mx-auto max-w-[1440px] px-4 py-16 text-center sm:px-6 sm:py-24 lg:px-10">
        <div className="pointer-events-none absolute inset-x-0 bottom-0 -z-10 h-64 bg-gradient-to-t from-prowem-orange/20 via-transparent to-transparent" />
        <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-prowem-coral sm:text-xs">
          Ready to start?
        </p>
        <h2 className="mt-4 font-display text-3xl font-bold uppercase sm:text-4xl md:text-6xl">
          Ready for your next event?
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-sm text-white/80 sm:text-base">
          Your event deserves more than software. It deserves confidence.
        </p>
        <div className="mt-8 flex flex-col items-stretch justify-center gap-3 sm:mt-10 sm:flex-row sm:flex-wrap sm:items-center sm:gap-4">
          <ButtonLink href={enterHref} className="w-full sm:w-auto">
            {user ? "Open dashboard" : "Enter Event Care"}
          </ButtonLink>
          <ButtonLink href="/login" variant="ghost" className="w-full sm:w-auto">
            Sign in
          </ButtonLink>
        </div>
        <p className="mt-16 text-xs text-prowem-muted">
          PROWEM Event Care © 2026 — YOUR EVENT IS OUR EVENT.
        </p>
      </section>
    </div>
  );
}
