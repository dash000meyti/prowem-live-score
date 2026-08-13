<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement("ALTER TABLE readiness_checks ADD CONSTRAINT readiness_dimension_check CHECK (dimension IN ('teams','players','fixtures','referees','venues','staff','live_score','streaming','graphics'))");
        DB::statement("ALTER TABLE team_operation_states ADD CONSTRAINT team_operation_check CHECK (operation IN ('verify_payment','check_in','approve_roster','confirm_eligibility','approve_documents'))");
        DB::statement("ALTER TABLE ticket_messages ADD CONSTRAINT ticket_message_visibility_check CHECK (visibility IN ('customer','internal'))");
    }

    public function down(): void
    {
        DB::statement('ALTER TABLE ticket_messages DROP CONSTRAINT IF EXISTS ticket_message_visibility_check');
        DB::statement('ALTER TABLE team_operation_states DROP CONSTRAINT IF EXISTS team_operation_check');
        DB::statement('ALTER TABLE readiness_checks DROP CONSTRAINT IF EXISTS readiness_dimension_check');
    }
};
