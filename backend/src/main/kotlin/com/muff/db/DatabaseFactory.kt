package com.muff.db

import com.muff.config.AppConfig
import com.muff.db.tables.Articles
import com.muff.db.tables.OpenEvents
import com.muff.db.tables.PopularityBuckets
import com.muff.db.tables.Sources
import com.zaxxer.hikari.HikariConfig
import com.zaxxer.hikari.HikariDataSource
import org.jetbrains.exposed.sql.Database
import org.jetbrains.exposed.sql.SchemaUtils
import org.jetbrains.exposed.sql.transactions.transaction

object DatabaseFactory {
    fun init(config: AppConfig.DatabaseConfig) {
        val dataSource = hikari(config)
        Database.connect(dataSource)
        transaction {
            SchemaUtils.createMissingTablesAndColumns(
                Sources,
                Articles,
                OpenEvents,
                PopularityBuckets,
            )
        }
    }

    private fun hikari(config: AppConfig.DatabaseConfig): HikariDataSource {
        val hikariConfig =
            HikariConfig().apply {
                jdbcUrl = config.url
                username = config.user
                password = config.password
                maximumPoolSize = config.maxPoolSize
                isAutoCommit = false
                transactionIsolation = "TRANSACTION_REPEATABLE_READ"
                validate()
            }
        return HikariDataSource(hikariConfig)
    }
}
