"use client";

import { useState } from "react";
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
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      {open && (
        <SourceDialogForm
          source={source}
          onSubmit={onSubmit}
          onCancel={() => onOpenChange(false)}
          isPending={isPending}
        />
      )}
    </Dialog>
  );
}

function SourceDialogForm({
  source,
  onSubmit,
  onCancel,
  isPending,
}: {
  source: SourceResponse | null;
  onSubmit: SourceDialogProps["onSubmit"];
  onCancel: () => void;
  isPending: boolean;
}) {
  const [name, setName] = useState(source?.name ?? "");
  const [rssUrl, setRssUrl] = useState(source?.rss_url ?? "");
  const [siteUrl, setSiteUrl] = useState(source?.site_url ?? "");

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    onSubmit({
      name,
      rss_url: rssUrl,
      site_url: siteUrl,
      ...(source ? { status: source.status } : {}),
    });
  }

  return (
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
        <DialogFooter>
          <Button type="button" variant="outline" onClick={onCancel}>
            キャンセル
          </Button>
          <Button type="submit" disabled={isPending}>
            {isPending ? "保存中..." : "保存"}
          </Button>
        </DialogFooter>
      </form>
    </DialogContent>
  );
}
