import Link from "next/link";
import { getSessionUser } from "@/shared/api/server";
import { ButtonLink } from "@/shared/ui/button";
import { ControlStackSection } from "@/features/marketing/control-stack";
import { HowItWorksCta } from "@/features/marketing/how-it-works-cta";
import { LandingHero } from "@/features/marketing/hero";
import { OutcomesSection } from "@/features/marketing/outcomes-section";
import { VisibilitySection } from "@/features/marketing/visibility-section";

export default async function LandingPage() {
  let user = null;
  try {
    user = await getSessionUser();
  } catch {
    user = null;
  }
  const enterHref = user ? "/events" : "/login";

  return (
    <div className="relative overflow-hidden">
      <header className="sticky top-0 z-50 border-b border-white/10 bg-black/70 backdrop-blur-xl supports-backdrop-filter:bg-black/55">
        <div className="mx-auto flex max-w-7xl items-center justify-between gap-3 px-4 py-3 sm:px-6 sm:py-4 lg:px-10">
          <Link href="/" className="font-display text-lg font-bold tracking-wide sm:text-xl">
            PROWEM <span className="text-prowem-coral">Event Care</span>
          </Link>
          <div className="flex items-center gap-2 sm:gap-3">
            <Link
              href="/how-it-works"
              className="hidden text-sm text-prowem-muted hover:text-white sm:inline"
            >
              How it works
            </Link>
            <ButtonLink href={enterHref} className="px-4 py-2 text-xs sm:px-5 sm:text-sm">
              {user ? "Open dashboard" : "Enter Event Care"}
            </ButtonLink>
          </div>
        </div>
      </header>

      <LandingHero enterHref={enterHref} signedIn={Boolean(user)} />
      <VisibilitySection />
      <ControlStackSection enterHref={enterHref} signedIn={Boolean(user)} />
      <OutcomesSection />
      <HowItWorksCta />

      <footer className="border-t border-white/10 px-4 py-8 text-center sm:px-6">
        <p>
          <Link
            href={enterHref}
            className="text-sm font-semibold text-white/80 transition hover:text-white"
          >
            Contact & Consultation
          </Link>
        </p>
        <p className="mt-2 text-xs text-prowem-muted">Powered by PROWEM</p>
      </footer>
    </div>
  );
}
