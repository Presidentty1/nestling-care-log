# Database Operations Guide

This guide explains how to manage the Nestling Supabase database, including migrations, seeding, and maintenance.

## Prerequisites

- Supabase CLI installed: `npm install -g supabase`
- Supabase project access
- Database connection credentials

## Project Structure

```
supabase/
├── migrations/          # SQL migration files
├── functions/          # Edge functions (Deno)
└── config.toml         # Supabase configuration
```

## Migrations

### Overview

Migrations are SQL files that modify the database schema. They are versioned and run in order.

**Location**: `supabase/migrations/`

**Naming**: `{timestamp}_{description}.sql`

### Applying Migrations

#### Local Development

```bash
# Start local Supabase
supabase start

# Apply all migrations
supabase db reset

# Apply new migrations only
supabase migration up
```

#### Production (via Supabase Dashboard)

1. Go to Supabase Dashboard → Database → Migrations
2. Click "New Migration"
3. Paste SQL from migration file
4. Review and apply

#### Production (via CLI)

```bash
# Link to remote project
supabase link --project-ref your-project-ref

# Push migrations
supabase db push
```

### Creating New Migrations

```bash
# Create new migration file
supabase migration new add_new_table

# Edit the generated file in supabase/migrations/
# Then apply locally to test
supabase migration up
```

### Migration Best Practices

1. **Idempotent**: Use `IF NOT EXISTS` / `IF EXISTS` checks
2. **Reversible**: Consider rollback strategy
3. **Tested**: Test locally before pushing to production
4. **Documented**: Add comments explaining changes
5. **RLS**: Always enable RLS and add policies

### Example Migration

```sql
-- Migration: Add new column to events table
ALTER TABLE public.events
ADD COLUMN IF NOT EXISTS duration_sec INTEGER;

-- Add index for performance
CREATE INDEX IF NOT EXISTS idx_events_duration_sec 
ON public.events(duration_sec);

-- Update RLS if needed (already enabled)
-- No policy changes needed for this column
```

## Seeding Data

### Seed Scripts

**Location**: `supabase/seed.sql` (create if needed)

### Creating Seed Data

```sql
-- seed.sql
-- Seed data for local development

-- Create test user (via Supabase Auth UI or API)
-- User ID: 00000000-0000-0000-0000-000000000001

-- Create test family
INSERT INTO public.families (id, name)
VALUES ('11111111-1111-1111-1111-111111111111', 'Test Family')
ON CONFLICT (id) DO NOTHING;

-- Add user to family
INSERT INTO public.family_members (family_id, user_id, role)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  '00000000-0000-0000-0000-000000000001',
  'admin'
)
ON CONFLICT (family_id, user_id) DO NOTHING;

-- Create test baby
INSERT INTO public.babies (
  id, family_id, name, date_of_birth, timezone, primary_feeding_style
)
VALUES (
  '22222222-2222-2222-2222-222222222222',
  '11111111-1111-1111-1111-111111111111',
  'Test Baby',
  CURRENT_DATE - INTERVAL '60 days',
  'UTC',
  'bottle'
)
ON CONFLICT (id) DO NOTHING;

-- Create sample events
INSERT INTO public.events (
  baby_id, family_id, type, subtype, start_time, end_time, amount, unit
)
VALUES
  -- Feed events
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'feed', 'bottle', NOW() - INTERVAL '2 hours', NOW() - INTERVAL '1 hour 45 minutes', 120, 'ml'),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'feed', 'bottle', NOW() - INTERVAL '5 hours', NOW() - INTERVAL '4 hours 30 minutes', 150, 'ml'),
  
  -- Sleep events
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'sleep', 'nap', NOW() - INTERVAL '3 hours', NOW() - INTERVAL '2 hours', NULL, NULL),
  
  -- Diaper events
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'diaper', 'wet', NOW() - INTERVAL '1 hour', NOW() - INTERVAL '1 hour', NULL, NULL),
  ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'diaper', 'both', NOW() - INTERVAL '30 minutes', NOW() - INTERVAL '30 minutes', NULL, NULL);
```

### Running Seed Script

```bash
# Local
supabase db reset  # Resets and applies migrations + seed.sql

# Or manually
psql -h localhost -p 54322 -U postgres -d postgres -f supabase/seed.sql
```

### Seed Data Guidelines

- **Use ON CONFLICT**: Prevent errors on re-runs
- **Realistic Data**: Use realistic dates, amounts, etc.
- **Multiple Scenarios**: Include edge cases (empty states, etc.)
- **No PII**: Don't use real user data
- **Documented**: Comment what each seed record represents

## Database Maintenance

### Backup

```bash
# Create backup
supabase db dump -f backup.sql

# Restore from backup
psql -h localhost -p 54322 -U postgres -d postgres < backup.sql
```

### Index Maintenance

```sql
-- Analyze tables for query optimization
ANALYZE public.events;
ANALYZE public.babies;

-- Rebuild indexes if needed
REINDEX TABLE public.events;
```

### Vacuum

```sql
-- Vacuum to reclaim space
VACUUM ANALYZE public.events;
```

### Monitor Performance

```sql
-- Check slow queries
SELECT * FROM pg_stat_statements 
ORDER BY total_exec_time DESC 
LIMIT 10;

-- Check table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Common Operations

### Reset Local Database

```bash
# Reset everything (migrations + seed)
supabase db reset

# Reset without seed
supabase db reset --no-seed
```

### Check Migration Status

```bash
# List applied migrations
supabase migration list

# Check remote status
supabase db remote commit
```

### Rollback Migration

⚠️ **Warning**: Rolling back migrations is risky. Prefer creating a new migration to fix issues.

```bash
# Rollback last migration (local only)
supabase migration repair --status reverted
```

## Edge Functions

Edge functions are separate from migrations but interact with the database.

**Location**: `supabase/functions/`

**Deploy**:
```bash
supabase functions deploy function-name
```

## Troubleshooting

### Migration Fails

1. **Check logs**: `supabase logs`
2. **Verify SQL syntax**: Test in Supabase SQL editor
3. **Check dependencies**: Ensure referenced tables/columns exist
4. **RLS conflicts**: Verify RLS policies don't conflict

### Seed Data Not Appearing

1. **Check user ID**: Ensure user exists in `auth.users`
2. **Check RLS**: Verify RLS policies allow access
3. **Check conflicts**: Use `ON CONFLICT` to handle duplicates

### Performance Issues

1. **Check indexes**: Ensure indexes exist on frequently queried columns
2. **Analyze queries**: Use `EXPLAIN ANALYZE`
3. **Check RLS**: Complex RLS policies can slow queries

## Production Checklist

Before deploying migrations to production:

- [ ] Test migrations locally
- [ ] Review SQL for security issues
- [ ] Verify RLS policies are correct
- [ ] Check for breaking changes
- [ ] Create backup before applying
- [ ] Test rollback procedure
- [ ] Monitor after deployment

## Resources

- [Supabase Migrations Guide](https://supabase.com/docs/guides/cli/local-development#database-migrations)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Supabase CLI Reference](https://supabase.com/docs/reference/cli)


