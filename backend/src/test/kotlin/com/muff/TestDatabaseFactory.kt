package com.muff

import com.muff.db.tables.Articles
import com.muff.db.tables.OpenEvents
import com.muff.db.tables.PopularityBuckets
import com.muff.db.tables.Sources
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.SchemaUtils
import org.jetbrains.exposed.sql.transactions.transaction

object TestDatabaseFactory {

    fun init() {
        Database.connect(
            url = "jdbc:h2:mem:test;DB_CLOSE_DELAY=-1;MODE=PostgreSQL",
            driver = "org.h2.Driver",
        )
        transaction {
            SchemaUtils.create(Sources, Articles, OpenEvents, PopularityBuckets)
        }
    }

    fun cleanup() {
        transaction {
            SchemaUtils.drop(PopularityBuckets, OpenEvents, Articles, Sources)
            SchemaUtils.create(Sources, Articles, OpenEvents, PopularityBuckets)
        }
    }
}
