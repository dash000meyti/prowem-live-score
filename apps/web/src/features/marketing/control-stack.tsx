import { CheckCircle2 } from "lucide-react";
import { ButtonLink } from "@/shared/ui/button";

const tasks = [
  {
    title: "Supply and check equipment",
    note: "Cameras, comms, power, and spare storage signed off.",
  },
  {
    title: "Test the broadcast",
    note: "Signal path, delay, and backup feed confirmed on site.",
  },
  {
    title: "Confirm staff are present",
    note: "Crew, officials, and pitch-side roles checked in.",
  },
  {
    title: "Make sure instructions reached specialists",
    note: "Every brief delivered, acknowledged, and owned.",
  },
  {
    title: "Review first graphics and content",
    note: "Approve the pack — or send a revision before kickoff.",
  },
  {
    title: "Follow up until it is done",
    note: "Then give the next order. Nothing sits unowned.",
  },
];

export function ControlStackSection({
  enterHref,
  signedIn,
}: {
  enterHref: string;
  signedIn: boolean;
}) {
  return (
    <section className="relative overflow-hidden border-y border-white/10">
      <div className="absolute inset-0 bg-[#0a0c12]" />
      <div className="pointer-events-none absolute inset-0 bg-[radial-gradient(ellipse_at_50%_-10%,rgba(255,122,24,0.18),transparent_52%),radial-gradient(ellipse_at_80%_90%,rgba(255,107,61,0.1),transparent_45%)]" />
      <div className="pointer-events-none absolute inset-x-0 top-0 h-px bg-linear-to-r from-transparent via-prowem-orange/50 to-transparent" />
      <div className="pointer-events-none absolute inset-x-0 bottom-0 h-px bg-linear-to-r from-transparent via-prowem-coral/40 to-transparent" />

      <div className="relative mx-auto max-w-7xl px-4 py-20 sm:px-6 sm:py-28 lg:px-10">
        <p className="text-center text-[10px] font-bold uppercase tracking-[0.28em] text-prowem-orange sm:text-xs">
          What it takes
        </p>
        <h2 className="mx-auto mt-3 max-w-3xl text-center font-display text-3xl font-bold leading-tight tracking-wide text-white sm:text-4xl md:text-5xl">
          To Run a Reliable Sports Event, You Need To:
        </h2>

        <div className="relative mx-auto mt-14 w-full max-w-lg">
          <div className="pointer-events-none absolute left-1/2 top-8 h-64 w-64 -translate-x-1/2 rounded-full bg-prowem-orange/15 blur-[90px]" />
          <div className="relative space-y-[-1.15rem] sm:space-y-[-1.35rem]">
            {tasks.map((task, index) => (
              <article
                key={task.title}
                className="relative border border-white/12 bg-[#12161e]/90 px-5 py-4 shadow-[0_18px_40px_rgba(0,0,0,0.45)] backdrop-blur-xl sm:px-6 sm:py-5"
                style={{
                  zIndex: index + 1,
                  borderRadius: "1rem",
                  transform: `rotate(${(index - 2.5) * 1.15}deg) translateX(${(index % 2 === 0 ? -1 : 1) * (6 + index)}px)`,
                }}
              >
                <div className="flex items-start gap-3">
                  <CheckCircle2 className="mt-0.5 h-4 w-4 shrink-0 text-prowem-orange" />
                  <div>
                    <h3 className="font-display text-lg font-bold uppercase leading-snug sm:text-xl">
                      {task.title}
                    </h3>
                    <p className="mt-1 text-sm leading-relaxed text-white/65">{task.note}</p>
                  </div>
                </div>
              </article>
            ))}
          </div>
        </div>

        <div className="mt-16 text-center">
          <p className="text-sm font-medium uppercase tracking-[0.22em] text-white/70">
            All Under Control With
          </p>
          <p className="mt-3 font-display text-3xl font-bold tracking-wide text-white sm:text-4xl">
            PROWEM <span className="text-prowem-accent text-glow-green">Event Care</span>
          </p>
          <div className="mt-7">
            <ButtonLink href={enterHref} variant="accent" className="min-w-44">
              {signedIn ? "Open dashboard" : "Try for Free"}
            </ButtonLink>
          </div>
        </div>
      </div>
    </section>
  );
}
