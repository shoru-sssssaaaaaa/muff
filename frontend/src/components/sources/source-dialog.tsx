"use client";

import { useEffect, useState } from "react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import type { SourceResponse } from "@/types/api";

interface SourceDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  source: SourceResponse | null;
  onSubmit: (data: {
    name: string;
    rss_url: string;
    site_url: string;
    default_category: string;
    status?: string;
  }) => void;
  isPending: boolean;
}

export function SourceDialog({
  open,
  onOpenChange,
  source,
  onSubmit,
  isPending,
}: SourceDialogProps) {
  const [name, setName] = useState("");
  const [rssUrl, setRssUrl] = useState("");
  const [siteUrl, setSiteUrl] = useState("");
  const [category, setCategory] = useState("");

  useEffect(() => {
    if (source) {
      setName(source.name);
      setRssUrl(source.rss_url);
      setSiteUrl(source.site_url);
      setCategory(source.default_category);
    } else {
      setName("");
      setRssUrl("");
      setSiteUrl("");
      setCategory("");
    }
  }, [source, open]);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    onSubmit({
      name,
      rss_url: rssUrl,
      site_url: siteUrl,
      default_category: category,
      ...(source ? { status: source.status } : {}),
    });
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>{source ? "ソースの編集" : "新規ソース"}</DialogTitle>
        </DialogHeader>
        <form onSubmit={handleSubmit} className="space-y-4">
          <div className="space-y-2">
            <Label htmlFor="name">名前</Label>
            <Input
              id="name"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="サイト名"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="rssUrl">RSS URL</Label>
            <Input
              id="rssUrl"
              type="url"
              value={rssUrl}
              onChange={(e) => setRssUrl(e.target.value)}
              placeholder="https://example.com/rss"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="siteUrl">サイトURL</Label>
            <Input
              id="siteUrl"
              type="url"
              value={siteUrl}
              onChange={(e) => setSiteUrl(e.target.value)}
              placeholder="https://example.com"
              required
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="category">カテゴリ</Label>
            <Input
              id="category"
              value={category}
              onChange={(e) => setCategory(e.target.value)}
              placeholder="ニュース"
              required
            />
          </div>
          <DialogFooter>
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              キャンセル
            </Button>
            <Button type="submit" disabled={isPending}>
              {isPending ? "保存中..." : "保存"}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
