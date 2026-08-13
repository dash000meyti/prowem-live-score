import { requireSessionUser } from "@/shared/api/server";
import { Providers } from "@/shared/providers";
import { AppShell } from "@/features/auth/app-shell";

export default async function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const user = await requireSessionUser();

  return (
    <Providers user={user}>
      <AppShell>{children}</AppShell>
    </Providers>
  );
}
