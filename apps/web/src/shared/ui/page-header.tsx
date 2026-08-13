import type { ReactNode } from "react";

export function PageHeader({
  eyebrow,
  title,
  description,
  actions,
}: {
  eyebrow?: string;
  title: string;
  description?: string;
  actions?: ReactNode;
}) {
  return (
    <div className="mb-6 flex flex-col gap-4 sm:mb-8 md:flex-row md:items-end md:justify-between">
      <div className="min-w-0 space-y-2">
        {eyebrow ? (
          <p className="text-[10px] font-bold uppercase tracking-[0.2em] text-prowem-coral sm:text-xs">
            {eyebrow}
          </p>
        ) : null}
        <h1 className="font-display text-[1.75rem] font-bold uppercase leading-tight tracking-wide text-white sm:text-3xl md:text-4xl">
          {title}
        </h1>
        {description ? (
          <p className="max-w-2xl text-sm leading-relaxed text-prowem-muted md:text-base">
            {description}
          </p>
        ) : null}
      </div>
      {actions ? (
        <div className="flex w-full flex-wrap gap-2 sm:w-auto sm:gap-3">{actions}</div>
      ) : null}
    </div>
  );
}

export function EmptyState({
  title,
  description,
}: {
  title: string;
  description?: string;
}) {
  return (
    <div className="glass-panel flex flex-col items-center justify-center gap-3 px-6 py-16 text-center">
      <h3 className="font-display text-2xl font-bold uppercase tracking-wide text-white">
        {title}
      </h3>
      {description ? (
        <p className="max-w-md text-sm leading-relaxed text-prowem-muted">{description}</p>
      ) : null}
    </div>
  );
}
