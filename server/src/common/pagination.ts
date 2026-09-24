export interface PaginationParams {
  page: number;
  limit: number;
  skip: number;
  cursor?: string;
}

export interface PaginationMeta {
  total: number;
  page: number;
  limit: number;
  totalPages: number;
  hasMore: boolean;
  nextCursor: string | null;
}

export interface PaginatedResult<T> {
  data: T[];
  pagination: PaginationMeta;
}

/**
 * Parses query parameters into sanitized pagination parameters.
 * Enforces a maximum limit of 100 items per page to prevent memory exhaustion.
 */
export const parsePagination = (query: Record<string, any>): PaginationParams => {
  const pageRaw = parseInt(query.page as string, 10);
  const limitRaw = parseInt(query.limit as string, 10);
  const cursor = typeof query.cursor === 'string' && query.cursor.trim().length > 0
    ? query.cursor.trim()
    : undefined;

  const page = !isNaN(pageRaw) && pageRaw > 0 ? pageRaw : 1;
  const limit = !isNaN(limitRaw) && limitRaw > 0 ? Math.min(limitRaw, 100) : 20;
  const skip = (page - 1) * limit;

  return { page, limit, skip, cursor };
};

/**
 * Builds a standardized paginated response envelope.
 */
export const buildPaginatedResult = <T extends { id?: string }>(
  items: T[],
  total: number,
  params: { page: number; limit: number }
): PaginatedResult<T> => {
  const { page, limit } = params;
  const totalPages = Math.ceil(total / limit) || 1;
  const hasMore = page < totalPages;

  let nextCursor: string | null = null;
  if (hasMore && items.length > 0 && items[items.length - 1].id) {
    nextCursor = items[items.length - 1].id!;
  }

  return {
    data: items,
    pagination: {
      total,
      page,
      limit,
      totalPages,
      hasMore,
      nextCursor,
    },
  };
};

export default {
  parsePagination,
  buildPaginatedResult,
};
