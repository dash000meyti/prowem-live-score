import type { Metadata, Viewport } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "PROWEM Event Care",
  description:
    "Operational readiness, incidents and match-day support for PROWEM events.",
};

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  viewportFit: "cover",
  themeColor: "#05070a",
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" data-scroll-behavior="smooth">
      <body
        className="bg-prowem-bg text-white antialiased"
      >
        <div className="bg-aurora min-h-screen">{children}</div>
      </body>
    </html>
  );
}
