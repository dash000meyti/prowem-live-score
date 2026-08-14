import { ApiError } from "@/shared/api/client";

export function ErrorBanner({ error }: { error: unknown }) {
  if (!error) {
    return null;
  }

  const message =
    error instanceof ApiError
      ? friendlyMessage(error)
      : error instanceof Error
        ? error.message
        : "Something went wrong.";

  const details =
    error instanceof ApiError && Array.isArray(error.details)
      ? error.details
      : error instanceof ApiError &&
          error.details &&
          typeof error.details === "object"
        ? Object.entries(error.details as Record<string, unknown>).flatMap(
            ([key, value]) =>
              Array.isArray(value)
                ? value.map((item) => `${key}: ${String(item)}`)
                : [`${key}: ${String(value)}`],
          )
        : [];

  return (
    <div className="rounded-2xl border border-prowem-danger/30 bg-prowem-danger/10 px-4 py-3 text-sm text-white">
      <p>{message}</p>
      {details.length > 0 ? (
        <ul className="mt-1 list-disc pl-5 text-prowem-muted">
          {details.map((item) => (
            <li key={item}>{item}</li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}

function friendlyMessage(error: ApiError) {
  if (error.code === "EVENT_NOT_READY") return "Event cannot start yet. Critical readiness blockers still require attention.";
  if (error.code === "INCIDENT_ALREADY_OPEN") return "This issue is already being handled. Open the existing incident to continue.";
  if (error.code === "FORBIDDEN") return "You do not have permission to perform this action.";
  if (error.code === "UNAUTHENTICATED") return "Your session has expired. Please sign in again.";
  if (error.status >= 500) return "Event Care is temporarily unavailable. Your current data is still shown; please try again.";
  return error.message || "Something went wrong. Please try again.";
}
