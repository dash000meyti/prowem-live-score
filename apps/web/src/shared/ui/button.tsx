"use client";

import { cn } from "@/shared/lib/cn";
import Link from "next/link";
import type { ButtonHTMLAttributes, ReactNode } from "react";

type ButtonVariant = "primary" | "ghost" | "danger" | "secondary" | "subtle";

const variants: Record<ButtonVariant, string> = {
  primary: "btn-primary-glow",
  ghost: "btn-ghost-glass",
  secondary: "btn-ghost-glass",
  danger:
    "inline-flex items-center justify-center gap-2 rounded-full bg-prowem-danger/90 px-5 py-3 font-semibold text-white shadow-[0_0_20px_rgba(255,59,78,0.35)] transition hover:brightness-110",
  subtle:
    "inline-flex items-center justify-center gap-2 rounded-full px-4 py-2 text-sm text-prowem-muted transition hover:bg-white/5 hover:text-white",
};

export function Button({
  variant = "primary",
  className,
  ...props
}: ButtonHTMLAttributes<HTMLButtonElement> & { variant?: ButtonVariant }) {
  return (
    <button
      className={cn(variants[variant], "focus-ring disabled:opacity-50", className)}
      {...props}
    />
  );
}

export function ButtonLink({
  href,
  variant = "primary",
  className,
  children,
}: {
  href: string;
  variant?: ButtonVariant;
  className?: string;
  children: ReactNode;
}) {
  return (
    <Link href={href} className={cn(variants[variant], "focus-ring", className)}>
      {children}
    </Link>
  );
}
