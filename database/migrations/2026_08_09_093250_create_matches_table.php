<?php

use App\Enums\GameStatus;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('matches', function (Blueprint $table) {
            $table->id();

            $table->foreignId('home_team_id')
                ->constrained('teams')
                ->restrictOnDelete();

            $table->foreignId('away_team_id')
                ->constrained('teams')
                ->restrictOnDelete();

            $table->unsignedSmallInteger('round_number');

            $table->unsignedSmallInteger('home_score')->nullable();
            $table->unsignedSmallInteger('away_score')->nullable();

            $table->string('status')
                ->default(GameStatus::Scheduled->value);

            $table->timestamp('kickoff_at')->nullable();

            $table->timestamps();

            $table->unique([
                'home_team_id',
                'away_team_id',
            ]);

        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('matches');
    }
};
