import Link from "next/link";
import { ArrowRight, Play } from "lucide-react";

const beats = [
  { n: "01", label: "My Events" },
  { n: "02", label: "Event Home" },
  { n: "03", label: "Checklists" },
  { n: "04", label: "Live" },
  { n: "05", label: "Support" },
  { n: "06", label: "Report" },
];

export function HowItWorksCta() {
  return (
    <section className="relative overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(circle_at_50%_120%,rgba(57,255,106,0.22),transparent_55%)]" />
      <div className="relative mx-auto max-w-7xl px-4 py-10 sm:px-6 sm:py-14 lg:px-10">
        <Link
          href="/how-it-works"
          className="group relative block overflow-hidden rounded-[2rem] border border-prowem-accent/35 bg-black/50 p-8 shadow-[0_0_60px_rgba(57,255,106,0.18)] transition hover:border-prowem-accent/70 hover:shadow-[0_0_80px_rgba(57,255,106,0.32)] sm:p-12"
        >
          <div className="pointer-events-none absolute -left-16 top-1/2 h-56 w-56 -translate-y-1/2 rounded-full bg-prowem-accent/20 blur-[90px] transition group-hover:bg-prowem-accent/30" />
          <div className="relative flex flex-col items-start gap-8 lg:flex-row lg:items-center lg:justify-between">
            <div className="max-w-2xl">
              <p className="flex items-center gap-2 text-[10px] font-bold uppercase tracking-[0.28em] text-prowem-accent sm:text-xs">
                <span className="grid h-6 w-6 place-items-center rounded-full bg-prowem-accent text-prowem-bg">
                  <Play className="h-3 w-3 fill-current" />
                </span>
                The playbook
              </p>
              <h2 className="mt-4 font-display text-3xl font-bold leading-[0.95] tracking-wide text-white sm:text-5xl md:text-6xl">
                See how control
                <br />
                <span className="text-prowem-accent text-glow-green">actually works.</span>
              </h2>
              <p className="mt-4 max-w-lg text-sm text-white/65 sm:text-base">
                Six screens. One path. From first checklist to the report after the whistle.
              </p>
            </div>
            <span className="btn-accent-glow inline-flex shrink-0 items-center gap-2 px-7 py-4 text-base">
              How It Works
              <ArrowRight className="h-5 w-5 transition group-hover:translate-x-1" />
            </span>
          </div>
          <ol className="relative mt-10 grid grid-cols-2 gap-2 sm:grid-cols-3 lg:grid-cols-6">
            {beats.map((beat) => (
              <li
                key={beat.n}
                className="rounded-2xl border border-white/10 bg-white/5 px-3 py-3 text-left"
              >
                <span className="block font-display text-lg font-bold text-prowem-accent/80">
                  {beat.n}
                </span>
                <span className="mt-1 block text-xs font-semibold uppercase tracking-wide text-white/80">
                  {beat.label}
                </span>
              </li>
            ))}
          </ol>
        </Link>
      </div>
    </section>
  );
}
