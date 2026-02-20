package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object CategoryRules : Table("category_rules") {
    val categoryRuleId = uuid("category_rule_id")
    val name = varchar("name", 100).uniqueIndex()
    val keywords = text("keywords") // カンマ区切り
    val isDefault = bool("is_default").default(false)
    val sortOrder = integer("sort_order").default(0)
    val createdAt = timestamp("created_at")

    override val primaryKey = PrimaryKey(categoryRuleId)
}
