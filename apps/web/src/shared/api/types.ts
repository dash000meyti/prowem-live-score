export type UserRole =
  | "organizer"
  | "support_agent"
  | "support_lead"
  | "admin";

export type EventStatus =
  | "preparing"
  | "ready"
  | "live"
  | "completed"
  | "cancelled";

export type ReadinessStatus = "ready" | "warning" | "blocked";

export type ReadinessDimension =
  | "teams"
  | "players"
  | "fixtures"
  | "referees"
  | "venues"
  | "staff"
  | "live_score"
  | "streaming"
  | "graphics";

export type TeamOperation =
  | "verify_payment"
  | "check_in"
  | "approve_roster"
  | "confirm_eligibility"
  | "approve_documents";

export type IncidentType = "operational" | "technical";
export type IncidentSeverity = "low" | "medium" | "high" | "critical";
export type IncidentStatus =
  | "open"
  | "acknowledged"
  | "in_progress"
  | "resolved";

export type TicketPriority = "p1" | "p2" | "p3" | "p4";
export type TicketStatus =
  | "open"
  | "in_progress"
  | "waiting"
  | "resolved"
  | "reopened";
export type SlaStatus = "on_track" | "approaching" | "breached" | "met";

export type SessionUser = {
  id: number;
  name: string;
  email: string;
  role: UserRole;
  customer: { id: number; name: string } | null;
};

export type ReadinessSummary = {
  status: ReadinessStatus;
  score: number;
  critical_blockers_count: number;
  actions_required_count: number;
  dimensions?: ReadinessDimensionSummary[];
  checks_count?: number;
};

export type ReadinessDimensionSummary = {
  key: string;
  label: string;
  status: ReadinessStatus;
  score: number;
  ready: number;
  total: number;
  actions_required: number;
};

export type EventCard = {
  id: number;
  external_reference: string | null;
  name: string;
  status: EventStatus;
  starts_at: string;
  ends_at: string;
  venue: { id: number; name: string } | null;
  teams_count: number;
  fields_count: number;
  readiness: ReadinessSummary;
  open_incidents_count: number;
  critical_incidents_count: number;
  open_tickets_count: number;
};

export type EventSummary = {
  all: number;
  needs_attention: number;
  preparing: number;
  ready: number;
  live: number;
  completed: number;
  cancelled: number;
};

export type EventDetail = {
  id: number;
  external_reference: string | null;
  name: string;
  status: EventStatus;
  starts_at: string;
  ends_at: string;
  completed_at: string | null;
  venue?: { id: number; name: string } | null;
  team_count?: number;
  field_count?: number;
};

export type ReadinessCheck = {
  id: number;
  subject_type: string;
  subject_id: number | null;
  dimension: string;
  check_type: string;
  status: ReadinessStatus;
  is_critical: boolean;
  message: string | null;
  error_code: string | null;
  metadata: Record<string, unknown> | null;
  last_checked_at: string | null;
  resolved_at: string | null;
};

export type Incident = {
  id: number;
  event_id: number;
  fixture_id: number | null;
  venue_id: number | null;
  type: IncidentType;
  category: string;
  severity: IncidentSeverity;
  status: IncidentStatus;
  title: string;
  description: string;
  started_at: string;
  acknowledged_at: string | null;
  resolved_at: string | null;
  resolution: string | null;
  metadata: Record<string, unknown> | null;
  ticket: Ticket | null | Record<string, never>;
};

export type Ticket = {
  id: number;
  reference: string;
  event: { id: number; name: string | null };
  incident: { id: number; category: string; title: string } | null;
  affected_service: string | null;
  location: string | null;
  priority: TicketPriority;
  status: TicketStatus;
  subject: string;
  description: string;
  assignee: { id: number; name: string } | null;
  created_at: string | null;
  updated_at: string | null;
  first_response_at: string | null;
  sla_due_at: string;
  sla_status: SlaStatus;
  sla_remaining_seconds: number;
  resolved_at: string | null;
  resolution: string | null;
  resolution_code: string | null;
};

export type SupportHome = {
  event: { id: number; name: string; status: EventStatus };
  critical: Ticket | null;
  open: Ticket[];
  resolved: Ticket[];
  counts: { open: number; resolved: number };
};

export type TicketMessage = {
  id: number;
  ticket_id: number;
  author: { id: number; name: string; role: UserRole } | null;
  visibility: "customer" | "internal";
  body: string;
  created_at: string | null;
};

export type Activity = {
  id: number;
  type: string;
  title: string;
  description: string;
  entity: { type: string | null; id: number | null };
  actor: { id: number; name: string } | null;
  context: Record<string, unknown> | null;
  occurred_at: string;
};

export type NotificationItem = {
  id: string;
  type: string;
  title: string | null;
  body: string | null;
  event_id: number | null;
  read_at: string | null;
  created_at: string | null;
};

export type TeamPassport = {
  team: { id: number; name: string };
  manager: { name: string | null; phone: string | null };
  first_match: { id: number; kickoff_at: string; field: string | null } | null;
  status: ReadinessStatus;
  score: number;
  blockers_count: number;
  actions_required_count: number;
  checks: {
    id: number;
    key: string;
    label: string;
    status: ReadinessStatus;
    message: string | null;
    action: TeamOperation | null;
  }[];
};

export type CareOverview = {
  event: EventDetail;
  readiness: ReadinessSummary;
  readiness_dimensions: ReadinessDimensionSummary[];
  needs_attention: ReadinessCheck[];
  open_critical_incidents: Incident[];
  open_tickets: Ticket[];
  next_matches: {
    id: number;
    number: number;
    kickoff_at: string;
    status: string;
    field: string | null;
    home_team: LookupTeam | null;
    away_team: LookupTeam | null;
  }[];
  recent_activity: Activity[];
};

export type DimensionDetail = {
  dimension: { key: string; label: string };
  summary: {
    status: ReadinessStatus;
    score: number;
    ready: number;
    total: number;
    actions_required: number;
  };
  items: {
    id: number;
    label: string;
    status: ReadinessStatus;
    message: string | null;
    action: string | null;
    subject: { type: string; id: number | null };
    metadata: Record<string, unknown> | null;
  }[];
};

export type Fixture = {
  id: number;
  event_id: number;
  venue_id: number | null;
  referee_id: number | null;
  home_team_id: number;
  away_team_id: number;
  number: number;
  kickoff_at: string;
  status: string;
  delay_minutes: number;
};

export type LiveControl = {
  event: { id: number; status: EventStatus };
  progress: { completed: number; total: number };
  live_matches: Fixture[];
  next_matches: Fixture[];
  delayed_matches: Fixture[];
  operational_incidents: Incident[];
  system_status: ReadinessSummary;
};

export type CareReport = {
  event: { id: number; name: string; status: EventStatus };
  team_count: number;
  match_count: number;
  readiness: {
    score_before_kickoff: number | null;
    status_before_kickoff: string | null;
  };
  incidents: { total: number; operational: number; technical: number };
  cancelled_matches: number;
  average_delay_minutes: number;
  support: {
    tickets: number;
    p1: number;
    sla_compliance_percent: number | null;
    average_resolution_minutes: number | null;
  };
  major_blockers: {
    key: string;
    message: string | null;
    error_code: string | null;
  }[];
  recommendations: string[];
};

export type Pagination = {
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
  from: number | null;
  to: number | null;
};

export type Paginated<T> = {
  data: T[];
  meta: { pagination: Pagination };
  links: {
    first: string;
    last: string;
    prev: string | null;
    next: string | null;
  };
};

export type LookupTeam = { id: number; name: string };

export type LookupFixture = {
  id: number;
  number: number;
  kickoff_at: string;
  status: string;
  venue_id: number | null;
  home_team: LookupTeam | null;
  away_team: LookupTeam | null;
};

export type LookupStaff = { id: number; name: string; role: UserRole };

export type EventLookups = {
  venues: { id: number; name: string }[];
  fixtures: LookupFixture[];
  staff: LookupStaff[];
};
