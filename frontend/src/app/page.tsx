"use client";

import { useQuery } from "@tanstack/react-query";
import { getSources, getArticles, getPopularArticles } from "@/lib/api";
import {
  Card,
  CardContent,
  CardDescription,
  CardHeader,
  CardTitle,
} from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

export default function DashboardPage() {
  const sourcesQuery = useQuery({
    queryKey: ["sources"],
    queryFn: getSources,
  });

  const articlesQuery = useQuery({
    queryKey: ["articles", "recent"],
    queryFn: () => getArticles({ limit: 10 }),
  });

  const popularQuery = useQuery({
    queryKey: ["popular"],
    queryFn: () => getPopularArticles(20),
  });

  const activeSources =
    sourcesQuery.data?.filter((s) => s.status === "active").length ?? 0;
  const totalSources = sourcesQuery.data?.length ?? 0;
  const totalArticles = articlesQuery.data?.items.length ?? 0;

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">ダッシュボード</h1>

      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <Card>
          <CardHeader className="pb-2">
            <CardDescription>ソース数</CardDescription>
            <CardTitle className="text-3xl">{totalSources}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              {activeSources} 件が有効
            </p>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-2">
            <CardDescription>最新記事</CardDescription>
            <CardTitle className="text-3xl">{totalArticles}</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">
              直近の取り込み
            </p>
          </CardContent>
        </Card>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>人気記事</CardTitle>
          <CardDescription>閲覧数が多い記事（人気順）</CardDescription>
        </CardHeader>
        <CardContent>
          {popularQuery.isLoading && (
            <p className="text-sm text-muted-foreground">読み込み中...</p>
          )}
          {popularQuery.isError && (
            <p className="text-sm text-destructive">
              人気記事の読み込みに失敗しました。
            </p>
          )}
          {popularQuery.data && popularQuery.data.items.length === 0 && (
            <p className="text-sm text-muted-foreground">人気記事はまだありません。</p>
          )}
          <div className="space-y-3">
            {popularQuery.data?.items.map((article, index) => (
              <div
                key={article.article_id}
                className="flex items-start gap-3 rounded-md border p-3"
              >
                <span className="flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-muted text-xs font-bold">
                  {index + 1}
                </span>
                {article.thumbnail_url && (
                  <img
                    src={article.thumbnail_url}
                    alt=""
                    className="h-12 w-12 shrink-0 rounded object-cover"
                  />
                )}
                <div className="min-w-0 flex-1">
                  <a
                    href={article.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="line-clamp-1 text-sm font-medium hover:underline"
                  >
                    {article.title}
                  </a>
                  <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                    <span>{article.source_name}</span>
                    <Badge variant="secondary" className="text-xs">
                      {article.category}
                    </Badge>
                    {article.view_count != null && (
                      <span>{article.view_count} views</span>
                    )}
                    <span>
                      {new Date(article.published_at).toLocaleString("ja-JP")}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>最新記事</CardTitle>
          <CardDescription>最近取り込まれた記事</CardDescription>
        </CardHeader>
        <CardContent>
          {articlesQuery.isLoading && (
            <p className="text-sm text-muted-foreground">読み込み中...</p>
          )}
          {articlesQuery.isError && (
            <p className="text-sm text-destructive">
              記事の読み込みに失敗しました。
            </p>
          )}
          {articlesQuery.data && articlesQuery.data.items.length === 0 && (
            <p className="text-sm text-muted-foreground">記事はまだありません。</p>
          )}
          <div className="space-y-3">
            {articlesQuery.data?.items.map((article) => (
              <div
                key={article.article_id}
                className="flex items-start gap-3 rounded-md border p-3"
              >
                {article.thumbnail_url && (
                  <img
                    src={article.thumbnail_url}
                    alt=""
                    className="h-12 w-12 shrink-0 rounded object-cover"
                  />
                )}
                <div className="min-w-0 flex-1">
                  <a
                    href={article.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="line-clamp-1 text-sm font-medium hover:underline"
                  >
                    {article.title}
                  </a>
                  <div className="mt-1 flex items-center gap-2 text-xs text-muted-foreground">
                    <span>{article.source_name}</span>
                    <Badge variant="secondary" className="text-xs">
                      {article.category}
                    </Badge>
                    <span>
                      {new Date(article.published_at).toLocaleString("ja-JP")}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
