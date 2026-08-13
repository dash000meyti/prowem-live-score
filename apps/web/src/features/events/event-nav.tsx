"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import { cn } from "@/shared/lib/cn";

const links = [
  ["", "Home"],
  ["/readiness", "Readiness"],
  ["/teams", "Teams"],
  ["/live", "Live"],
  ["/incidents", "Incidents"],
  ["/tickets", "Tickets"],
  ["/activity", "Activity"],
  ["/report", "Report"],
] as const;

export function EventNav({ eventId }: { eventId: string }) {
  const pathname = usePathname();
  const base = `/events/${eventId}`;

  return (
    <nav className="event-context-nav mb-6 items-center gap-1 overflow-x-auto pb-1 [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
      {links.map(([path, label]) => {
        const href = `${base}${path}`;
        const active = path === "" ? pathname === base : pathname.startsWith(href);
        return (
          <Link
            key={href}
            href={href}
            className={cn(
              "shrink-0 rounded-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide transition sm:text-xs",
              active
                ? "border border-prowem-coral/30 bg-prowem-coral/10 text-prowem-coral"
                : "text-prowem-muted hover:bg-white/5 hover:text-white",
            )}
          >
            {label}
          </Link>
        );
      })}
    </nav>
  );
}
