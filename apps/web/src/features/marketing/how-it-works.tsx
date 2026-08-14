"use client";

import { useEffect, useState } from "react";
import Link from "next/link";
import {
  Activity,
  ArrowRight,
  Bell,
  CheckCircle2,
  CheckSquare,
  FileText,
  Home,
  LayoutGrid,
  MessageSquare,
  Radio,
  ShieldCheck,
  TriangleAlert,
  Users,
} from "lucide-react";
import { cn } from "@/shared/lib/cn";
import { ButtonLink } from "@/shared/ui/button";
import { GlassCard } from "@/shared/ui/card";

const sections = [
  { id: "journey", label: "Journey" },
  { id: "events", label: "Events" },
  { id: "home", label: "Event Home" },
  { id: "checklists", label: "Checklists" },
  { id: "live", label: "Live" },
  { id: "support", label: "Support" },
  { id: "report", label: "Report" },
  { id: "roles", label: "Roles" },
] as const;

const journey = [
  {
    id: "events",
    step: "01",
    phase: "Before",
    title: "Open My Events",
    body: "See every tournament you own — and which ones need attention before kickoff.",
  },
  {
    id: "home",
    step: "02",
    phase: "Before",
    title: "Read Event Home",
    body: "One command view: readiness score, blockers, next matches, and recent activity.",
  },
  {
    id: "checklists",
    step: "03",
    phase: "Before",
    title: "Clear the checklists",
    body: "Nine dimensions. A critical blocker stops go-live, even if the score looks fine.",
  },
  {
    id: "live",
    step: "04",
    phase: "During",
    title: "Go live when ready",
    body: "Start the event only when critical checks are clear. Then run live, next, and delayed matches.",
  },
  {
    id: "support",
    step: "05",
    phase: "During",
    title: "Stay in control",
    body: "Operations for on-pitch issues. Messages for support with SLA. Activity keeps the trail.",
  },
  {
    id: "report",
    step: "06",
    phase: "After",
    title: "Close with a report",
    body: "Kickoff snapshot, incident mix, SLA, and the next-event recommendations.",
  },
];

const dimensions = [
  "Teams",
  "Players",
  "Fixtures",
  "Referees",
  "Venues",
  "Staff",
  "Live score",
  "Streaming",
  "Graphics",
];

const teamActions = [
  "Verify payment",
  "Check in",
  "Approve roster",
  "Confirm eligibility",
  "Approve documents",
];

const screens = [
  { href: "#events", icon: LayoutGrid, label: "My Events", note: "Portfolio + attention" },
  { href: "#home", icon: Home, label: "Event Home", note: "Score and next actions" },
  { href: "#checklists", icon: CheckSquare, label: "Event Checklists", note: "Nine dimensions" },
  { href: "#live", icon: Radio, label: "Matches", note: "Go-live gate" },
  { href: "#checklists", icon: Users, label: "Teams", note: "Passport operations" },
  { href: "#support", icon: TriangleAlert, label: "Operations", note: "Incidents" },
  { href: "#support", icon: MessageSquare, label: "Messages", note: "Tickets + SLA" },
  { href: "#report", icon: Activity, label: "Activity", note: "Audit trail" },
  { href: "#report", icon: FileText, label: "Reports", note: "After the whistle" },
];

export function HowItWorksView({
  enterHref,
  signedIn,
}: {
  enterHref: string;
  signedIn: boolean;
}) {
  const [active, setActive] = useState<(typeof sections)[number]["id"]>("journey");
  const [role, setRole] = useState<"organizer" | "support">("organizer");

  useEffect(() => {
    const nodes = sections
      .map((section) => document.getElementById(section.id))
      .filter((node): node is HTMLElement => Boolean(node));
    if (nodes.length === 0) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((entry) => entry.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
        if (visible?.target.id) {
          setActive(visible.target.id as (typeof sections)[number]["id"]);
        }
      },
      { rootMargin: "-28% 0px -55% 0px", threshold: [0.15, 0.35, 0.6] },
    );

    nodes.forEach((node) => observer.observe(node));
    return () => observer.disconnect();
  }, []);

  return (
    <div className="relative overflow-hidden">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-black/70 backdrop-blur-xl supports-backdrop-filter:bg-black/55">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-3 sm:px-6 sm:py-4 lg:px-10">
          <Link href="/" className="font-display text-lg font-bold tracking-wide sm:text-xl">
            PROWEM <span className="text-prowem-coral">Event Care</span>
          </Link>
          <div className="flex items-center gap-2 sm:gap-3">
            <Link href="/" className="hidden text-sm text-prowem-muted hover:text-white sm:inline">
              Home
            </Link>
            <Link
              href={enterHref}
              className="hidden text-sm text-prowem-muted hover:text-white sm:inline"
            >
              {signedIn ? "Dashboard" : "Login"}
            </Link>
            <ButtonLink href={enterHref} className="px-4 py-2 text-xs sm:px-5 sm:text-sm">
              {signedIn ? "Open dashboard" : "Take Control"}
            </ButtonLink>
          </div>
        </div>
      </header>

      <nav
        aria-label="On this page"
        className="sticky top-[3.35rem] z-40 border-b border-white/10 bg-black/60 backdrop-blur-xl sm:top-[4.15rem]"
      >
        <div className="mx-auto flex max-w-7xl gap-2 overflow-x-auto px-4 py-2.5 [scrollbar-width:none] sm:px-6 lg:px-10 [&::-webkit-scrollbar]:hidden">
          {sections.map((section) => (
            <a
              key={section.id}
              href={`#${section.id}`}
              className={cn(
                "shrink-0 rounded-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide transition sm:text-xs",
                active === section.id
                  ? "border border-prowem-accent/40 bg-prowem-accent/10 text-prowem-accent"
                  : "text-white/55 hover:bg-white/5 hover:text-white",
              )}
            >
              {section.label}
            </a>
          ))}
        </div>
      </nav>

      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_20%_0%,rgba(57,255,106,0.16),transparent_40%),radial-gradient(circle_at_90%_20%,rgba(0,212,255,0.12),transparent_35%)]" />
        <div className="relative mx-auto max-w-7xl px-4 pb-12 pt-12 sm:px-6 sm:pb-16 sm:pt-16 lg:px-10">
          <p className="text-[10px] font-bold uppercase tracking-[0.28em] text-prowem-accent sm:text-xs">
            How it works
          </p>
          <h1 className="mt-3 max-w-3xl font-display text-4xl font-bold leading-[0.95] tracking-wide text-white sm:text-6xl md:text-7xl">
            See the whole event.
            <br />
            <span className="text-prowem-accent text-glow-green">Act on what matters.</span>
          </h1>
          <p className="mt-5 max-w-2xl text-sm leading-relaxed text-white/70 sm:text-base">
            Event Care is the operational layer around a football tournament — readiness,
            live control, incidents, support, and the post-event story. Same screens you
            use in the dashboard. Not a scoreboard.
          </p>
          <div className="mt-8 flex flex-col gap-3 sm:flex-row sm:items-center">
            <ButtonLink href="#journey" variant="accent" className="w-full sm:w-auto">
              Walk the journey
            </ButtonLink>
            <ButtonLink href={enterHref} variant="ghost" className="w-full sm:w-auto">
              {signedIn ? "Open dashboard" : "Sign in"}
            </ButtonLink>
          </div>
        </div>
      </section>

      <section id="journey" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-12 sm:px-6 sm:py-16 lg:px-10">
        <SectionEyebrow>The path</SectionEyebrow>
        <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-4xl">
          Before · During · After
        </h2>
        <p className="mt-3 max-w-2xl text-sm text-prowem-muted">
          Follow the same loop organizers and support run on every event — from first
          checklist to the report after the final whistle.
        </p>
        <ol className="mt-10 grid gap-4 md:grid-cols-2 xl:grid-cols-3">
          {journey.map((item) => (
            <li key={item.step}>
              <a href={`#${item.id}`} className="block h-full">
                <GlassCard strong className="h-full transition hover:border-white/25">
                  <div className="flex items-center justify-between">
                    <span className="font-display text-2xl font-bold text-white/25">{item.step}</span>
                    <span
                      className={cn(
                        "rounded-full px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider",
                        item.phase === "Before" && "bg-prowem-orange/15 text-prowem-orange",
                        item.phase === "During" && "bg-prowem-coral/15 text-prowem-coral",
                        item.phase === "After" && "bg-prowem-cyan/15 text-prowem-cyan",
                      )}
                    >
                      {item.phase}
                    </span>
                  </div>
                  <h3 className="mt-4 font-display text-xl font-bold uppercase">{item.title}</h3>
                  <p className="mt-2 text-sm leading-relaxed text-prowem-muted">{item.body}</p>
                  <p className="mt-4 inline-flex items-center gap-1 text-xs font-semibold text-prowem-accent">
                    Jump to this step <ArrowRight className="h-3.5 w-3.5" />
                  </p>
                </GlassCard>
              </a>
            </li>
          ))}
        </ol>
      </section>

      <section className="mx-auto max-w-7xl px-4 pb-4 sm:px-6 lg:px-10">
        <div className="grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
          {screens.map((screen) => (
            <a key={screen.label} href={screen.href} className="group">
              <GlassCard className="flex items-center gap-3 py-4 transition group-hover:border-white/25">
                <screen.icon className="h-5 w-5 text-prowem-accent" />
                <div>
                  <p className="font-semibold">{screen.label}</p>
                  <p className="text-xs text-prowem-muted">{screen.note}</p>
                </div>
              </GlassCard>
            </a>
          ))}
        </div>
      </section>

      <section id="events" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <div className="grid items-center gap-8 lg:grid-cols-[1.05fr_0.95fr]">
          <div>
            <SectionEyebrow>01 · My Events</SectionEyebrow>
            <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-5xl">
              Your portfolio, ranked by attention
            </h2>
            <p className="mt-4 text-sm leading-relaxed text-white/70 sm:text-base">
              After sign-in you land on My Events. Filter All, Needs Attention, Preparing,
              Ready, Completed, or Cancelled. Search by name. Attention is calculated by
              the API from readiness checks and open incidents or tickets — the board does
              not invent it.
            </p>
            <ul className="mt-6 space-y-3 text-sm">
              {[
                "Each card shows venue, dates, status, and open issues.",
                "Needs Attention surfaces events that are not safe to ignore.",
                "Open an event and the sidebar switches to that event’s command set.",
              ].map((line) => (
                <li key={line} className="flex gap-2 text-white/85">
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-prowem-accent" />
                  {line}
                </li>
              ))}
            </ul>
          </div>
          <GlassCard strong className="p-4 sm:p-6">
            <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-muted">
              My Events
            </p>
            <div className="mt-4 space-y-3">
              {[
                { name: "Vienna Youth Cup", ref: "VSC-2026", status: "Live", tone: "text-prowem-coral", note: "Match day in progress" },
                { name: "Alpine Cup", ref: "ALP-2026", status: "Blocked", tone: "text-prowem-warning", note: "Critical checklist open" },
                { name: "Marche Cup", ref: "MRC-2026", status: "Ready", tone: "text-prowem-accent", note: "Clear to go live" },
              ].map((event) => (
                <div key={event.ref} className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
                  <div className="flex items-center justify-between gap-3">
                    <p className="font-semibold">{event.name}</p>
                    <span className={cn("text-[11px] font-bold uppercase", event.tone)}>{event.status}</span>
                  </div>
                  <p className="mt-1 text-xs text-prowem-muted">
                    {event.ref} · {event.note}
                  </p>
                </div>
              ))}
            </div>
          </GlassCard>
        </div>
      </section>

      <section id="home" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <div className="grid items-center gap-8 lg:grid-cols-[0.95fr_1.05fr]">
          <GlassCard glow="green" strong className="order-2 p-5 lg:order-1 sm:p-6">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-muted">
                  Event Home
                </p>
                <p className="mt-2 font-display text-2xl font-bold uppercase">Vienna Youth Cup</p>
              </div>
              <div className="grid h-24 w-24 place-items-center rounded-full border-4 border-prowem-accent/30 bg-black/40">
                <div className="text-center">
                  <p className="font-display text-2xl font-bold text-prowem-accent">92%</p>
                  <p className="text-[9px] uppercase tracking-wider text-white/50">Readiness</p>
                </div>
              </div>
            </div>
            <div className="mt-5 grid grid-cols-2 gap-3 text-sm">
              <div className="rounded-xl border border-white/10 bg-black/20 p-3">
                <p className="text-[10px] uppercase text-prowem-muted">Needs attention</p>
                <p className="mt-1 font-semibold">3 items</p>
              </div>
              <div className="rounded-xl border border-white/10 bg-black/20 p-3">
                <p className="text-[10px] uppercase text-prowem-muted">Next matches</p>
                <p className="mt-1 font-semibold">Pitch A · 14:00</p>
              </div>
            </div>
          </GlassCard>
          <div className="order-1 lg:order-2">
            <SectionEyebrow>02 · Event Home</SectionEyebrow>
            <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-5xl">
              The command center
            </h2>
            <p className="mt-4 text-sm leading-relaxed text-white/70 sm:text-base">
              Event Home is the first screen inside an event. Readiness score and status,
              critical blockers, actions required, needs-attention cards, upcoming matches,
              and recent activity. From here you jump to checklists, live control, an
              incident, or a ticket — you never hunt through tables.
            </p>
            <p className="mt-4 text-sm text-white/70">
              When something changes on the event channel, this view refreshes. After a
              reconnect, REST is still the source of truth.
            </p>
          </div>
        </div>
      </section>

      <section id="checklists" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <SectionEyebrow>03 · Event Checklists & Teams</SectionEyebrow>
        <h2 className="mt-3 max-w-3xl font-display text-3xl font-bold uppercase sm:text-5xl">
          Ready means every dimension is clear
        </h2>
        <p className="mt-4 max-w-2xl text-sm leading-relaxed text-white/70 sm:text-base">
          Event Checklists score nine dimensions. A single critical blocked check can
          block the event independently of the overall score. Organizers run team
          operations. Support can override a check — with a reason. Organizers cannot.
        </p>
        <div className="mt-8 grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-9">
          {dimensions.map((item) => (
            <GlassCard key={item} className="flex min-h-20 items-center justify-center px-2 py-3 text-center">
              <p className="text-[11px] font-semibold uppercase tracking-wide">{item}</p>
            </GlassCard>
          ))}
        </div>
        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <GlassCard glow="cyan">
            <Users className="h-5 w-5 text-prowem-cyan" />
            <h3 className="mt-3 font-display text-xl font-bold uppercase">Team passport</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              Each team has blockers and a short list of operations. Completing one writes
              an audit fact, updates readiness, and broadcasts to everyone on the event.
            </p>
            <div className="mt-4 flex flex-wrap gap-2">
              {teamActions.map((action) => (
                <span
                  key={action}
                  className="rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs"
                >
                  {action}
                </span>
              ))}
            </div>
          </GlassCard>
          <GlassCard glow="green">
            <ShieldCheck className="h-5 w-5 text-prowem-accent" />
            <h3 className="mt-3 font-display text-xl font-bold uppercase">The go-live rule</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              Live Control will not start the event while a critical blocker is open. The
              API returns Event not ready, with the blockers attached — so the board and
              the rule stay aligned.
            </p>
          </GlassCard>
        </div>
      </section>

      <section id="live" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <div className="grid items-start gap-8 lg:grid-cols-2">
          <div>
            <SectionEyebrow>04 · Matches</SectionEyebrow>
            <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-5xl">
              Live control on match day
            </h2>
            <p className="mt-4 text-sm leading-relaxed text-white/70 sm:text-base">
              Matches is live control: event progress, live / next / delayed fixtures,
              operational incidents, and system status. Only manage roles can change event
              status. Support agents see the board but do not start or stop the event, and
              they do not run team actions.
            </p>
          </div>
          <div className="grid gap-3 sm:grid-cols-3">
            {[
              { label: "Live", value: "Pitch A", tone: "glow-coral" as const, copy: "In play" },
              { label: "Next", value: "14:30", tone: "glow-green" as const, copy: "Semi final" },
              { label: "Delayed", value: "0", tone: "none" as const, copy: "On schedule" },
            ].map((card) => (
              <GlassCard key={card.label} glow={card.tone === "none" ? undefined : card.tone === "glow-coral" ? "coral" : "green"} className="text-center">
                <p className="text-[10px] font-bold uppercase tracking-wider text-prowem-muted">
                  {card.label}
                </p>
                <p className="mt-2 font-display text-2xl font-bold">{card.value}</p>
                <p className="mt-1 text-xs text-prowem-muted">{card.copy}</p>
              </GlassCard>
            ))}
          </div>
        </div>
      </section>

      <section id="support" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <SectionEyebrow>05 · Operations & Messages</SectionEyebrow>
        <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-5xl">
          Issues stay in context
        </h2>
        <p className="mt-4 max-w-2xl text-sm leading-relaxed text-white/70 sm:text-base">
          When something breaks, Event Care already knows the event, fixture, and service.
          Two lanes stay separate so the right people act.
        </p>
        <div className="mt-8 grid gap-4 lg:grid-cols-2">
          <GlassCard glow="orange">
            <TriangleAlert className="h-5 w-5 text-prowem-orange" />
            <h3 className="mt-3 font-display text-xl font-bold uppercase">Operations</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              Organizers own operational incidents. They can report a technical issue;
              only support roles work technical incidents. Status changes are audited and
              broadcast on the event channel.
            </p>
          </GlassCard>
          <GlassCard glow="purple">
            <MessageSquare className="h-5 w-5 text-prowem-purple" />
            <h3 className="mt-3 font-display text-xl font-bold uppercase">Messages</h3>
            <p className="mt-2 text-sm text-prowem-muted">
              Open a ticket with category and requested urgency. Priority and SLA are
              calculated by the API. A live technical incident opens one P1 ticket
              automatically. Organizers never see internal notes, and cannot assign or
              close tickets from the inside.
            </p>
          </GlassCard>
        </div>
        <GlassCard className="mt-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
          <div className="flex items-start gap-3">
            <Bell className="mt-0.5 h-5 w-5 text-prowem-cyan" />
            <div>
              <p className="font-semibold">Inbox + activity</p>
              <p className="text-sm text-prowem-muted">
                Notifications land on your user channel. Activity is the event’s timeline.
                Both refresh live; both re-read from the API after reconnect.
              </p>
            </div>
          </div>
        </GlassCard>
      </section>

      <section id="report" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <SectionEyebrow>06 · Reports</SectionEyebrow>
        <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-5xl">
          Every event teaches the next one
        </h2>
        <p className="mt-4 max-w-2xl text-sm leading-relaxed text-white/70 sm:text-base">
          The post-event report is not a dump. It snapshots readiness at kickoff, counts
          operational vs technical incidents, records delays, and shows SLA compliance
          when tickets were measurable. Recommendations are deterministic from that data.
        </p>
        <div className="mt-8 grid gap-4 md:grid-cols-3">
          {[
            { title: "Kickoff readiness", value: "Snapshot", note: "Score and status before the first whistle" },
            { title: "Incident mix", value: "Ops + tech", note: "Totals, cancelled matches, average delay" },
            { title: "Support SLA", value: "Compliance", note: "P1 count and average resolution" },
          ].map((card) => (
            <GlassCard key={card.title} glow="cyan">
              <p className="text-[10px] font-bold uppercase tracking-wider text-prowem-cyan">
                {card.title}
              </p>
              <p className="mt-2 font-display text-2xl font-bold uppercase">{card.value}</p>
              <p className="mt-2 text-sm text-prowem-muted">{card.note}</p>
            </GlassCard>
          ))}
        </div>
      </section>

      <section id="roles" className="scroll-mt-32 mx-auto max-w-7xl px-4 py-14 sm:px-6 sm:py-20 lg:px-10">
        <SectionEyebrow>Who does what</SectionEyebrow>
        <h2 className="mt-3 font-display text-3xl font-bold uppercase sm:text-5xl">
          The same event. Different controls.
        </h2>
        <div className="mt-6 inline-flex rounded-full border border-white/10 bg-black/40 p-1">
          {(["organizer", "support"] as const).map((value) => (
            <button
              key={value}
              type="button"
              onClick={() => setRole(value)}
              className={cn(
                "rounded-full px-4 py-2 text-sm font-semibold capitalize transition",
                role === value ? "bg-prowem-accent text-prowem-bg" : "text-white/60 hover:text-white",
              )}
            >
              {value === "organizer" ? "Organizer" : "Support"}
            </button>
          ))}
        </div>
        <GlassCard strong className="mt-6">
          {role === "organizer" ? (
            <RoleList
              title="You run your own events"
              items={[
                "See only your customer’s events.",
                "Complete team passport operations.",
                "Manage operational incidents and report technical ones.",
                "Open customer tickets and reply in the public thread.",
                "Cannot override readiness, administer tickets, or read internal notes.",
              ]}
            />
          ) : (
            <RoleList
              title="You cover every event"
              items={[
                "Work technical incidents and ticket administration.",
                "Assign, reprioritize, resolve, and write internal notes.",
                "Support agents do not transition events or run team actions.",
                "Support leads and admins can manage and support.",
                "The API still returns 403 if a hidden control is forced.",
              ]}
            />
          )}
        </GlassCard>
      </section>

      <section className="relative mx-auto max-w-7xl px-4 py-16 text-center sm:px-6 sm:py-24 lg:px-10">
        <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-prowem-accent sm:text-xs">
          Ready to start?
        </p>
        <h2 className="mt-4 font-display text-3xl font-bold uppercase sm:text-5xl">
          Take control of the next event
        </h2>
        <p className="mx-auto mt-4 max-w-xl text-sm text-white/70">
          Sign in, open My Events, and work the same path this page just walked.
        </p>
        <div className="mt-8 flex flex-col items-stretch justify-center gap-3 sm:flex-row sm:items-center">
          <ButtonLink href={enterHref} variant="accent" className="w-full sm:w-auto">
            {signedIn ? "Open dashboard" : "Take Control"}
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

function SectionEyebrow({ children }: { children: string }) {
  return (
    <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-prowem-accent sm:text-xs">
      {children}
    </p>
  );
}

function RoleList({ title, items }: { title: string; items: string[] }) {
  return (
    <div>
      <h3 className="font-display text-2xl font-bold uppercase">{title}</h3>
      <ul className="mt-5 space-y-3">
        {items.map((item) => (
          <li key={item} className="flex gap-2 text-sm text-white/85">
            <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-prowem-accent" />
            {item}
          </li>
        ))}
      </ul>
    </div>
  );
}
