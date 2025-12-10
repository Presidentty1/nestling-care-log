# Database Replication Guide

This document describes how to set up database replication for Nestling's Supabase database.

## Overview

Database replication provides:

- **High Availability**: Automatic failover if primary database fails
- **Read Scalability**: Distribute read queries across replicas
- **Disaster Recovery**: Backup database in different region
- **Zero Downtime**: Seamless failover for users

## Supabase Replication

Supabase uses PostgreSQL streaming replication. Replication can be configured via:

1. **Supabase Dashboard** (recommended)
2. **Supabase CLI**
3. **Direct PostgreSQL configuration** (advanced)

## Setup via Supabase Dashboard

### Step 1: Enable Replication

1. Go to Supabase Dashboard → Project Settings → Database
2. Navigate to "Replication" section
3. Click "Enable Replication"
4. Select replication type:
   - **Read Replicas**: For read scaling
   - **Standby Replicas**: For high availability

### Step 2: Configure Replica

1. Select region for replica (should be different from primary)
2. Choose instance size (can be smaller than primary for read replicas)
3. Configure replication lag tolerance
4. Enable automatic failover (for standby replicas)

### Step 3: Update Application

Update Supabase client configuration to use read replicas for read queries:

```typescript
// In edge functions or server-side code
const readClient = createClient(
  process.env.SUPABASE_READ_REPLICA_URL,
  process.env.SUPABASE_ANON_KEY
);

// Use readClient for SELECT queries
const { data } = await readClient.from('events').select('*');
```

## Monitoring Replication

### Check Replication Status

```sql
-- Check replication lag
SELECT * FROM public.check_replication_lag();

-- Check replication slots (requires superuser)
SELECT * FROM pg_replication_slots;
```

### Monitor via Supabase Dashboard

1. Go to Database → Replication
2. View replication lag metrics
3. Monitor replica health
4. Check failover status

## Replication Types

### Read Replicas

**Use Case**: Scale read queries

**Configuration**:

- Multiple read replicas allowed
- Asynchronous replication
- Small replication lag acceptable
- No automatic failover

**Best For**:

- Analytics queries
- Reporting
- Read-heavy workloads

### Standby Replicas

**Use Case**: High availability

**Configuration**:

- Single standby replica
- Synchronous or asynchronous replication
- Automatic failover
- Same region or different region

**Best For**:

- Production databases
- Critical applications
- Zero-downtime requirements

## Application Changes

### Read/Write Splitting

```typescript
// Primary client (writes)
const writeClient = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_ANON_KEY
);

// Read replica client (reads)
const readClient = createClient(
  process.env.SUPABASE_READ_REPLICA_URL,
  process.env.SUPABASE_ANON_KEY
);

// Write operations
await writeClient.from('events').insert(data);

// Read operations
const { data } = await readClient.from('events').select('*');
```

### Automatic Failover

If using standby replica with automatic failover:

- Supabase handles failover automatically
- DNS updates point to new primary
- Application reconnects automatically
- No code changes required

## Performance Considerations

### Replication Lag

- **Asynchronous**: 1-5 seconds typical lag
- **Synchronous**: < 100ms lag (slower writes)
- Monitor lag and adjust if needed

### Query Routing

- Route read queries to replicas
- Route write queries to primary
- Use connection pooling for both

## Cost Considerations

### Read Replicas

- Additional compute cost (replica instance)
- Storage cost (duplicate data)
- Network cost (replication traffic)

### Standby Replicas

- Full replica instance cost
- Automatic failover premium
- Consider multi-region costs

## Disaster Recovery

### Backup Strategy

1. **Primary Database**: Daily backups
2. **Replica Database**: Continuous replication
3. **Point-in-Time Recovery**: Enabled by default

### Recovery Procedures

1. **Primary Failure**: Automatic failover to standby
2. **Replica Failure**: Create new replica from primary
3. **Data Corruption**: Restore from backup

## Testing Replication

### Test Read Replicas

```sql
-- On primary
INSERT INTO events (baby_id, type, start_time) VALUES (...);

-- On replica (should appear within seconds)
SELECT * FROM events WHERE id = ...;
```

### Test Failover

1. Simulate primary failure (via dashboard)
2. Verify automatic failover
3. Check application connectivity
4. Verify data consistency

## Troubleshooting

### High Replication Lag

- Check network connectivity
- Verify replica instance size
- Monitor primary database load
- Consider synchronous replication

### Replication Not Working

- Verify replication enabled in dashboard
- Check replication slots
- Verify network connectivity
- Check replica instance status

## Best Practices

1. **Monitor Lag**: Set up alerts for high replication lag
2. **Test Failover**: Regularly test failover procedures
3. **Document Procedures**: Keep runbooks updated
4. **Cost Optimization**: Use read replicas only when needed
5. **Security**: Ensure replicas have same RLS policies

## References

- [Supabase Replication Docs](https://supabase.com/docs/guides/database/replication)
- [PostgreSQL Replication](https://www.postgresql.org/docs/current/high-availability.html)
- [Supabase Status Page](https://status.supabase.com/)
