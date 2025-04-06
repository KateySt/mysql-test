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


---

CREATE TABLE IF NOT EXISTS login_attempts (
    id SERIAL PRIMARY KEY,
    username TEXT NOT NULL,
    success BOOLEAN NOT NULL,
    attempt_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE OR REPLACE FUNCTION check_login_rate()
RETURNS TRIGGER AS $$
DECLARE
    recent_failures INTEGER;
BEGIN
    -- Count failed login attempts in the last 5 minutes
    SELECT COUNT(*) INTO recent_failures
    FROM login_attempts
    WHERE username = NEW.username
      AND success = FALSE
      AND attempt_time > (CURRENT_TIMESTAMP - INTERVAL '5 minutes');

    -- If 5 or more failures → block this attempt
    IF recent_failures >= 5 THEN
        RAISE EXCEPTION 'Too many failed login attempts for user % — please try again later.', NEW.username;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS prevent_brute_force ON login_attempts;

CREATE TRIGGER prevent_brute_force
BEFORE INSERT ON login_attempts
FOR EACH ROW
EXECUTE FUNCTION check_login_rate();

-- Uncomment and run these manually for testing

-- INSERT INTO login_attempts (username, success) VALUES ('hacker', FALSE);
-- INSERT INTO login_attempts (username, success) VALUES ('hacker', FALSE);
-- INSERT INTO login_attempts (username, success) VALUES ('hacker', FALSE);
-- INSERT INTO login_attempts (username, success) VALUES ('hacker', FALSE);
-- INSERT INTO login_attempts (username, success) VALUES ('hacker', FALSE);

-- -- This 6th attempt (within 5 min) will be blocked
-- INSERT INTO login_attempts (username, success) VALUES ('hacker', FALSE);
