<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

class EventCareChanged implements ShouldBroadcastNow
{
    use Dispatchable,InteractsWithSockets;

    public function __construct(public readonly int $eventId, public readonly string $name, public readonly array $payload) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel("events.{$this->eventId}")];
    }

    public function broadcastAs(): string
    {
        return $this->name;
    }

    public function broadcastWith(): array
    {
        return $this->payload;
    }
}
