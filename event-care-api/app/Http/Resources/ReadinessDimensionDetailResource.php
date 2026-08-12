<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ReadinessDimensionDetailResource extends JsonResource
{
    /** @return array{dimension:array{key:string,label:string},summary:array{status:string,score:int,ready:int,total:int,actions_required:int},items:list<array{id:int,label:string,status:string,message:string|null,action:string|null,subject:array{type:string,id:int|null},metadata:object|null}>} */
    public function toArray(Request $request): array
    {
        return $this->resource;
    }
}
