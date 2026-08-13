<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class EventReadinessResource extends JsonResource
{
    /** @return array{status:string,score:int,critical_blockers_count:int,actions_required_count:int,dimensions:list<array{key:string,label:string,status:string,score:int,ready:int,total:int,actions_required:int}>,checks_count:int} */
    public function toArray(Request $request): array
    {
        return $this->resource;
    }
}
