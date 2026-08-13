"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { Bell, Menu, X } from "lucide-react";
import { useState } from "react";
import { useSession } from "@/shared/auth/session-context";
import { roleLabel } from "@/shared/auth/roles";
import { useUserRealtime } from "@/shared/realtime/hooks";
import { cn } from "@/shared/lib/cn";

const links = [
  { href: "/events", label: "Events" },
  { href: "/notifications", label: "Inbox" },
];

export function AppShell({ children }: { children: React.ReactNode }) {
  const user = useSession();
  const router = useRouter();
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  const [menuPath, setMenuPath] = useState(pathname);
  useUserRealtime(user.id);

  if (menuPath !== pathname) {
    setMenuPath(pathname);
    setMenuOpen(false);
  }

  async function logout() {
    await fetch("/api/auth/logout", { method: "POST" });
    router.push("/");
    router.refresh();
  }

  return (
    <div className="min-h-screen">
      <header className="sticky top-0 z-40 border-b border-white/10 bg-[#05070a]/90 backdrop-blur-xl">
        <div className="mx-auto flex max-w-[1440px] items-center gap-3 px-3 py-2.5 sm:px-4 sm:py-3 lg:px-8">
          <Link href="/events" className="min-w-0 shrink">
            <span className="font-display text-lg font-bold tracking-wide sm:text-xl">
              PROWEM <span className="text-prowem-coral">Event Care</span>
            </span>
          </Link>
          <div className="ml-auto flex shrink-0 items-center gap-1.5 sm:gap-2">
            <Link href="/notifications" className="btn-ghost-glass px-2.5 py-2" aria-label="Inbox">
              <Bell className="h-4 w-4" />
            </Link>
            <button
              type="button"
              className="btn-ghost-glass shrink-0 px-2.5 py-2"
              onClick={() => setMenuOpen(true)}
              aria-label="Open menu"
            >
              <Menu className="h-5 w-5" />
            </button>
          </div>
        </div>
        <div className="border-t border-white/5">
          <div className="mx-auto max-w-[1440px] px-3 py-2 sm:px-4 lg:px-8">
            <nav className="flex items-center gap-1 overflow-x-auto [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {links.map((link) => {
                const active = pathname.startsWith(link.href);
                return (
                  <Link
                    key={link.href}
                    href={link.href}
                    className={cn(
                      "shrink-0 rounded-full px-3 py-1.5 text-[11px] font-semibold uppercase tracking-wide transition sm:text-xs",
                      active
                        ? "bg-white/10 text-white"
                        : "text-prowem-muted hover:bg-white/5 hover:text-white",
                    )}
                  >
                    {link.label}
                  </Link>
                );
              })}
            </nav>
          </div>
        </div>
      </header>

      <main className="mx-auto max-w-[1440px] px-3 py-5 sm:px-4 sm:py-8 lg:px-8">
        {children}
      </main>

      {menuOpen ? (
        <div className="fixed inset-0 z-50">
          <button
            type="button"
            className="absolute inset-0 bg-black/70 backdrop-blur-sm"
            aria-label="Close menu"
            onClick={() => setMenuOpen(false)}
          />
          <div className="absolute inset-y-0 right-0 flex w-[min(100%,20rem)] flex-col border-l border-white/10 bg-[#080b10] shadow-glass">
            <div className="flex items-center justify-between border-b border-white/10 px-4 py-3">
              <span className="font-display text-lg font-bold">
                PROWEM <span className="text-prowem-coral">Event Care</span>
              </span>
              <button
                type="button"
                className="btn-ghost-glass px-2.5 py-2"
                onClick={() => setMenuOpen(false)}
                aria-label="Close menu"
              >
                <X className="h-5 w-5" />
              </button>
            </div>
            <div className="flex-1 overflow-y-auto px-3 py-4">
              <p className="mb-2 px-2 text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-muted">
                Navigate
              </p>
              <div className="flex flex-col gap-1">
                {links.map((link) => (
                  <Link
                    key={link.href}
                    href={link.href}
                    onClick={() => setMenuOpen(false)}
                    className="rounded-xl px-3 py-3 text-sm font-semibold uppercase tracking-wide text-prowem-muted hover:bg-white/5 hover:text-white"
                  >
                    {link.label}
                  </Link>
                ))}
              </div>
            </div>
            <div className="border-t border-white/10 p-4">
              <div className="mb-3 flex items-center gap-3">
                <span className="flex h-9 w-9 items-center justify-center rounded-full bg-prowem-coral/30 text-xs font-bold">
                  {user.name.slice(0, 2).toUpperCase()}
                </span>
                <div className="min-w-0">
                  <p className="truncate text-sm font-medium text-white">{user.name}</p>
                  <p className="truncate text-xs text-prowem-muted">
                    {roleLabel(user.role)} · {user.email}
                  </p>
                </div>
              </div>
              <button type="button" className="btn-ghost-glass w-full py-2.5 text-sm" onClick={logout}>
                Logout
              </button>
            </div>
          </div>
        </div>
      ) : null}
    </div>
  );
}
