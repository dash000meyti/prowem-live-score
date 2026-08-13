import { getSessionUser } from "@/shared/api/server";
import { redirect } from "next/navigation";
import { LoginForm } from "@/features/auth/login-form";

export default async function LoginPage() {
  const user = await getSessionUser();
  if (user) {
    redirect("/events");
  }

  return (
    <main className="mx-auto flex min-h-screen max-w-5xl flex-col justify-center gap-8 px-4 py-12 sm:px-6 sm:py-16">
      <div className="space-y-3 text-center">
        <p className="text-[10px] font-bold uppercase tracking-[0.25em] text-prowem-coral sm:text-xs">
          Event Care
        </p>
        <h1 className="font-display text-3xl font-bold uppercase tracking-wide sm:text-4xl md:text-5xl">
          Enter the dashboard
        </h1>
        <p className="mx-auto max-w-xl text-sm text-prowem-muted sm:text-base">
          Pick a demo role or sign in with your Event Care credentials.
        </p>
      </div>
      <LoginForm />
    </main>
  );
}
