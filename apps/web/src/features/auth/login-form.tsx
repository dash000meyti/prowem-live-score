"use client";

import { useRouter } from "next/navigation";
import { useState } from "react";
import { Button } from "@/shared/ui/button";
import { GlassCard } from "@/shared/ui/card";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { ApiError } from "@/shared/api/client";

const demoRoles = [
  {
    email: "organizer@prowem.test",
    title: "Organizer",
    subtitle: "Customer events, readiness and support requests",
    glow: "orange" as const,
  },
  {
    email: "support@prowem.test",
    title: "Support Agent",
    subtitle: "Technical incidents and ticket administration",
    glow: "cyan" as const,
  },
  {
    email: "lead@prowem.test",
    title: "Support Lead",
    subtitle: "Manage events, SLA and escalation",
    glow: "purple" as const,
  },
  {
    email: "admin@prowem.test",
    title: "Admin",
    subtitle: "Full Event Care access",
    glow: "coral" as const,
  },
];

export function LoginForm() {
  const router = useRouter();
  const [error, setError] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const [email, setEmail] = useState("organizer@prowem.test");
  const [password, setPassword] = useState("password");

  async function submit(nextEmail = email, nextPassword = password) {
    setPending(true);
    setError(null);
    const response = await fetch("/api/auth/login", {
      method: "POST",
      headers: { "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify({ email: nextEmail, password: nextPassword }),
    });
    const json = await response.json();
    setPending(false);
    if (!response.ok || json.success !== true) {
      setError(
        new ApiError(
          json.message ?? "Unable to sign in.",
          json.error?.code ?? "INVALID_CREDENTIALS",
          response.status,
          json.error?.details,
        ),
      );
      return;
    }
    router.push("/events");
    router.refresh();
  }

  return (
    <div className="space-y-6">
      <div className="grid gap-3 sm:grid-cols-2">
        {demoRoles.map((role) => (
          <button
            key={role.email}
            type="button"
            className="text-left"
            onClick={() => {
              setEmail(role.email);
              setPassword("password");
              void submit(role.email, "password");
            }}
          >
            <GlassCard glow={role.glow} className="h-full transition hover:border-white/25">
              <p className="text-xs uppercase tracking-wide text-prowem-muted">{role.email}</p>
              <h2 className="mt-2 font-display text-2xl font-bold uppercase">{role.title}</h2>
              <p className="mt-2 text-sm text-prowem-muted">{role.subtitle}</p>
              <p className="mt-4 text-sm font-semibold text-prowem-coral">Continue →</p>
            </GlassCard>
          </button>
        ))}
      </div>

      <GlassCard strong>
        <form
          className="space-y-4"
          onSubmit={(event) => {
            event.preventDefault();
            void submit();
          }}
        >
          <ErrorBanner error={error} />
          <label className="block text-sm">
            <span className="mb-1 block text-prowem-muted">Email</span>
            <input
              name="email"
              type="email"
              required
              value={email}
              onChange={(event) => setEmail(event.target.value)}
              className="input-glass"
            />
          </label>
          <label className="block text-sm">
            <span className="mb-1 block text-prowem-muted">Password</span>
            <input
              name="password"
              type="password"
              required
              value={password}
              onChange={(event) => setPassword(event.target.value)}
              className="input-glass"
            />
          </label>
          <Button type="submit" disabled={pending} className="w-full">
            {pending ? "Signing in…" : "Sign in"}
          </Button>
        </form>
      </GlassCard>
    </div>
  );
}
