package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object AttestChallenges : Table("attest_challenges") {
    val challenge = varchar("challenge", 255)
    val expiresAt = timestamp("expires_at")
    val used = bool("used").default(false)

    override val primaryKey = PrimaryKey(challenge)
}
