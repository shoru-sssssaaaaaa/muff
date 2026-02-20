export interface SourceResponse {
  source_id: string;
  name: string;
  rss_url: string;
  site_url: string;
  status: string;
  consecutive_failures: number;
  last_fetch_at: string | null;
  last_success_at: string | null;
}

export interface ArticleResponse {
  article_id: string;
  source_id: string;
  source_name: string;
  title: string;
  url: string;
  published_at: string;
  thumbnail_url: string | null;
  category: string;
  view_count: number | null;
}

export interface FeedResponse {
  items: ArticleResponse[];
  next_cursor: string | null;
}

export interface CreateSourceRequest {
  name: string;
  rss_url: string;
  site_url: string;
}

export interface UpdateSourceRequest {
  name: string;
  rss_url: string;
  site_url: string;
  status: string;
}

export interface ErrorResponse {
  error: string;
  message: string;
}

export interface CategoryRuleResponse {
  category_rule_id: string;
  name: string;
  keywords: string[];
  is_default: boolean;
  sort_order: number;
  article_count: number;
}

export interface CreateCategoryRuleRequest {
  name: string;
  keywords: string[];
  is_default: boolean;
  sort_order: number;
}

export interface UpdateCategoryRuleRequest {
  name: string;
  keywords: string[];
  is_default: boolean;
  sort_order: number;
}
