ALTER TABLE subscriptions ADD COLUMN next_due_date INTEGER;
ALTER TABLE subscriptions ADD COLUMN recurrence_months INTEGER;
ALTER TABLE vehicles ADD COLUMN is_archived INTEGER DEFAULT 0;
