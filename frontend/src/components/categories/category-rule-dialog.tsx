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
import type { CategoryRuleResponse } from "@/types/api";

interface CategoryRuleDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  rule: CategoryRuleResponse | null;
  onSubmit: (data: {
    name: string;
    keywords: string[];
    is_default: boolean;
    sort_order: number;
  }) => void;
  isPending: boolean;
}

export function CategoryRuleDialog({
  open,
  onOpenChange,
  rule,
  onSubmit,
  isPending,
}: CategoryRuleDialogProps) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      {open && (
        <CategoryRuleDialogForm
          rule={rule}
          onSubmit={onSubmit}
          onCancel={() => onOpenChange(false)}
          isPending={isPending}
        />
      )}
    </Dialog>
  );
}

function CategoryRuleDialogForm({
  rule,
  onSubmit,
  onCancel,
  isPending,
}: {
  rule: CategoryRuleResponse | null;
  onSubmit: CategoryRuleDialogProps["onSubmit"];
  onCancel: () => void;
  isPending: boolean;
}) {
  const [name, setName] = useState(rule?.name ?? "");
  const [keywordsText, setKeywordsText] = useState(
    rule?.keywords.join(", ") ?? "",
  );
  const [isDefault, setIsDefault] = useState(rule?.is_default ?? false);
  const [sortOrder, setSortOrder] = useState(rule?.sort_order ?? 0);

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    const keywords = keywordsText
      .split(",")
      .map((k) => k.trim())
      .filter((k) => k.length > 0);
    onSubmit({ name, keywords, is_default: isDefault, sort_order: sortOrder });
  }

  return (
    <DialogContent>
      <DialogHeader>
        <DialogTitle>
          {rule ? "カテゴリルールの編集" : "新規カテゴリルール"}
        </DialogTitle>
      </DialogHeader>
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="space-y-2">
          <Label htmlFor="name">カテゴリ名</Label>
          <Input
            id="name"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="AI"
            required
          />
        </div>
        <div className="space-y-2">
          <Label htmlFor="keywords">キーワード (カンマ区切り)</Label>
          <textarea
            id="keywords"
            value={keywordsText}
            onChange={(e) => setKeywordsText(e.target.value)}
            placeholder="ai, 人工知能, 機械学習, deep learning"
            className="flex min-h-[80px] w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
            required
          />
        </div>
        <div className="flex items-center gap-2">
          <input
            id="isDefault"
            type="checkbox"
            checked={isDefault}
            onChange={(e) => setIsDefault(e.target.checked)}
            className="h-4 w-4 rounded border-gray-300"
          />
          <Label htmlFor="isDefault">
            デフォルトカテゴリ (マッチしない記事に適用)
          </Label>
        </div>
        <div className="space-y-2">
          <Label htmlFor="sortOrder">並び順</Label>
          <Input
            id="sortOrder"
            type="number"
            value={sortOrder}
            onChange={(e) => setSortOrder(Number(e.target.value))}
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
