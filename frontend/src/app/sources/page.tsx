"use client";

import { useState } from "react";
import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { getSources, createSource, updateSource, deleteSource } from "@/lib/api";
import { SourceTable } from "@/components/sources/source-table";
import { SourceDialog } from "@/components/sources/source-dialog";
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
import type { SourceResponse } from "@/types/api";

export default function SourcesPage() {
  const queryClient = useQueryClient();

  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingSource, setEditingSource] = useState<SourceResponse | null>(null);
  const [deletingSource, setDeletingSource] = useState<SourceResponse | null>(null);

  const sourcesQuery = useQuery({
    queryKey: ["sources"],
    queryFn: getSources,
  });

  const createMutation = useMutation({
    mutationFn: createSource,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sources"] });
      setDialogOpen(false);
      toast.success("ソースを作成しました");
    },
    onError: (err) => toast.error(err.message),
  });

  const updateMutation = useMutation({
    mutationFn: ({ id, data }: { id: string; data: Parameters<typeof updateSource>[1] }) =>
      updateSource(id, data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sources"] });
      setDialogOpen(false);
      setEditingSource(null);
      toast.success("ソースを更新しました");
    },
    onError: (err) => toast.error(err.message),
  });

  const deleteMutation = useMutation({
    mutationFn: deleteSource,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ["sources"] });
      setDeletingSource(null);
      toast.success("ソースを削除しました");
    },
    onError: (err) => toast.error(err.message),
  });

  function handleEdit(source: SourceResponse) {
    setEditingSource(source);
    setDialogOpen(true);
  }

  function handleToggleStatus(source: SourceResponse) {
    const newStatus = source.status === "active" ? "inactive" : "active";
    updateMutation.mutate({
      id: source.source_id,
      data: {
        name: source.name,
        rss_url: source.rss_url,
        site_url: source.site_url,
        default_category: source.default_category,
        status: newStatus,
      },
    });
  }

  function handleDialogSubmit(data: {
    name: string;
    rss_url: string;
    site_url: string;
    default_category: string;
    status?: string;
  }) {
    if (editingSource) {
      updateMutation.mutate({
        id: editingSource.source_id,
        data: {
          ...data,
          status: data.status ?? editingSource.status,
        },
      });
    } else {
      createMutation.mutate(data);
    }
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">ソース管理</h1>
        <Button
          onClick={() => {
            setEditingSource(null);
            setDialogOpen(true);
          }}
        >
          新規作成
        </Button>
      </div>

      {sourcesQuery.isLoading && (
        <p className="text-sm text-muted-foreground">読み込み中...</p>
      )}
      {sourcesQuery.isError && (
        <p className="text-sm text-destructive">ソースの読み込みに失敗しました。</p>
      )}
      {sourcesQuery.data && (
        <SourceTable
          sources={sourcesQuery.data}
          onEdit={handleEdit}
          onDelete={setDeletingSource}
          onToggleStatus={handleToggleStatus}
        />
      )}

      <SourceDialog
        open={dialogOpen}
        onOpenChange={(open) => {
          setDialogOpen(open);
          if (!open) setEditingSource(null);
        }}
        source={editingSource}
        onSubmit={handleDialogSubmit}
        isPending={createMutation.isPending || updateMutation.isPending}
      />

      <Dialog
        open={!!deletingSource}
        onOpenChange={(open) => {
          if (!open) setDeletingSource(null);
        }}
      >
        <DialogContent>
          <DialogHeader>
            <DialogTitle>ソースの削除</DialogTitle>
            <DialogDescription>
              「{deletingSource?.name}」を削除しますか？この操作は取り消せません。
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setDeletingSource(null)}>
              キャンセル
            </Button>
            <Button
              variant="destructive"
              disabled={deleteMutation.isPending}
              onClick={() => {
                if (deletingSource) {
                  deleteMutation.mutate(deletingSource.source_id);
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
