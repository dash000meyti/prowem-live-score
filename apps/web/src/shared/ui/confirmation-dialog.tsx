"use client";

import { Button } from "@/shared/ui/button";

export function ConfirmationDialog({
  open,
  title,
  description,
  confirmLabel,
  pending = false,
  destructive = false,
  onCancel,
  onConfirm,
}: {
  open: boolean;
  title: string;
  description: string;
  confirmLabel: string;
  pending?: boolean;
  destructive?: boolean;
  onCancel: () => void;
  onConfirm: () => void;
}) {
  if (!open) return null;

  return (
    <div className="fixed inset-0 z-50 grid place-items-end bg-black/70 p-0 backdrop-blur-sm sm:place-items-center sm:p-6" role="presentation" onMouseDown={(event) => { if (event.target === event.currentTarget && !pending) onCancel(); }}>
      <section role="dialog" aria-modal="true" aria-labelledby="confirmation-title" className="w-full rounded-t-3xl border border-white/15 bg-[#0d1117] p-5 shadow-2xl sm:max-w-md sm:rounded-3xl sm:p-6">
        <div className="mx-auto mb-4 h-1 w-12 rounded-full bg-white/20 sm:hidden" />
        <h2 id="confirmation-title" className="text-xl font-extrabold">{title}</h2>
        <p className="mt-2 text-sm leading-6 text-prowem-muted">{description}</p>
        <div className="mt-6 grid gap-2 sm:grid-cols-2">
          <Button type="button" variant="secondary" disabled={pending} onClick={onCancel}>Cancel</Button>
          <Button type="button" variant={destructive ? "danger" : "primary"} disabled={pending} onClick={onConfirm}>{pending ? "Saving…" : confirmLabel}</Button>
        </div>
      </section>
    </div>
  );
}
