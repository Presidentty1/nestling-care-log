# Database Security Documentation

## Overview

Nestling uses Supabase PostgreSQL with **Row Level Security (RLS)** to ensure data isolation between families and prevent cross-tenant data leakage.

## Security Model

### Multi-Tenancy via Families

- Each user belongs to one or more **families**
- All data (babies, events) is scoped to a `family_id`
- Users can only access data for families they belong to
- Family members can have roles: `admin`, `member`, or `viewer`

### Role-Based Access Control

**Admin**:
- Can manage family members (invite, remove, change roles)
- Can update family settings
- Can delete babies
- Can create/update/delete events

**Member**:
- Can view all family data
- Can create/update babies
- Can create/update/delete events
- Cannot manage family members

**Viewer**:
- Can view all family data (read-only)
- Cannot create/update/delete anything

## Row Level Security Policies

### Core Tables

#### `profiles`

**Policies**:
- Users can view their own profile
- Users can update their own profile
- Users can insert their own profile

**Security**: ✅ Users cannot access other users' profiles

#### `families`

**Policies**:
- Users can view families they belong to
- Users can create families
- Admins can update their families

**Security**: ✅ Users cannot see families they don't belong to

#### `family_members`

**Policies**:
- Users can view family members of their families
- Users can insert themselves as family members
- Admins can manage family members (update/delete)

**Security**: ✅ Users cannot see members of other families

#### `babies`

**Policies**:
- Users can view babies in their families
- Members/admins can create babies in their families
- Members/admins can update babies in their families
- Admins can delete babies

**Security**: ✅ Users cannot access babies from other families

#### `events`

**Policies**:
- Users can view events for babies in their families
- Members/admins can create events in their families
- Members/admins can update events in their families
- Members/admins can delete events in their families

**Security**: ✅ Users cannot access events from other families

### Additional Tables

All other tables follow the same pattern:
- **View**: Users can view data for babies in their families
- **Create/Update/Delete**: Members/admins can manage data in their families

## Security Guarantees

### ✅ Data Isolation

- Users **cannot** access data from families they don't belong to
- All queries are automatically filtered by `family_id` via RLS
- No cross-tenant data leakage possible

### ✅ Role Enforcement

- Role checks enforced at database level (not just application level)
- Viewers cannot modify data even if they bypass application checks
- Admins have elevated permissions only for their families

### ✅ Authentication Required

- All RLS policies check `auth.uid()` (authenticated user ID)
- Unauthenticated users cannot access any data
- Edge functions verify authentication before database access

## Testing RLS Policies

### Manual Testing

1. **Create two test users**:
   - User A: `test-a@example.com`
   - User B: `test-b@example.com`

2. **Create separate families**:
   - Family 1: User A creates
   - Family 2: User B creates

3. **Verify isolation**:
   - User A should NOT see Family 2's babies/events
   - User B should NOT see Family 1's babies/events

### Automated Testing

```sql
-- Test: User cannot access other family's data
SET ROLE authenticated;
SET request.jwt.claim.sub = 'user-a-uuid';

-- Should return empty (User A cannot see Family 2)
SELECT * FROM babies WHERE family_id = 'family-2-uuid';

-- Should return data (User A can see Family 1)
SELECT * FROM babies WHERE family_id = 'family-1-uuid';
```

## Edge Cases Handled

### ✅ Family Member Removal

- When a user is removed from a family, they immediately lose access
- RLS policies prevent access even if session is still active
- No orphaned data access possible

### ✅ Baby Deletion

- When a baby is deleted, all related events are cascade-deleted
- RLS ensures only admins can delete babies
- No data leakage from deleted babies

### ✅ Event Ownership

- Events are scoped to `family_id`, not individual users
- Any family member (with appropriate role) can view/edit events
- `created_by` field tracks creator but doesn't restrict access

## Security Best Practices

### ✅ Always Use RLS

- Never disable RLS for any table
- All tables have RLS enabled
- Policies are tested and verified

### ✅ Use Parameterized Queries

- All Supabase queries use parameterized queries (built-in)
- No SQL injection possible
- Edge functions use Supabase client (safe)

### ✅ Validate Input

- Application-level validation (Zod schemas)
- Database-level constraints (CHECK constraints)
- Type safety via TypeScript

### ✅ Audit Logging

- `created_by` field tracks who created records
- `created_at` / `updated_at` track timestamps
- Can audit changes via `updated_at` triggers

## Known Limitations

### ⚠️ Service Role Bypass

- Service role (used by edge functions) bypasses RLS
- Edge functions must manually verify permissions
- All edge functions check `auth.uid()` before database access

### ⚠️ Materialized Views

- Materialized views may not respect RLS automatically
- Views are refreshed periodically, not real-time
- Consider using regular views or functions instead

## Recommendations

1. **Regular Audits**: Review RLS policies quarterly
2. **Test Coverage**: Add automated RLS tests
3. **Documentation**: Keep this doc updated with policy changes
4. **Monitoring**: Monitor for unauthorized access attempts

## Migration Safety

When adding new tables:
1. ✅ Enable RLS: `ALTER TABLE ... ENABLE ROW LEVEL SECURITY;`
2. ✅ Add SELECT policy (family members can view)
3. ✅ Add INSERT policy (members/admins can create)
4. ✅ Add UPDATE policy (members/admins can update)
5. ✅ Add DELETE policy (admins can delete, if applicable)
6. ✅ Test policies with multiple users/families

## References

- [Supabase RLS Documentation](https://supabase.com/docs/guides/auth/row-level-security)
- [PostgreSQL RLS Guide](https://www.postgresql.org/docs/current/ddl-rowsecurity.html)


