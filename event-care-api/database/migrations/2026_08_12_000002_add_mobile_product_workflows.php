<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('teams', function (Blueprint $table): void {
            $table->string('manager_name')->nullable();
            $table->string('manager_phone', 40)->nullable();
        });
        Schema::table('support_tickets', function (Blueprint $table): void {
            $table->string('reference')->nullable()->unique();
            $table->string('category')->nullable();
            $table->string('affected_service')->nullable();
            $table->foreignId('fixture_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('venue_id')->nullable()->constrained()->nullOnDelete();
            $table->string('idempotency_key')->nullable();
            $table->unique(['event_id', 'idempotency_key']);
        });
        Schema::create('team_operation_states', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('team_id')->constrained()->cascadeOnDelete();
            $table->string('operation');
            $table->foreignId('completed_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestampTz('completed_at');
            $table->timestampsTz();
            $table->unique(['event_id', 'team_id', 'operation']);
        });
        Schema::create('readiness_snapshots', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->string('reason');
            $table->string('status');
            $table->unsignedSmallInteger('score');
            $table->unsignedInteger('critical_blockers_count')->default(0);
            $table->timestampTz('captured_at');
            $table->timestampsTz();
            $table->index(['event_id', 'captured_at']);
        });
        Schema::create('ticket_messages', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('ticket_id')->constrained('support_tickets')->cascadeOnDelete();
            $table->foreignId('author_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('visibility')->default('customer');
            $table->text('body');
            $table->string('idempotency_key')->nullable();
            $table->timestampsTz();
            $table->unique(['ticket_id', 'idempotency_key']);
        });
        Schema::create('notifications', function (Blueprint $table): void {
            $table->uuid('id')->primary();
            $table->string('type');
            $table->morphs('notifiable');
            $table->text('data');
            $table->timestampTz('read_at')->nullable();
            $table->timestampsTz();
            $table->index(['notifiable_type', 'notifiable_id', 'read_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('notifications');
        Schema::dropIfExists('ticket_messages');
        Schema::dropIfExists('readiness_snapshots');
        Schema::dropIfExists('team_operation_states');
        Schema::table('support_tickets', fn (Blueprint $table) => $table->dropColumn(['reference', 'category', 'affected_service', 'fixture_id', 'venue_id', 'idempotency_key']));
        Schema::table('teams', fn (Blueprint $table) => $table->dropColumn(['manager_name', 'manager_phone']));
    }
};
