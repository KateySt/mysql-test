-- comments_censorship.sql

CREATE TABLE IF NOT EXISTS comments (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION censor_bad_words()
RETURNS TRIGGER AS $$
DECLARE
    censored TEXT := NEW.content;
BEGIN
    censored := regexp_replace(censored, '\m(stupid|damn|crap)\M', '***', 'gi');
    NEW.content := censored;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_censor_bad_words ON comments;

CREATE TRIGGER trigger_censor_bad_words
BEFORE INSERT OR UPDATE ON comments
FOR EACH ROW
EXECUTE FUNCTION censor_bad_words();

-- INSERT INTO comments (user_id, content) VALUES (1, 'That stupid idea is total crap');
-- SELECT * FROM comments;
