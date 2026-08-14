"use client";

import { useSession } from "@/shared/auth/session-context";
import { cn } from "@/shared/lib/cn";
import { useUserRealtime } from "@/shared/realtime/hooks";
import { Activity, Bell, CheckSquare, ChevronDown, Home, LayoutGrid, Menu, MessageSquare, Radio, ShieldCheck, Users, X, TriangleAlert, Headphones } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import { useState } from "react";

type ShellLink = { href: string; label: string; icon: typeof Home; count?: number };

export function AppShell({ children }: { children: React.ReactNode }) {
  const user = useSession();
  const router = useRouter();
  const pathname = usePathname();
  const [menuOpen, setMenuOpen] = useState(false);
  useUserRealtime(user.id);
  const eventId = pathname.match(/^\/events\/(\d+)/)?.[1];
  const supportUser = user.role === "support_agent" || user.role === "support_lead" || user.role === "admin";
  const mainLinks: ShellLink[] = [
    { href: "/events", label: supportUser ? "Support Queue" : "My Events", icon: supportUser ? Headphones : LayoutGrid },
    { href: "/notifications", label: "Notifications", icon: Bell },
  ];
  const organizerLinks: ShellLink[] = [
    { href: `/events/${eventId}`, label: "Event Home", icon: Home },
    { href: `/events/${eventId}/readiness`, label: "Event Checklists", icon: CheckSquare },
    { href: `/events/${eventId}/live`, label: "Live Control", icon: Radio },
    { href: `/events/${eventId}/teams`, label: "Teams", icon: Users },
    { href: `/events/${eventId}/incidents`, label: "Operations", icon: TriangleAlert },
    { href: `/events/${eventId}/tickets`, label: "PROWEM Support", icon: MessageSquare },
    { href: `/events/${eventId}/activity`, label: "Activity", icon: Activity },
  ];
  const supportLinks: ShellLink[] = [
    { href: `/events/${eventId}`, label: "Event Context", icon: Home },
    { href: `/events/${eventId}/incidents`, label: "Technical Incidents", icon: TriangleAlert },
    { href: `/events/${eventId}/tickets`, label: "Support Tickets", icon: Headphones },
    { href: `/events/${eventId}/activity`, label: "Activity", icon: Activity },
  ];
  const links = eventId ? (supportUser ? supportLinks : organizerLinks) : mainLinks;

  async function logout() { await fetch("/api/auth/logout", { method: "POST" }); router.push("/"); router.refresh(); }

  return (
    <div className="app-frame">
      <aside className="app-sidebar">
        <Brand />
        <nav>{links.map(({ href, label, icon: Icon, count }, index) => { const active = eventId ? pathname === href || (index > 0 && pathname.startsWith(href)) : index === 0 && pathname === "/events"; return <Link key={`${label}-${index}`} href={href} className={cn(active && "is-active")}><Icon /><span>{label}</span>{count ? <b>{count}</b> : null}</Link>; })}</nav>
        <div className="sidebar-status"><p><ShieldCheck /> Secure access</p><p><i /> Role-protected workspace</p></div>
      </aside>

      <header className="app-mobile-header"><Brand /><div><Link href="/notifications" aria-label="Notifications"><Bell /></Link><button type="button" onClick={() => setMenuOpen(true)} aria-label="Open menu"><Menu /></button></div></header>
      <header className="app-topbar"><Link href="/notifications" aria-label="Notifications" className="topbar-bell"><Bell /></Link><button type="button" onClick={() => setMenuOpen(true)}><span>{user.name.slice(0, 2).toUpperCase()}</span>{user.name}<ChevronDown /></button></header>
      <main className="app-content">{children}</main>

      {menuOpen ? <div className="app-drawer"><button type="button" className="app-drawer__shade" onClick={() => setMenuOpen(false)} aria-label="Close menu" /><section><button type="button" className="drawer-close" onClick={() => setMenuOpen(false)}><X /></button><Brand /><div className="drawer-user"><span>{user.name.slice(0, 2).toUpperCase()}</span><div><b>{user.name}</b><small>{user.email}</small></div></div><nav>{links.slice(0, 5).map(({ href, label, icon: Icon }) => <Link key={label} href={href} onClick={() => setMenuOpen(false)}><Icon />{label}</Link>)}</nav><button type="button" className="drawer-logout" onClick={logout}>Logout</button></section></div> : null}
    </div>
  );
}

function Brand() { return <Link href="/events" className="app-brand"><span className="prowem-mark prowem-mark--tiny"><i /></span><span><b>PROWEM</b><small>Event Care</small></span></Link>; }
