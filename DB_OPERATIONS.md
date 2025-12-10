# Database Operations Guide

## Overview

This document describes database operations, migrations, seed data, and maintenance procedures for the Nuzzle application using Supabase (PostgreSQL).

## Database Schema

**Location**: `supabase/migrations/`

**Key Tables:**

- `profiles` - User profiles
- `families` - Family groups
- `family_members` - Family membership
- `babies` - Baby profiles
- `events` - All baby care events
- `growth_records` - Growth tracking
- `health_records` - Health data
- `milestones` - Developmental milestones
- `predictions` - AI predictions
- `subscriptions` - User subscriptions

**Full Schema**: See `DATA_MODEL.md`

## Migration Management

### Creating Migrations

**Using Supabase CLI:**

```bash
# Create new migration
supabase migration new migration_name

# Edit the generated SQL file
# supabase/migrations/YYYYMMDDHHMMSS_migration_name.sql
```

**Manual Creation:**

```bash
# Create file with timestamp
touch supabase/migrations/$(date +%Y%m%d%H%M%S)_migration_name.sql
```

### Migration Best Practices

**1. Always Use Transactions:**

```sql
BEGIN;
-- Your migration SQL
COMMIT;
```

**2. Make Migrations Reversible:**

```sql
-- Up migration
CREATE TABLE IF NOT EXISTS new_table (...);

-- Down migration (create separate file or document)
-- DROP TABLE IF EXISTS new_table;
```

**3. Test Migrations:**

```bash
# Test locally
supabase db reset  # Applies all migrations
```

**4. Never Modify Existing Migrations:**

- Create new migration to fix issues
- Document breaking changes

### Applying Migrations

**Local Development:**

```bash
# Reset database (applies all migrations + seed)
supabase db reset

# Apply new migrations only
supabase db push
```

**Staging/Production:**

```bash
# Link to project
supabase link --project-ref your-project-ref

# Push migrations
supabase db push
```

**Via Supabase Dashboard:**

1. Go to Database → Migrations
2. Upload migration file
3. Review and apply

## Seed Data

### Seed Script

**Location**: `supabase/seed.sql` and `supabase/seed_enhanced.sql`

**Purpose:**

- Development testing
- QA environment setup
- Demo data

**Running Seed:**

```bash
# Seed is automatically applied with db reset
supabase db reset

# Or manually
psql -h localhost -U postgres -d postgres -f supabase/seed.sql
```

### Seed Data Structure

**Test Family:**

- Family ID: `11111111-1111-1111-1111-111111111111`
- Name: "Test Family"

**Test Baby:**

- Baby ID: `22222222-2222-2222-2222-222222222222`
- Name: "Test Baby"
- Age: 60 days old

**Sample Events:**

- Feed events (last 12 hours)
- Sleep events (today)
- Diaper events (today)
- Tummy time (today)
- Historical events (yesterday, last week)

### Customizing Seed Data

**Update User ID:**

```sql
-- Get your test user ID
SELECT id FROM auth.users LIMIT 1;

-- Update seed script
UPDATE supabase/seed.sql
SET user_id = 'your-user-id';
```

## Common Operations

### Querying Data

**Via Supabase Dashboard:**

1. Go to SQL Editor
2. Write query
3. Run query

**Via Supabase CLI:**

```bash
# Connect to database
supabase db connect

# Run SQL file
psql -f query.sql
```

**Via Application:**

```typescript
const { data, error } = await supabase
  .from('events')
  .select('*')
  .eq('baby_id', babyId);
```

### Data Export

**Export Table:**

```sql
-- Export to CSV
COPY (SELECT * FROM events) TO '/tmp/events.csv' CSV HEADER;

-- Or via Supabase Dashboard
-- Table Editor → Export → CSV
```

**Export All Data:**

```bash
# Using pg_dump
pg_dump -h db.your-project.supabase.co \
  -U postgres \
  -d postgres \
  -F c \
  -f backup.dump
```

### Data Import

**Import CSV:**

```sql
-- Create temporary table
CREATE TEMP TABLE temp_events (LIKE events);

-- Import CSV
COPY temp_events FROM '/tmp/events.csv' CSV HEADER;

-- Insert into main table
INSERT INTO events SELECT * FROM temp_events;
```

**Import Dump:**

```bash
pg_restore -h db.your-project.supabase.co \
  -U postgres \
  -d postgres \
  backup.dump
```

## Backup & Restore

### Automated Backups

**Supabase Managed:**

- Daily backups (7 days retention)
- Point-in-time recovery available
- Automatic backup scheduling

**Manual Backup:**

```bash
# Full database backup
supabase db dump -f backup.sql

# Specific table
supabase db dump -t events -f events_backup.sql
```

### Restore from Backup

**Full Restore:**

```bash
# Restore from SQL dump
psql -h localhost -U postgres -d postgres -f backup.sql

# Or via Supabase Dashboard
# Database → Backups → Restore
```

**Point-in-Time Recovery:**

1. Go to Supabase Dashboard
2. Database → Backups
3. Select restore point
4. Confirm restore

## Performance Optimization

### Index Management

**Check Existing Indexes:**

```sql
SELECT tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
```

**Create Index:**

```sql
CREATE INDEX IF NOT EXISTS idx_events_baby_id
ON public.events(baby_id);

CREATE INDEX IF NOT EXISTS idx_events_start_time
ON public.events(start_time DESC);
```

**Drop Index:**

```sql
DROP INDEX IF EXISTS idx_events_baby_id;
```

### Query Optimization

**Analyze Query Performance:**

```sql
EXPLAIN ANALYZE
SELECT * FROM events
WHERE baby_id = '...'
AND start_time >= NOW() - INTERVAL '7 days';
```

**Common Optimizations:**

- Add indexes on frequently queried columns
- Use `LIMIT` for large result sets
- Filter early in query
- Use appropriate data types

### Vacuum & Analyze

**Regular Maintenance:**

```sql
-- Vacuum (reclaim space)
VACUUM ANALYZE events;

-- Analyze (update statistics)
ANALYZE events;
```

**Auto-Vacuum:**

- Supabase handles automatically
- Runs during low-traffic periods

## Security Operations

### Row Level Security (RLS)

**Check RLS Status:**

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
```

**Enable RLS:**

```sql
ALTER TABLE public.events ENABLE ROW LEVEL SECURITY;
```

**View Policies:**

```sql
SELECT schemaname, tablename, policyname, cmd, qual
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

**Test RLS:**

```sql
-- As authenticated user
SET ROLE authenticated;
SELECT * FROM events;  -- Should only see own data

-- Reset
RESET ROLE;
```

### User Management

**Create User:**

```sql
-- Via Supabase Auth (recommended)
-- Dashboard → Authentication → Add User

-- Or via SQL (service role only)
INSERT INTO auth.users (id, email, encrypted_password)
VALUES (gen_random_uuid(), 'user@example.com', crypt('password', gen_salt('bf')));
```

**Delete User:**

```sql
-- Via Supabase Dashboard (recommended)
-- Or via SQL (cascades to related data)
DELETE FROM auth.users WHERE id = 'user-id';
```

## Monitoring & Maintenance

### Database Size

**Check Database Size:**

```sql
SELECT
  pg_size_pretty(pg_database_size('postgres')) AS database_size;

SELECT
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

### Connection Monitoring

**Active Connections:**

```sql
SELECT
  pid,
  usename,
  application_name,
  state,
  query_start,
  query
FROM pg_stat_activity
WHERE datname = 'postgres';
```

### Slow Queries

**Enable Query Logging:**

```sql
-- In Supabase Dashboard → Database → Settings
-- Enable "Log Slow Queries"
-- Threshold: 1000ms
```

## Troubleshooting

### Common Issues

**Migration Fails:**

1. Check SQL syntax
2. Verify table doesn't already exist
3. Check for conflicting migrations
4. Review error message

**RLS Blocking Queries:**

1. Verify user is authenticated
2. Check RLS policies
3. Test with service role (temporarily)
4. Review policy conditions

**Performance Issues:**

1. Check for missing indexes
2. Analyze query execution plan
3. Review table statistics
4. Consider partitioning large tables

### Getting Help

**Resources:**

- Supabase Documentation
- PostgreSQL Documentation
- Supabase Discord Community
- GitHub Issues

## Related Documentation

- `DATA_MODEL.md` - Complete schema documentation
- `DB_SECURITY.md` - RLS policies and security
- `supabase/migrations/` - Migration files
- `supabase/seed.sql` - Seed data script
