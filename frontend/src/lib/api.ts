import type {
  SourceResponse,
  FeedResponse,
  CreateSourceRequest,
  UpdateSourceRequest,
  CategoryRuleResponse,
  CreateCategoryRuleRequest,
  UpdateCategoryRuleRequest,
} from "@/types/api";

const BASE_URL = "/api";

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const res = await fetch(`${BASE_URL}${path}`, {
    ...init,
    headers: {
      "Content-Type": "application/json",
      ...init?.headers,
    },
  });
  if (!res.ok) {
    const body = await res.json().catch(() => null);
    throw new Error(body?.message ?? `Request failed: ${res.status}`);
  }
  return res.json();
}

// Sources
export function getSources() {
  return request<SourceResponse[]>("/admin/sources");
}

export function createSource(data: CreateSourceRequest) {
  return request<SourceResponse>("/admin/sources", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export function updateSource(id: string, data: UpdateSourceRequest) {
  return request<SourceResponse>(`/admin/sources/${id}`, {
    method: "PUT",
    body: JSON.stringify(data),
  });
}

export function deleteSource(id: string) {
  return request<{ status: string }>(`/admin/sources/${id}`, {
    method: "DELETE",
  });
}

// Category Rules
export function getCategoryRules() {
  return request<CategoryRuleResponse[]>("/admin/category-rules");
}

export function createCategoryRule(data: CreateCategoryRuleRequest) {
  return request<CategoryRuleResponse>("/admin/category-rules", {
    method: "POST",
    body: JSON.stringify(data),
  });
}

export function updateCategoryRule(id: string, data: UpdateCategoryRuleRequest) {
  return request<CategoryRuleResponse>(`/admin/category-rules/${id}`, {
    method: "PUT",
    body: JSON.stringify(data),
  });
}

export function deleteCategoryRule(id: string) {
  return request<{ status: string }>(`/admin/category-rules/${id}`, {
    method: "DELETE",
  });
}

export function reclassifyArticles() {
  return request<{ status: string }>("/admin/category-rules/reclassify", {
    method: "POST",
  });
}

// Popular
export function getPopularArticles(limit = 20) {
  return request<FeedResponse>(`/admin/popular?limit=${limit}`);
}

// Articles
export function getArticles(params: {
  source_id?: string;
  category?: string;
  cursor?: string;
  limit?: number;
}) {
  const searchParams = new URLSearchParams();
  if (params.source_id) searchParams.set("source_id", params.source_id);
  if (params.category) searchParams.set("category", params.category);
  if (params.cursor) searchParams.set("cursor", params.cursor);
  if (params.limit) searchParams.set("limit", String(params.limit));
  const qs = searchParams.toString();
  return request<FeedResponse>(`/admin/articles${qs ? `?${qs}` : ""}`);
}
