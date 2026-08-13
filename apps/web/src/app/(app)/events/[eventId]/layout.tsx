import { EventNav } from "@/features/events/event-nav";

export default async function EventLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ eventId: string }>;
}) {
  const { eventId } = await params;

  return (
    <>
      <EventNav eventId={eventId} />
      {children}
    </>
  );
}
