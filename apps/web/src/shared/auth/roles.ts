import type { UserRole } from "@/shared/api/types";

export function canManage(role: UserRole) {
  return role === "organizer" || role === "support_lead" || role === "admin";
}

export function canSupport(role: UserRole) {
  return (
    role === "support_agent" || role === "support_lead" || role === "admin"
  );
}

export function roleLabel(role: UserRole) {
  return {
    organizer: "Organizer",
    support_agent: "Support agent",
    support_lead: "Support lead",
    admin: "Admin",
  }[role];
}
