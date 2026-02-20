"use client";

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
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import type { CategoryRuleResponse } from "@/types/api";

interface CategoryRuleTableProps {
  rules: CategoryRuleResponse[];
  onEdit: (rule: CategoryRuleResponse) => void;
  onDelete: (rule: CategoryRuleResponse) => void;
}

export function CategoryRuleTable({
  rules,
  onEdit,
  onDelete,
}: CategoryRuleTableProps) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>カテゴリ名</TableHead>
          <TableHead>キーワード</TableHead>
          <TableHead className="w-[80px]">記事数</TableHead>
          <TableHead className="w-[100px]">デフォルト</TableHead>
          <TableHead className="w-[80px]">並び順</TableHead>
          <TableHead className="w-[80px]" />
        </TableRow>
      </TableHeader>
      <TableBody>
        {rules.length === 0 && (
          <TableRow>
            <TableCell colSpan={6} className="text-center text-muted-foreground">
              カテゴリルールが見つかりません。
            </TableCell>
          </TableRow>
        )}
        {rules.map((rule) => (
          <TableRow key={rule.category_rule_id}>
            <TableCell className="font-medium">{rule.name}</TableCell>
            <TableCell>
              <div className="flex flex-wrap gap-1">
                {rule.keywords.slice(0, 10).map((kw) => (
                  <Badge key={kw} variant="outline" className="text-xs">
                    {kw}
                  </Badge>
                ))}
                {rule.keywords.length > 10 && (
                  <Badge variant="secondary" className="text-xs">
                    +{rule.keywords.length - 10}
                  </Badge>
                )}
              </div>
            </TableCell>
            <TableCell className="text-sm tabular-nums">
              {rule.article_count.toLocaleString()}
            </TableCell>
            <TableCell>
              {rule.is_default && (
                <Badge variant="default" className="text-xs">
                  デフォルト
                </Badge>
              )}
            </TableCell>
            <TableCell className="text-sm">{rule.sort_order}</TableCell>
            <TableCell>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" size="sm">
                    ...
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem onClick={() => onEdit(rule)}>
                    編集
                  </DropdownMenuItem>
                  <DropdownMenuItem
                    className="text-destructive"
                    onClick={() => onDelete(rule)}
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
  );
}
