<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EventCareReportResource extends JsonResource
{
    /** @return array{event:array{id:int,name:string,status:string},team_count:int,match_count:int,readiness:array{score_before_kickoff:int|null,status_before_kickoff:string|null},incidents:array{total:int,operational:int,technical:int},cancelled_matches:int,average_delay_minutes:float,support:array{tickets:int,p1:int,sla_compliance_percent:float|null,average_resolution_minutes:float|null},major_blockers:list<array{key:string,message:string|null,error_code:string|null}>,recommendations:list<string>} */
    public function toArray(Request $request): array
    {
        return $this->resource;
    }
}
