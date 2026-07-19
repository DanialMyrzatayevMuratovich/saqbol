CREATE TYPE channel AS ENUM ('sms', 'call');
CREATE TYPE verdict AS ENUM ('safe', 'suspicious', 'scam');
CREATE TYPE report_feedback AS ENUM ('confirmed', 'false_positive');

CREATE TABLE users (
    id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    phone         text UNIQUE NOT NULL,
    name          text,
    locale        text NOT NULL DEFAULT 'ru',
    password_hash text NOT NULL,
    created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE scam_categories (
    id          serial PRIMARY KEY,
    name        text UNIQUE NOT NULL,
    description text
);

CREATE TABLE model_versions (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name       text NOT NULL,
    metrics    jsonb,
    trained_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE numbers (
    number        text PRIMARY KEY,
    reports_count int NOT NULL DEFAULT 0,
    risk_score    double precision NOT NULL DEFAULT 0,
    last_reported timestamptz
);

CREATE TABLE messages (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    channel          channel NOT NULL,
    raw_text         text NOT NULL,
    source_number    text,
    scam_probability double precision,
    verdict          verdict,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_user ON messages(user_id);
CREATE INDEX idx_messages_source ON messages(source_number);

CREATE TABLE detections (
    id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    message_id       uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    model_version_id uuid REFERENCES model_versions(id),
    category_id      int REFERENCES scam_categories(id),
    probability      double precision NOT NULL,
    triggers         jsonb NOT NULL DEFAULT '[]',
    latency_ms       int NOT NULL DEFAULT 0,
    created_at       timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_detections_message ON detections(message_id);

CREATE TABLE call_sessions (
    id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    transcript      text,
    max_probability double precision,
    alert_triggered boolean NOT NULL DEFAULT false,
    started_at      timestamptz NOT NULL DEFAULT now(),
    ended_at        timestamptz
);

CREATE INDEX idx_call_sessions_user ON call_sessions(user_id);

CREATE TABLE reports (
    id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    message_id uuid NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    feedback   report_feedback NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_reports_message ON reports(message_id);
