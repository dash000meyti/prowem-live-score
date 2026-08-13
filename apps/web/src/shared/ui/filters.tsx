"use client";

import type { Pagination } from "@/shared/api/types";
import { Button } from "@/shared/ui/button";
import type { ReactNode, SelectHTMLAttributes } from "react";

export function FilterBar({ children }: { children: ReactNode }) {
  return (
    <div className="glass-panel flex flex-wrap items-end gap-2 p-3">{children}</div>
  );
}

export function FilterSelect({
  label,
  children,
  ...props
}: SelectHTMLAttributes<HTMLSelectElement> & { label: string }) {
  return (
    <label className="grid min-w-36 gap-1 text-[10px] font-bold uppercase tracking-[0.16em] text-prowem-muted">
      {label}
      <select {...props} className="input-glass bg-prowem-bg text-sm font-normal normal-case tracking-normal">
        {children}
      </select>
    </label>
  );
}

export function FilterInput({
  label,
  ...props
}: React.InputHTMLAttributes<HTMLInputElement> & { label: string }) {
  return (
    <label className="grid min-w-36 gap-1 text-[10px] font-bold uppercase tracking-[0.16em] text-prowem-muted">
      {label}
      <input {...props} className="input-glass bg-prowem-bg text-sm font-normal normal-case tracking-normal" />
    </label>
  );
}

export function PaginationControls({
  pagination,
  onPageChange,
}: {
  pagination?: Pagination;
  onPageChange: (page: number) => void;
}) {
  if (!pagination || pagination.last_page <= 1) {
    return null;
  }

  return (
    <div className="flex items-center justify-between gap-3 text-sm text-prowem-muted">
      <span>
        {pagination.from ?? 0}–{pagination.to ?? 0} of {pagination.total}
      </span>
      <div className="flex gap-2">
        <Button
          type="button"
          variant="secondary"
          disabled={pagination.current_page <= 1}
          onClick={() => onPageChange(pagination.current_page - 1)}
        >
          Previous
        </Button>
        <Button
          type="button"
          variant="secondary"
          disabled={pagination.current_page >= pagination.last_page}
          onClick={() => onPageChange(pagination.current_page + 1)}
        >
          Next
        </Button>
      </div>
    </div>
  );
}
