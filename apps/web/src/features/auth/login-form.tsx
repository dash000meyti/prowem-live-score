"use client";

import { ApiError } from "@/shared/api/client";
import { ErrorBanner } from "@/shared/ui/error-banner";
import { ArrowRight, Eye, EyeOff, LockKeyhole, Mail, ShieldCheck } from "lucide-react";
import { useRouter } from "next/navigation";
import { useState } from "react";

export function LoginForm() {
  const router = useRouter();
  const [error, setError] = useState<unknown>(null);
  const [pending, setPending] = useState(false);
  const [showPassword, setShowPassword] = useState(false);
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  async function submit(nextEmail = email, nextPassword = password) {
    setPending(true);
    setError(null);
    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: { "Content-Type": "application/json", Accept: "application/json" },
        body: JSON.stringify({ email: nextEmail, password: nextPassword }),
      });
      const json = await response.json();
      if (!response.ok || json.success !== true) {
        setError(new ApiError(json.message ?? "Unable to sign in.", json.error?.code ?? "INVALID_CREDENTIALS", response.status, json.error?.details));
        return;
      }
      router.push("/events");
      router.refresh();
    } catch {
      setError(new ApiError("Unable to reach the sign-in service. Please try again.", "AUTH_SERVICE_UNAVAILABLE", 503));
    } finally {
      setPending(false);
    }
  }

  function useDemoAccount() {
    setEmail("organizer@prowem.test");
    setPassword("password");
  }

  return (
    <section className="login-card">
      <div className="login-card__brand">
        <span className="prowem-mark prowem-mark--small" aria-hidden="true"><i /></span>
        <h2>PROWEM</h2>
        <p>Event Care</p>
      </div>

      <div className="login-divider" aria-hidden="true"><span>⚽</span></div>

      <form action="/api/auth/login" method="post" onSubmit={(event) => { event.preventDefault(); void submit(); }}>
        <ErrorBanner error={error} />

        <label className="login-field">
          <span>Email</span>
          <span className="login-input-wrap">
            <Mail aria-hidden="true" />
            <input name="email" type="email" autoComplete="email" required placeholder="Enter your email" value={email} onChange={(event) => setEmail(event.target.value)} />
          </span>
        </label>

        <label className="login-field">
          <span>Password</span>
          <span className="login-input-wrap">
            <LockKeyhole aria-hidden="true" />
            <input name="password" type={showPassword ? "text" : "password"} autoComplete="current-password" required placeholder="Enter your password" value={password} onChange={(event) => setPassword(event.target.value)} />
            <button type="button" className="password-toggle" onClick={() => setShowPassword((value) => !value)} aria-label={showPassword ? "Hide password" : "Show password"}>
              {showPassword ? <EyeOff /> : <Eye />}
            </button>
          </span>
        </label>

        <button type="button" className="demo-login-link" onClick={useDemoAccount}>
          Use organizer demo account
        </button>

        <button type="submit" className="login-submit" disabled={pending}>
          <span>{pending ? "Signing in…" : "Sign In"}</span>
          <ArrowRight aria-hidden="true" />
        </button>
      </form>

      <div className="secure-access" aria-label="Secure access">
        <i /><span><ShieldCheck aria-hidden="true" /> Secure access</span><i />
      </div>
    </section>
  );
}
