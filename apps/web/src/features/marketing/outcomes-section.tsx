import { Database, HeartHandshake, ShieldCheck, Sparkles } from "lucide-react";

const outcomes = [
  {
    icon: ShieldCheck,
    title: "Risk Reduction & Trust",
    line: "Nothing critical stays unseen.",
    glow: "rgba(57,255,106,0.35)",
    iconClass: "text-prowem-accent",
  },
  {
    icon: HeartHandshake,
    title: "Client Retention",
    line: "A calm event is one they book again.",
    glow: "rgba(0,212,255,0.35)",
    iconClass: "text-prowem-cyan",
  },
  {
    icon: Sparkles,
    title: "User Satisfaction",
    line: "Every role knows the next step.",
    glow: "rgba(192,38,255,0.35)",
    iconClass: "text-prowem-purple",
  },
  {
    icon: Database,
    title: "Data for the next event",
    line: "Every close leaves a clearer plan.",
    glow: "rgba(255,122,24,0.35)",
    iconClass: "text-prowem-orange",
  },
];

export function OutcomesSection() {
  return (
    <section className="relative overflow-hidden">
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_20%_0%,rgba(57,255,106,0.12),transparent_45%),radial-gradient(ellipse_at_90%_80%,rgba(0,212,255,0.1),transparent_40%)]" />
      <div className="relative mx-auto max-w-7xl px-4 py-16 sm:px-6 sm:py-24 lg:px-10">
        <p className="text-center text-[10px] font-bold uppercase tracking-[0.28em] text-prowem-accent sm:text-xs">
          What you actually get
        </p>
        <h2 className="mx-auto mt-3 max-w-2xl text-center font-display text-3xl font-bold leading-tight tracking-wide text-white sm:text-4xl md:text-5xl">
          Trust. Repeat business. A better next event.
        </h2>
        <div className="mt-12 grid gap-4 sm:grid-cols-2">
          {outcomes.map((item) => (
            <article
              key={item.title}
              className="group relative overflow-hidden rounded-3xl border border-white/12 bg-white/[0.04] p-6 backdrop-blur-xl transition hover:border-white/25 sm:p-8"
            >
              <div
                className="pointer-events-none absolute -right-8 -top-8 h-32 w-32 rounded-full opacity-0 blur-2xl transition group-hover:opacity-100"
                style={{ background: item.glow }}
              />
              <div
                className="grid h-12 w-12 place-items-center rounded-2xl border border-white/10 bg-black/30"
                style={{ boxShadow: `0 0 24px ${item.glow}` }}
              >
                <item.icon className={`h-6 w-6 ${item.iconClass}`} />
              </div>
              <h3 className="mt-5 font-display text-2xl font-bold uppercase leading-snug">
                {item.title}
              </h3>
              <p className="mt-2 text-sm text-white/65">{item.line}</p>
            </article>
          ))}
        </div>
      </div>
    </section>
  );
}
