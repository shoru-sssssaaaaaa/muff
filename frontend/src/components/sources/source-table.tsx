"use client";

import { useState } from "react";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { SourceResponse } from "@/types/api";

interface SourceTableProps {
  sources: SourceResponse[];
  onEdit: (source: SourceResponse) => void;
  onDelete: (source: SourceResponse) => void;
  onToggleStatus: (source: SourceResponse) => void;
}

export function SourceTable({
  sources,
  onEdit,
  onDelete,
  onToggleStatus,
}: SourceTableProps) {
  const [errorSource, setErrorSource] = useState<SourceResponse | null>(null);

  return (
    <>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>名前</TableHead>
            <TableHead>RSS URL</TableHead>
            <TableHead>サイトURL</TableHead>
            <TableHead>カテゴリ</TableHead>
            <TableHead>ステータス</TableHead>
            <TableHead className="w-[80px]" />
          </TableRow>
        </TableHeader>
        <TableBody>
          {sources.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="text-center text-muted-foreground">
                ソースが見つかりません。
              </TableCell>
            </TableRow>
          )}
          {sources.map((source) => (
            <TableRow key={source.source_id}>
              <TableCell className="font-medium">
                <div className="flex items-center gap-2">
                  {source.name}
                  {source.consecutive_failures > 0 && (
                    <button
                      onClick={() => setErrorSource(source)}
                      className="text-amber-500 hover:text-amber-600"
                      title="RSS取得エラーあり"
                    >
                      ⚠
                    </button>
                  )}
                </div>
              </TableCell>
              <TableCell className="max-w-[200px] truncate text-xs">
                {source.rss_url}
              </TableCell>
              <TableCell className="max-w-[200px] truncate text-xs">
                {source.site_url}
              </TableCell>
              <TableCell>
                <Badge variant="secondary">{source.default_category}</Badge>
              </TableCell>
              <TableCell>
                <Badge
                  variant={source.status === "active" ? "default" : "outline"}
                  className="cursor-pointer"
                  onClick={() => onToggleStatus(source)}
                >
                  {source.status}
                </Badge>
              </TableCell>
              <TableCell>
                <DropdownMenu>
                  <DropdownMenuTrigger asChild>
                    <Button variant="ghost" size="sm">
                      ...
                    </Button>
                  </DropdownMenuTrigger>
                  <DropdownMenuContent align="end">
                    <DropdownMenuItem onClick={() => onEdit(source)}>
                      編集
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      onClick={() => onToggleStatus(source)}
                    >
                      {source.status === "active" ? "無効にする" : "有効にする"}
                    </DropdownMenuItem>
                    <DropdownMenuItem
                      className="text-destructive"
                      onClick={() => onDelete(source)}
                    >
                      削除
                    </DropdownMenuItem>
                  </DropdownMenuContent>
                </DropdownMenu>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <Dialog open={!!errorSource} onOpenChange={(open) => { if (!open) setErrorSource(null); }}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>RSS取得エラー: {errorSource?.name}</DialogTitle>
            <DialogDescription>
              このソースのRSS取得でエラーが発生しています。
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">連続失敗回数</span>
              <span className="font-medium text-destructive">
                {errorSource?.consecutive_failures} 回
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">最終取得試行</span>
              <span>
                {errorSource?.last_fetch_at
                  ? new Date(errorSource.last_fetch_at).toLocaleString("ja-JP")
                  : "—"}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">最終成功日時</span>
              <span>
                {errorSource?.last_success_at
                  ? new Date(errorSource.last_success_at).toLocaleString("ja-JP")
                  : "—"}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-muted-foreground">RSS URL</span>
              <span className="max-w-[300px] truncate">{errorSource?.rss_url}</span>
            </div>
          </div>
        </DialogContent>
      </Dialog>
    </>
  );
}
