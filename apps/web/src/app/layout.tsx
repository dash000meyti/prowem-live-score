import type { Metadata, Viewport } from "next";
import { Montserrat, Rajdhani } from "next/font/google";
import "./globals.css";

const sans = Montserrat({
  variable: "--font-sans",
  subsets: ["latin"],
  weight: ["400", "500", "600", "700"],
});

const display = Rajdhani({
  variable: "--font-display",
  subsets: ["latin"],
  weight: ["500", "600", "700"],
});

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
    <html lang="en">
      <body
        className={`${sans.variable} ${display.variable} bg-prowem-bg text-white antialiased`}
      >
        <div className="bg-aurora min-h-screen">{children}</div>
      </body>
    </html>
  );
}
