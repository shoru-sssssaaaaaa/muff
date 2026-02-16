"use client";

import Image from "next/image";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import type { ArticleResponse } from "@/types/api";

interface ArticleTableProps {
  articles: ArticleResponse[];
}

export function ArticleTable({ articles }: ArticleTableProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead className="w-[48px]" />
          <TableHead>タイトル</TableHead>
          <TableHead>ソース</TableHead>
          <TableHead>カテゴリ</TableHead>
          <TableHead>公開日時</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {articles.length === 0 && (
          <TableRow>
            <TableCell colSpan={5} className="text-center text-muted-foreground">
              記事が見つかりません。
            </TableCell>
          </TableRow>
        )}
        {articles.map((article) => (
          <TableRow key={article.article_id}>
            <TableCell>
              {article.thumbnail_url ? (
                <Image
                  src={article.thumbnail_url}
                  alt=""
                  width={40}
                  height={40}
                  className="h-10 w-10 rounded object-cover"
                  unoptimized
                />
              ) : (
                <div className="h-10 w-10 rounded bg-muted" />
              )}
            </TableCell>
            <TableCell>
              <a
                href={article.url}
                target="_blank"
                rel="noopener noreferrer"
                className="line-clamp-2 text-sm font-medium hover:underline"
              >
                {article.title}
              </a>
            </TableCell>
            <TableCell className="text-sm">{article.source_name}</TableCell>
            <TableCell>
              <Badge variant="secondary">{article.category}</Badge>
            </TableCell>
            <TableCell className="whitespace-nowrap text-sm">
              {new Date(article.published_at).toLocaleString("ja-JP")}
            </TableCell>
          </TableRow>
        ))}
      </TableBody>
    </Table>
  );
}
