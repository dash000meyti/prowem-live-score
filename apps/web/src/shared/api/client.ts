export class ApiError extends Error {
  constructor(
    message: string,
    public readonly code: string,
    public readonly status: number,
    public readonly details: unknown = null,
  ) {
    super(message);
    this.name = "ApiError";
  }
}

export type SuccessEnvelope<T> = {
  success: true;
  message: string | null;
  data: T;
  meta?: { pagination: unknown };
  links?: unknown;
};

export type ErrorEnvelope = {
  success: false;
  message: string;
  error: { code: string; details: unknown };
};

export async function parseApiResponse<T>(response: Response): Promise<T> {
  const json = (await response.json()) as SuccessEnvelope<T> | ErrorEnvelope;

  if (!("success" in json) || json.success !== true) {
    const error = json as ErrorEnvelope;
    throw new ApiError(
      error.message ?? "Request failed.",
      error.error?.code ?? "INTERNAL_ERROR",
      response.status,
      error.error?.details ?? null,
    );
  }

  return json.data;
}

export async function parsePaginated<T>(response: Response) {
  const json = (await response.json()) as
    | (SuccessEnvelope<T[]> & {
        meta: { pagination: import("./types").Pagination };
        links: import("./types").Paginated<T>["links"];
      })
    | ErrorEnvelope;

  if (!("success" in json) || json.success !== true) {
    const error = json as ErrorEnvelope;
    throw new ApiError(
      error.message ?? "Request failed.",
      error.error?.code ?? "INTERNAL_ERROR",
      response.status,
      error.error?.details ?? null,
    );
  }

  return {
    data: json.data,
    meta: json.meta,
    links: json.links,
    message: json.message,
  };
}
