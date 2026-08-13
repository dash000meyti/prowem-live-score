<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('accounts', function (Blueprint $table): void {
            $table->id();
            $table->string('name');
            $table->string('plan')->default('standard');
            $table->timestampsTz();
        });

        Schema::create('users', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('account_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->string('role');
            $table->rememberToken();
            $table->timestampsTz();
        });

        Schema::create('personal_access_tokens', function (Blueprint $table): void {
            $table->id();
            $table->morphs('tokenable');
            $table->text('name');
            $table->string('token', 64)->unique();
            $table->text('abilities')->nullable();
            $table->timestampTz('last_used_at')->nullable();
            $table->timestampTz('expires_at')->nullable()->index();
            $table->timestampsTz();
        });

        Schema::create('events', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('account_id')->constrained()->restrictOnDelete();
            $table->string('external_reference')->nullable()->unique();
            $table->string('name');
            $table->string('status')->default('preparing');
            $table->timestampTz('starts_at');
            $table->timestampTz('ends_at');
            $table->timestampTz('completed_at')->nullable();
            $table->timestampsTz();
            $table->index(['account_id', 'status']);
        });

        Schema::create('event_user', function (Blueprint $table): void {
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role');
            $table->primary(['event_id', 'user_id']);
        });

        Schema::create('teams', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->string('external_reference')->nullable();
            $table->string('name');
            $table->string('readiness_status')->default('ready');
            $table->unsignedSmallInteger('readiness_score')->default(100);
            $table->timestampsTz();
            $table->unique(['event_id', 'external_reference']);
            $table->index(['event_id', 'readiness_status']);
        });

        Schema::create('venues', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->timestampsTz();
        });

        Schema::create('referees', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->timestampsTz();
        });

        Schema::create('fixtures', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('venue_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('referee_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('home_team_id')->constrained('teams')->restrictOnDelete();
            $table->foreignId('away_team_id')->constrained('teams')->restrictOnDelete();
            $table->unsignedSmallInteger('number');
            $table->timestampTz('kickoff_at');
            $table->string('status')->default('scheduled');
            $table->unsignedSmallInteger('delay_minutes')->default(0);
            $table->timestampsTz();
            $table->unique(['event_id', 'number']);
            $table->index(['event_id', 'kickoff_at']);
        });

        Schema::create('readiness_checks', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->string('subject_type');
            $table->unsignedBigInteger('subject_id')->nullable();
            $table->string('dimension');
            $table->string('check_type');
            $table->string('status');
            $table->boolean('is_critical')->default(false);
            $table->text('message')->nullable();
            $table->string('error_code')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestampTz('last_checked_at')->nullable();
            $table->timestampTz('resolved_at')->nullable();
            $table->timestampsTz();
            $table->unique(['event_id', 'subject_type', 'subject_id', 'check_type'], 'readiness_check_unique');
            $table->index(['event_id', 'dimension', 'status']);
        });

        Schema::create('incidents', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('fixture_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('venue_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type');
            $table->string('category');
            $table->string('severity');
            $table->string('status')->default('open');
            $table->string('correlation_key')->nullable();
            $table->string('title');
            $table->text('description');
            $table->timestampTz('started_at');
            $table->timestampTz('acknowledged_at')->nullable();
            $table->timestampTz('resolved_at')->nullable();
            $table->text('resolution')->nullable();
            $table->jsonb('metadata')->nullable();
            $table->timestampsTz();
            $table->index(['event_id', 'status', 'type']);
            $table->index(['event_id', 'category', 'started_at']);
        });
        DB::statement("CREATE UNIQUE INDEX incidents_active_correlation_unique ON incidents (event_id, correlation_key) WHERE correlation_key IS NOT NULL AND status <> 'resolved'");

        Schema::create('support_tickets', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('incident_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('assignee_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('priority');
            $table->string('status')->default('open');
            $table->string('subject');
            $table->text('description');
            $table->timestampTz('first_response_at')->nullable();
            $table->timestampTz('sla_due_at');
            $table->timestampTz('resolved_at')->nullable();
            $table->text('resolution')->nullable();
            $table->string('resolution_code')->nullable();
            $table->text('customer_note')->nullable();
            $table->text('internal_note')->nullable();
            $table->timestampsTz();
            $table->index(['event_id', 'status', 'priority']);
        });

        Schema::create('activities', function (Blueprint $table): void {
            $table->id();
            $table->foreignId('event_id')->constrained()->cascadeOnDelete();
            $table->foreignId('actor_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('type');
            $table->string('subject_type')->nullable();
            $table->unsignedBigInteger('subject_id')->nullable();
            $table->text('description');
            $table->jsonb('context')->nullable();
            $table->timestampTz('occurred_at');
            $table->timestampsTz();
            $table->index(['event_id', 'occurred_at']);
            $table->index(['event_id', 'type']);
        });

        DB::statement("ALTER TABLE events ADD CONSTRAINT events_status_check CHECK (status IN ('preparing','ready','live','completed','cancelled'))");
        DB::statement("ALTER TABLE readiness_checks ADD CONSTRAINT readiness_status_check CHECK (status IN ('ready','warning','blocked'))");
        DB::statement("ALTER TABLE incidents ADD CONSTRAINT incidents_type_check CHECK (type IN ('operational','technical'))");
        DB::statement("ALTER TABLE incidents ADD CONSTRAINT incidents_status_check CHECK (status IN ('open','acknowledged','in_progress','resolved'))");
        DB::statement("ALTER TABLE support_tickets ADD CONSTRAINT tickets_priority_check CHECK (priority IN ('p1','p2','p3','p4'))");
        DB::statement("ALTER TABLE support_tickets ADD CONSTRAINT tickets_status_check CHECK (status IN ('open','in_progress','waiting','resolved','reopened'))");
    }

    public function down(): void
    {
        Schema::dropIfExists('activities');
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('incidents');
        Schema::dropIfExists('readiness_checks');
        Schema::dropIfExists('fixtures');
        Schema::dropIfExists('referees');
        Schema::dropIfExists('venues');
        Schema::dropIfExists('teams');
        Schema::dropIfExists('event_user');
        Schema::dropIfExists('events');
        Schema::dropIfExists('personal_access_tokens');
        Schema::dropIfExists('users');
        Schema::dropIfExists('accounts');
    }
};
