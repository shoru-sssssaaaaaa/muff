-- Sources
CREATE TABLE sources (
    source_id UUID PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    rss_url VARCHAR(2048) NOT NULL,
    site_url VARCHAR(2048) NOT NULL,
    default_category VARCHAR(100) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    last_fetch_at TIMESTAMP NULL,
    last_success_at TIMESTAMP NULL,
    consecutive_failures INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX sources_rss_url_unique ON sources (rss_url);

-- Articles
CREATE TABLE articles (
    article_id UUID PRIMARY KEY,
    source_id UUID NOT NULL REFERENCES sources(source_id),
    title TEXT NOT NULL,
    url VARCHAR(2048) NOT NULL,
    published_at TIMESTAMP NOT NULL,
    thumbnail_url VARCHAR(2048) NULL,
    category VARCHAR(100) NOT NULL,
    rss_category TEXT NULL,
    rule_category VARCHAR(100) NULL,
    ingested_at TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX articles_url_unique ON articles (url);
CREATE INDEX articles_published_at_article_id ON articles (published_at, article_id);
CREATE INDEX articles_category_published_at_article_id ON articles (category, published_at, article_id);

-- Open Events
CREATE TABLE open_events (
    event_id UUID PRIMARY KEY,
    article_url VARCHAR(2048) NOT NULL,
    article_id UUID NULL,
    occurred_at TIMESTAMP NOT NULL,
    anon_device_id_hash VARCHAR(128) NOT NULL,
    app_version VARCHAR(50) NOT NULL,
    created_at TIMESTAMP NOT NULL
);
CREATE INDEX open_events_occurred_at ON open_events (occurred_at);

-- Popularity Buckets
CREATE TABLE popularity_buckets (
    id BIGSERIAL PRIMARY KEY,
    bucket_start_at TIMESTAMP NOT NULL,
    article_id UUID NOT NULL REFERENCES articles(article_id),
    open_count INT NOT NULL
);
CREATE UNIQUE INDEX popularity_buckets_bucket_start_at_article_id ON popularity_buckets (bucket_start_at, article_id);
CREATE INDEX popularity_buckets_bucket_start_at_open_count ON popularity_buckets (bucket_start_at, open_count);

-- Category Rules
CREATE TABLE category_rules (
    category_rule_id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    keywords TEXT NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT false,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL
);
CREATE UNIQUE INDEX category_rules_name_unique ON category_rules (name);

-- Attested Keys
CREATE TABLE attested_keys (
    key_id VARCHAR(255) PRIMARY KEY,
    public_key BYTEA NOT NULL,
    receipt BYTEA NOT NULL,
    sign_count BIGINT NOT NULL,
    anon_device_id_hash VARCHAR(128) NULL,
    created_at TIMESTAMP NOT NULL
);

-- Attest Challenges
CREATE TABLE attest_challenges (
    challenge VARCHAR(255) PRIMARY KEY,
    expires_at TIMESTAMP NOT NULL,
    used BOOLEAN NOT NULL DEFAULT false
);
