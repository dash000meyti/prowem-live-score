import Image from "next/image";
import { CheckCircle2 } from "lucide-react";
import { cn } from "@/shared/lib/cn";
import { ButtonLink } from "@/shared/ui/button";
import { GlassCard } from "@/shared/ui/card";

const pillars = [
  { label: "Event Care", active: true },
  { label: "Readiness", active: false },
  { label: "Live Control", active: false },
  { label: "Support", active: false },
];

export function LandingHero({
  enterHref,
  signedIn,
}: {
  enterHref: string;
  signedIn: boolean;
}) {
  return (
    <section className="relative min-h-svh overflow-hidden">
      <Image
        src="/images/hero-command-center.jpg"
        alt=""
        fill
        priority
        className="object-cover object-center opacity-40"
      />
      <div className="absolute inset-0 bg-linear-to-r from-black/80 via-black/55 to-black/45" />
      <div className="absolute inset-0 bg-[radial-gradient(circle_at_70%_45%,rgba(57,255,106,0.12),transparent_45%)]" />
      <div className="absolute inset-0 bg-linear-to-t from-prowem-bg via-black/25 to-black/55" />

      <div className="relative mx-auto grid min-h-svh max-w-7xl items-center gap-8 px-4 pb-14 pt-10 sm:gap-10 sm:px-6 sm:pb-16 sm:pt-14 lg:grid-cols-[1.05fr_0.95fr]">
        <div className="order-2 text-center lg:order-1 lg:text-left">
          <p>
          PROWEM Event Guardian
          </p>
          <h1 className="font-display text-[2.6rem] font-bold leading-[0.95] tracking-wide text-white sm:text-6xl md:text-7xl">
          verything at Your
            <br />
            <span className="text-prowem-accent text-glow-green">
            Command</span>
          </h1>
          <p className="mx-auto mt-5 max-w-lg text-sm leading-relaxed text-white/70 sm:mt-6 md:text-base lg:mx-0">
          An integrated system for preparing, managing, and improving sports events.
          </p>

          <div className="mx-auto mt-6 grid w-fit grid-cols-2 gap-2 sm:mt-8 sm:flex sm:flex-wrap sm:justify-center sm:gap-3 lg:mx-0 lg:justify-start">
            {pillars.map((item) => (
              <div
                key={item.label}
                className={cn(
                  "glass-panel flex min-w-0 flex-col items-center gap-2 px-3 py-3 text-center sm:min-w-30 sm:px-4",
                  item.active && "neon-border-green",
                )}
              >
                <span
                  className={cn(
                    "h-2.5 w-2.5 rounded-full",
                    item.active ? "bg-prowem-accent shadow-glow-sm" : "bg-white/30",
                  )}
                />
                <span className="text-[10px] font-semibold uppercase tracking-wide text-white/80 sm:text-[11px]">
                  {item.label}
                </span>
              </div>
            ))}
          </div>

          <div className="mt-6 flex flex-col items-center gap-3 sm:mt-8 sm:flex-row sm:flex-wrap sm:justify-center sm:gap-4 lg:justify-start">
            <ButtonLink href={enterHref} variant="accent" className="w-full sm:w-auto">
              {signedIn ? "Go to dashboard" : "Take Control"}
            </ButtonLink>
            <ButtonLink href="/how-it-works" variant="ghost" className="w-full sm:w-auto">
              How It Works
            </ButtonLink>
          </div>
        </div>

        <div className="relative order-1 mx-auto w-full max-w-sm lg:order-2 lg:mx-0 lg:max-w-none">
          <div className="pointer-events-none absolute left-1/2 top-1/2 h-[85%] w-[85%] -translate-x-1/2 -translate-y-1/2 animate-pulse-glow rounded-full bg-[radial-gradient(circle,rgba(57,255,106,0.28),transparent_65%)]" />
          <Image
            src="/images/hero-control-split.png"
            alt=""
            width={400}
            height={814}
            priority
            unoptimized
            className="relative z-0 mx-auto h-auto w-full max-w-[168px] bg-transparent sm:max-w-[200px] lg:max-w-xs"
          />
          <GlassCard glow="green" className="absolute left-0 top-4 z-10 w-32 animate-float p-2 sm:left-2 sm:top-8 sm:w-40 lg:w-44 lg:p-3">
            <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-prowem-accent sm:text-xs">
              <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
              Ready
            </p>
            <p className="mt-1 text-xs text-white/80">Kickoff cleared</p>
          </GlassCard>
          <GlassCard glow="cyan" className="absolute right-0 top-16 z-10 w-32 animate-float-delayed p-2 sm:top-24 sm:w-40 lg:w-44 lg:p-3">
            <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-prowem-cyan sm:text-xs">
              <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
              All Clear
            </p>
            <p className="mt-1 text-xs text-white/80">No blockers live</p>
          </GlassCard>
          <GlassCard glow="green" className="absolute bottom-10 left-0 z-10 w-36 animate-float p-2 sm:bottom-20 sm:left-2 sm:w-44 lg:w-48 lg:p-3">
            <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-prowem-accent sm:text-xs">
              <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
              Issue Resolved
            </p>
            <p className="mt-1 text-xs text-white/80">Back on the pitch</p>
          </GlassCard>
          <GlassCard glow="cyan" className="absolute bottom-2 right-0 z-10 w-36 animate-float-delayed p-2 sm:bottom-8 sm:w-44 lg:w-48 lg:p-3">
            <p className="flex items-center gap-1.5 text-[11px] font-bold uppercase tracking-wider text-prowem-cyan sm:text-xs">
              <CheckCircle2 className="h-3.5 w-3.5 shrink-0" />
              Event Report
            </p>
            <p className="mt-1 text-xs text-white/80">After the whistle</p>
          </GlassCard>
        </div>
      </div>
    </section>
  );
}
