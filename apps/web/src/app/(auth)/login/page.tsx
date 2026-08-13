import { getSessionUser } from "@/shared/api/server";
import { LoginForm } from "@/features/auth/login-form";
import { redirect } from "next/navigation";

export default async function LoginPage() {
  const user = await getSessionUser();
  if (user) redirect("/events");

  return (
    <main className="login-screen">
      <div className="login-screen__shade" />
      <div className="login-shell">
        <section className="login-brand" aria-label="PROWEM Event Care">
          <span className="prowem-mark" aria-hidden="true">
            <i />
          </span>
          <div>
            <h1>PROWEM</h1>
            <p>Event Care</p>
          </div>
        </section>
        <LoginForm />
      </div>
    </main>
  );
}
