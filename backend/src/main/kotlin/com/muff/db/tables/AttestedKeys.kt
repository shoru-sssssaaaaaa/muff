package com.muff.db.tables

import org.jetbrains.exposed.sql.Table
import org.jetbrains.exposed.sql.kotlin.datetime.timestamp

object AttestedKeys : Table("attested_keys") {
    val keyId = varchar("key_id", 255)
    val publicKey = binary("public_key")
    val receipt = binary("receipt")
    val signCount = long("sign_count")
    val anonDeviceIdHash = varchar("anon_device_id_hash", 128).nullable()
    val createdAt = timestamp("created_at")

    override val primaryKey = PrimaryKey(keyId)
}
