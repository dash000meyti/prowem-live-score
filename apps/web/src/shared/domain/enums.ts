import type { EventStatus } from "@/shared/api/types";

export const EVENT_STATUSES = [
  "preparing",
  "ready",
  "live",
  "completed",
  "cancelled",
] as const satisfies EventStatus[];

export const EVENT_TRANSITIONS: Record<EventStatus, EventStatus[]> = {
  preparing: ["ready", "cancelled"],
  ready: ["preparing", "live", "cancelled"],
  live: ["completed", "cancelled"],
  completed: [],
  cancelled: [],
};

export const READINESS_STATUSES = ["ready", "warning", "blocked"] as const;

export const INCIDENT_TYPES = ["operational", "technical"] as const;

export const OPERATIONAL_CATEGORIES = [
  "team_absent",
  "team_late",
  "referee_absent",
  "match_delay",
  "venue_issue",
  "player_eligibility",
  "staff_issue",
  "other",
] as const;

export const TECHNICAL_CATEGORIES = [
  "live_score",
  "streaming",
  "graphics",
  "platform",
  "other",
] as const;

export const ALL_INCIDENT_CATEGORIES = [
  ...OPERATIONAL_CATEGORIES.filter((value) => value !== "other"),
  ...TECHNICAL_CATEGORIES,
] as const;

export const INCIDENT_SEVERITIES = ["low", "medium", "high", "critical"] as const;

export const INCIDENT_STATUSES = [
  "open",
  "acknowledged",
  "in_progress",
  "resolved",
] as const;

export const INCIDENT_TRANSITIONS: Record<string, typeof INCIDENT_STATUSES[number][]> = {
  open: ["acknowledged", "in_progress", "resolved"],
  acknowledged: ["in_progress", "resolved"],
  in_progress: ["resolved"],
  resolved: [],
};

export const TICKET_CATEGORIES = [
  "live_score",
  "streaming",
  "graphics",
  "platform",
  "team_absent",
  "team_late",
  "referee_absent",
  "match_delay",
  "venue_issue",
  "player_eligibility",
  "staff_issue",
  "other",
] as const;

export const TICKET_URGENCIES = ["critical", "high", "normal", "low"] as const;

export const AFFECTED_SERVICES = [
  "live_score",
  "streaming",
  "graphics",
  "platform",
  "other",
] as const;

export const TICKET_PRIORITIES = ["p1", "p2", "p3", "p4"] as const;

export const TICKET_STATUSES = [
  "open",
  "in_progress",
  "waiting",
  "resolved",
  "reopened",
] as const;

export const TICKET_TRANSITIONS: Record<string, typeof TICKET_STATUSES[number][]> = {
  open: ["in_progress", "waiting", "resolved"],
  in_progress: ["waiting", "resolved"],
  waiting: ["in_progress", "resolved"],
  resolved: ["reopened"],
  reopened: ["in_progress", "resolved"],
};

export const ACTIVITY_TYPES = [
  "incident_created",
  "incident_acknowledged",
  "incident_in_progress",
  "incident_resolved",
  "support_ticket_created",
  "ticket_in_progress",
  "ticket_waiting",
  "ticket_resolved",
  "ticket_reopened",
  "ticket_priority_changed",
  "ticket_message_created",
  "team_operation_completed",
  "team_readiness_changed",
  "readiness_check_overridden",
  "event_status_changed",
  "readiness_check_changed",
  "operational_update",
] as const;

export const PAGE_SIZE = 20;

export function humanize(value: string) {
  return value.replaceAll("_", " ");
}

export function eventStatusLabel(status: EventStatus) {
  return status === "live" ? "Start event" : humanize(status);
}
