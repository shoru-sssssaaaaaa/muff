"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import {
  getCategoryRules,
  createCategoryRule,
  updateCategoryRule,
  deleteCategoryRule,
  reclassifyArticles,
} from "@/lib/api";
import { CategoryRuleTable } from "@/components/categories/category-rule-table";
import { CategoryRuleDialog } from "@/components/categories/category-rule-dialog";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { toast } from "sonner";
import type { CategoryRuleResponse } from "@/types/api";

export default function CategoriesPage() {
  const queryClient = useQueryClient();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingRule, setEditingRule] = useState<CategoryRuleResponse | null>(null);
  const [deletingRule, setDeletingRule] = useState<CategoryRuleResponse | null>(null);

  const rulesQuery = useQuery({
    queryKey: ["category-rules"],
    queryFn: getCategoryRules,
  });

  const createMutation = useMutation({
    mutationFn: createCategoryRule,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["category-rules"] });
      setDialogOpen(false);
      toast.success("カテゴリルールを作成しました");
    },
    onError: (err) => toast.error(err.message),
  });

  const updateMutation = useMutation({
    mutationFn: ({
      id,
      data,
    }: {
      id: string;
      data: Parameters<typeof updateCategoryRule>[1];
    }) => updateCategoryRule(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["category-rules"] });
      setDialogOpen(false);
      setEditingRule(null);
      toast.success("カテゴリルールを更新しました");
    },
    onError: (err) => toast.error(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteCategoryRule,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["category-rules"] });
      setDeletingRule(null);
      toast.success("カテゴリルールを削除しました");
    },
    onError: (err) => toast.error(err.message),
  });

  const reclassifyMutation = useMutation({
    mutationFn: reclassifyArticles,
    onSuccess: () => {
      toast.success("全記事の再分類が完了しました");
    },
    onError: (err) => toast.error(err.message),
  });

  function handleEdit(rule: CategoryRuleResponse) {
    setEditingRule(rule);
    setDialogOpen(true);
  }

  function handleDialogSubmit(data: {
    name: string;
    keywords: string[];
    is_default: boolean;
    sort_order: number;
  }) {
    if (editingRule) {
      updateMutation.mutate({ id: editingRule.category_rule_id, data });
    } else {
      createMutation.mutate(data);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">カテゴリ管理</h1>
        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            onClick={() => reclassifyMutation.mutate()}
            disabled={reclassifyMutation.isPending}
          >
            {reclassifyMutation.isPending ? "再分類中..." : "全記事再分類"}
          </Button>
          <Button
            onClick={() => {
              setEditingRule(null);
              setDialogOpen(true);
            }}
          >
            新規作成
          </Button>
        </div>
      </div>

      {rulesQuery.isLoading && (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      )}
      {rulesQuery.isError && (
        <p className="text-sm text-destructive">
          カテゴリルールの読み込みに失敗しました。
        </p>
      )}
      {rulesQuery.data && (
        <CategoryRuleTable
          rules={rulesQuery.data}
          onEdit={handleEdit}
          onDelete={setDeletingRule}
        />
      )}

      <CategoryRuleDialog
        open={dialogOpen}
        onOpenChange={(open) => {
          setDialogOpen(open);
          if (!open) setEditingRule(null);
        }}
        rule={editingRule}
        onSubmit={handleDialogSubmit}
        isPending={createMutation.isPending || updateMutation.isPending}
      />

      <Dialog
        open={!!deletingRule}
        onOpenChange={(open) => {
          if (!open) setDeletingRule(null);
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>カテゴリルールの削除</DialogTitle>
            <DialogDescription>
              「{deletingRule?.name}
              」を削除しますか？この操作は取り消せません。
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeletingRule(null)}>
              キャンセル
            </Button>
            <Button
              variant="destructive"
              disabled={deleteMutation.isPending}
              onClick={() => {
                if (deletingRule) {
                  deleteMutation.mutate(deletingRule.category_rule_id);
                }
              }}
            >
              {deleteMutation.isPending ? "削除中..." : "削除"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
