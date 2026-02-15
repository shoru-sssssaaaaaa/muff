export interface SourceResponse {
  source_id: string;
  name: string;
  rss_url: string;
  site_url: string;
  default_category: string;
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
  default_category: string;
}

export interface UpdateSourceRequest {
  name: string;
  rss_url: string;
  site_url: string;
  default_category: string;
  status: string;
}

export interface ErrorResponse {
  error: string;
  message: string;
}
