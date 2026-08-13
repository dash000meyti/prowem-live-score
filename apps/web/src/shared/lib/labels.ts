import type { LookupFixture } from "@/shared/api/types";

export function fixtureLabel(fixture: LookupFixture) {
  const matchup =
    fixture.home_team && fixture.away_team
      ? `${fixture.home_team.name} vs ${fixture.away_team.name}`
      : "";
  return `#${fixture.number}${matchup ? ` · ${matchup}` : ""}`;
}

export function formatWhen(value: string | null | undefined) {
  if (!value) {
    return "—";
  }
  return new Date(value).toLocaleString();
}
