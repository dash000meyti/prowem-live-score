import type { Metadata } from "next";
import { getSessionUser } from "@/shared/api/server";
import { HowItWorksView } from "@/features/marketing/how-it-works";

export const metadata: Metadata = {
  title: "How It Works · PROWEM Event Care",
  description:
    "How PROWEM Event Care runs an event: My Events, readiness checklists, live control, incidents, support tickets, and the post-event report.",
};

export default async function HowItWorksPage() {
  let user = null;
  try {
    user = await getSessionUser();
  } catch {
    user = null;
  }

  return (
    <HowItWorksView enterHref={user ? "/events" : "/login"} signedIn={Boolean(user)} />
  );
}
