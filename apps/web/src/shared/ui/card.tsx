import { cn } from "@/shared/lib/cn";
import type { ReactNode } from "react";

export function GlassCard({
  children,
  className,
  strong,
  glow,
  as: Tag = "div",
}: {
  children: ReactNode;
  className?: string;
  strong?: boolean;
  glow?: "coral" | "green" | "cyan" | "purple" | "orange" | "none";
  as?: "div" | "section" | "article";
}) {
  const glowClass =
    glow === "coral"
      ? "shadow-glow-coral"
      : glow === "green"
        ? "shadow-[0_0_24px_rgba(57,255,106,0.25)]"
        : glow === "cyan"
          ? "shadow-[0_0_20px_rgba(0,212,255,0.25)]"
          : glow === "purple"
            ? "shadow-[0_0_20px_rgba(192,38,255,0.25)]"
            : glow === "orange"
              ? "shadow-[0_0_20px_rgba(255,122,24,0.25)]"
              : "";

  return (
    <Tag
      className={cn(
        strong ? "glass-panel-strong" : "glass-panel",
        "relative overflow-hidden p-5",
        glowClass,
        className,
      )}
    >
      {children}
    </Tag>
  );
}

export function Card({
  className,
  children,
}: {
  className?: string;
  children: React.ReactNode;
}) {
  return <GlassCard className={className}>{children}</GlassCard>;
}

export function CardTitle({ children }: { children: React.ReactNode }) {
  return (
    <h2 className="mb-3 text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-muted">
      {children}
    </h2>
  );
}
