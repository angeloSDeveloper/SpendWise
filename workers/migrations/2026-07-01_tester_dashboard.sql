ALTER TABLE users
ADD COLUMN role TEXT NOT NULL DEFAULT 'user'
CHECK(role IN ('user','tester','admin'));

UPDATE users
SET role = 'tester'
WHERE email = 'acampione97@gmail.com';

CREATE TABLE IF NOT EXISTS notification_test_results (
  user_id TEXT NOT NULL,
  test_key TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'pending'
    CHECK(status IN ('pending','passed','partial','ko')),
  updated_at INTEGER NOT NULL,
  PRIMARY KEY (user_id, test_key),
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);
