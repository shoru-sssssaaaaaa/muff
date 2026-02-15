"use client";

import { useState } from "react";
import { useQuery } from "@tanstack/react-query";
import { getArticles, getSources } from "@/lib/api";
import { ArticleTable } from "@/components/articles/article-table";
import { Button } from "@/components/ui/button";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

const LIMIT = 20;

export default function ArticlesPage() {
  const [sourceId, setSourceId] = useState<string>("");
  const [category, setCategory] = useState<string>("");
  const [cursors, setCursors] = useState<string[]>([]);

  const currentCursor = cursors.length > 0 ? cursors[cursors.length - 1] : undefined;

  const sourcesQuery = useQuery({
    queryKey: ["sources"],
    queryFn: getSources,
  });

  const articlesQuery = useQuery({
    queryKey: ["articles", sourceId, category, currentCursor],
    queryFn: () =>
      getArticles({
        source_id: sourceId || undefined,
        category: category || undefined,
        cursor: currentCursor,
        limit: LIMIT,
      }),
  });

  const categories = sourcesQuery.data
    ? [...new Set(sourcesQuery.data.map((s) => s.default_category))]
    : [];

  function handleFilterChange(newSourceId: string, newCategory: string) {
    setSourceId(newSourceId);
    setCategory(newCategory);
    setCursors([]);
  }

  function handleNext() {
    if (articlesQuery.data?.next_cursor) {
      setCursors((prev) => [...prev, articlesQuery.data!.next_cursor!]);
    }
  }

  function handlePrev() {
    setCursors((prev) => prev.slice(0, -1));
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-bold">記事一覧</h1>

      <div className="flex flex-wrap gap-3">
        <Select
          value={sourceId}
          onValueChange={(val) => handleFilterChange(val === "__all__" ? "" : val, category)}
        >
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder="すべてのソース" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="__all__">すべてのソース</SelectItem>
            {sourcesQuery.data?.map((source) => (
              <SelectItem key={source.source_id} value={source.source_id}>
                {source.name}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>

        <Select
          value={category}
          onValueChange={(val) => handleFilterChange(sourceId, val === "__all__" ? "" : val)}
        >
          <SelectTrigger className="w-[200px]">
            <SelectValue placeholder="すべてのカテゴリ" />
          </SelectTrigger>
          <SelectContent>
            <SelectItem value="__all__">すべてのカテゴリ</SelectItem>
            {categories.map((cat) => (
              <SelectItem key={cat} value={cat}>
                {cat}
              </SelectItem>
            ))}
          </SelectContent>
        </Select>
      </div>

      {articlesQuery.isLoading && (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      )}
      {articlesQuery.isError && (
        <p className="text-sm text-destructive">記事の読み込みに失敗しました。</p>
      )}
      {articlesQuery.data && (
        <>
          <ArticleTable articles={articlesQuery.data.items} />
          <div className="flex items-center justify-between">
            <Button
              variant="outline"
              disabled={cursors.length === 0}
              onClick={handlePrev}
            >
              前へ
            </Button>
            <span className="text-sm text-muted-foreground">
              {cursors.length + 1} ページ目
            </span>
            <Button
              variant="outline"
              disabled={!articlesQuery.data.next_cursor}
              onClick={handleNext}
            >
              次へ
            </Button>
          </div>
        </>
      )}
    </div>
  );
}
