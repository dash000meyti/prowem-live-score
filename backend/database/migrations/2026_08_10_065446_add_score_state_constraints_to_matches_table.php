<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        DB::statement(<<<'SQL'
            ALTER TABLE matches
                ADD CONSTRAINT matches_status_must_be_valid
                    CHECK (
                        status IN ('scheduled', 'in_play', 'finished')
                    ),
                ADD CONSTRAINT matches_score_state_must_be_consistent
                    CHECK (
                        (
                            status = 'scheduled'
                            AND home_score IS NULL
                            AND away_score IS NULL
                        )
                        OR
                        (
                            status IN ('in_play', 'finished')
                            AND home_score IS NOT NULL
                            AND away_score IS NOT NULL
                        )
                    )
        SQL);
    }

    public function down(): void
    {
        DB::statement(<<<'SQL'
            ALTER TABLE matches
                DROP CHECK matches_score_state_must_be_consistent,
                DROP CHECK matches_status_must_be_valid
        SQL);
    }
};
