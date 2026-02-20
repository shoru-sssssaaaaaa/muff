package com.muff.service

import com.muff.db.tables.CategoryRules
import org.jetbrains.exposed.sql.SortOrder
import org.jetbrains.exposed.sql.selectAll
import org.jetbrains.exposed.sql.transactions.transaction

class CategoryClassifier {
    private data class Rule(
        val category: String,
        val keywords: List<String>,
    )

    private var cachedRules: List<Rule> = emptyList()
    private var defaultCategory: String = "ネタ・その他"

    fun reloadRules() {
        transaction {
            val rows =
                CategoryRules.selectAll()
                    .orderBy(CategoryRules.sortOrder to SortOrder.ASC)
                    .toList()
            cachedRules =
                rows.map { row ->
                    Rule(
                        category = row[CategoryRules.name],
                        keywords =
                        row[CategoryRules.keywords]
                            .split(",")
                            .map { it.trim().lowercase() }
                            .filter { it.isNotEmpty() },
                    )
                }
            defaultCategory =
                rows.firstOrNull { it[CategoryRules.isDefault] }
                    ?.get(CategoryRules.name) ?: "ネタ・その他"
        }
    }

    fun classify(title: String): String {
        val lowerTitle = title.lowercase()
        val scores = mutableMapOf<String, Int>()

        for (rule in cachedRules) {
            val matchCount = rule.keywords.count { keyword -> lowerTitle.contains(keyword) }
            if (matchCount > 0) {
                scores[rule.category] = matchCount
            }
        }

        return scores.maxByOrNull { it.value }?.key ?: defaultCategory
    }
}
