import { cn } from "@/shared/lib/cn";

type Tone =
  | "muted"
  | "success"
  | "warning"
  | "danger"
  | "info"
  | "coral"
  | "purple"
  | "orange";

const tones: Record<Tone, string> = {
  muted: "bg-white/5 text-prowem-muted border-white/10",
  success: "bg-prowem-success/10 text-prowem-success border-prowem-success/30",
  warning: "bg-prowem-warning/10 text-prowem-warning border-prowem-warning/30",
  danger: "bg-prowem-danger/10 text-prowem-danger border-prowem-danger/30",
  info: "bg-prowem-cyan/10 text-prowem-cyan border-prowem-cyan/30",
  coral: "bg-prowem-coral/10 text-prowem-coral border-prowem-coral/30",
  purple: "bg-prowem-purple/10 text-prowem-purple border-prowem-purple/30",
  orange: "bg-prowem-orange/10 text-prowem-orange border-prowem-orange/30",
};

const valueTone: Record<string, Tone> = {
  ready: "success",
  warning: "warning",
  blocked: "danger",
  preparing: "muted",
  live: "danger",
  completed: "info",
  cancelled: "muted",
  critical: "danger",
  high: "orange",
  medium: "warning",
  low: "muted",
  p1: "danger",
  p2: "orange",
  p3: "info",
  p4: "muted",
  open: "coral",
  acknowledged: "purple",
  in_progress: "info",
  resolved: "success",
  waiting: "warning",
  reopened: "orange",
  on_track: "success",
  approaching: "warning",
  breached: "danger",
  met: "success",
  operational: "muted",
  technical: "info",
};

export function Badge({
  value,
  tone,
  children,
  className,
}: {
  value?: string;
  tone?: Tone;
  children?: React.ReactNode;
  className?: string;
}) {
  const resolved = tone ?? (value ? valueTone[value] : undefined) ?? "muted";
  const label = children ?? value?.replaceAll("_", " ");

  return (
    <span
      className={cn(
        "inline-flex items-center gap-1 rounded-full border px-2.5 py-0.5 text-xs font-semibold uppercase tracking-wide",
        tones[resolved],
        className,
      )}
    >
      {label}
    </span>
  );
}
