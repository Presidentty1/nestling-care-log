# Database Security Documentation

## Overview

This document describes the security architecture, Row Level Security (RLS) policies, and security best practices for the Nuzzle database.

## Security Architecture

### Authentication

**Supabase Auth:**
- Email/password authentication
- JWT tokens for API access
- Session management via HTTP-only cookies
- Password hashing (bcrypt)

**User Identification:**
- `auth.uid()` - Current authenticated user ID
- Available in RLS policies and functions
- Null for unauthenticated requests

### Authorization

**Row Level Security (RLS):**
- Database-level access control
- Policies evaluated on every query
- No application-level bypass possible

**Role-Based Access:**
- `admin` - Full family management
- `member` - Can create/edit events
- `viewer` - Read-only access

## RLS Policy Architecture

### Policy Structure

**Standard Policy Pattern:**
```sql
CREATE POLICY "policy_name" ON table_name
  FOR operation  -- SELECT, INSERT, UPDATE, DELETE, ALL
  USING (condition)  -- For SELECT, UPDATE, DELETE
  WITH CHECK (condition)  -- For INSERT, UPDATE
```

**Helper Functions:**
```sql
-- Check family membership
CREATE FUNCTION is_family_member(_user_id UUID, _family_id UUID)
RETURNS BOOLEAN;

-- Check baby access
CREATE FUNCTION can_access_baby(_user_id UUID, _baby_id UUID)
RETURNS BOOLEAN;
```

### Core Tables Policies

#### Profiles

**Policy: Users can only access their own profile**
```sql
CREATE POLICY "Users can view their own profile" ON public.profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.profiles
  FOR INSERT WITH CHECK (auth.uid() = id);
```

#### Families

**Policy: Users can see families they belong to**
```sql
CREATE POLICY "Users can view families they belong to" ON public.families
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
    )
  );
```

**Policy: Admins can update families**
```sql
CREATE POLICY "Admins can update their families" ON public.families
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = families.id
      AND family_members.user_id = auth.uid()
      AND family_members.role = 'admin'
    )
  );
```

#### Babies

**Policy: Users can access babies in their families**
```sql
CREATE POLICY "Users can view babies in their families" ON public.babies
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = babies.family_id
      AND family_members.user_id = auth.uid()
    )
  );
```

**Policy: Members can create/update babies**
```sql
CREATE POLICY "Members can create babies in their families" ON public.babies
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = babies.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );
```

#### Events

**Policy: Users can view events for babies in their families**
```sql
CREATE POLICY "Users can view events for babies in their families" ON public.events
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = events.family_id
      AND family_members.user_id = auth.uid()
    )
  );
```

**Policy: Members can create/update/delete events**
```sql
CREATE POLICY "Members can create events in their families" ON public.events
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.family_members
      WHERE family_members.family_id = events.family_id
      AND family_members.user_id = auth.uid()
      AND family_members.role IN ('admin', 'member')
    )
  );
```

### Additional Tables

**All tables follow similar patterns:**
- SELECT: Family membership check
- INSERT: Family membership + role check
- UPDATE: Family membership + role check
- DELETE: Family membership + role check (admin only for sensitive data)

## Security Functions

### Helper Functions

**is_family_member:**
```sql
CREATE OR REPLACE FUNCTION public.is_family_member(
  _user_id UUID, 
  _family_id UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.family_members
    WHERE family_id = _family_id
      AND user_id = _user_id
  )
$$;
```

**can_access_baby:**
```sql
CREATE OR REPLACE FUNCTION public.can_access_baby(
  _user_id UUID, 
  _baby_id UUID
)
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.babies b
    JOIN public.family_members fm ON b.family_id = fm.family_id
    WHERE b.id = _baby_id
      AND fm.user_id = _user_id
  )
$$;
```

### Security Definer Functions

**Purpose:**
- Bypass RLS for internal checks
- Prevent RLS recursion
- Maintain security while allowing policy evaluation

**Best Practices:**
- Always use `SET search_path = public`
- Mark as `STABLE` for query optimization
- Document function purpose

## Data Isolation

### Family-Level Isolation

**Principle:**
- Users can only access data for families they belong to
- No cross-family data access
- Enforced at database level

**Implementation:**
- All tables include `family_id`
- RLS policies check family membership
- Helper functions verify access

### User-Level Isolation

**User-Specific Data:**
- `profiles` - Own profile only
- `app_settings` - Own settings only
- `user_feedback` - Own feedback only
- `subscriptions` - Own subscription only

## Service Role Access

### Service Role Usage

**When to Use:**
- Edge functions (server-side)
- Background jobs
- Admin operations
- System operations

**Security:**
- Service role bypasses RLS
- Use with extreme caution
- Always validate input
- Log all service role operations

**Example:**
```typescript
// Edge function
const supabaseAdmin = createClient(
  SUPABASE_URL,
  SUPABASE_SERVICE_ROLE_KEY  // Service role key
);

// Can access all data (bypasses RLS)
const { data } = await supabaseAdmin
  .from('events')
  .select('*');
```

## Security Best Practices

### Policy Design

**1. Principle of Least Privilege:**
- Grant minimum necessary access
- Separate SELECT, INSERT, UPDATE, DELETE policies
- Role-based restrictions

**2. Explicit Checks:**
- Always check family membership
- Verify user roles explicitly
- Don't rely on implicit relationships

**3. Performance:**
- Use indexes on foreign keys
- Keep policy conditions simple
- Use helper functions for complex checks

### Application Security

**1. Never Trust Client:**
- Always validate on server
- RLS is final authority
- Don't skip RLS checks

**2. Input Validation:**
- Validate all user input
- Use parameterized queries
- Sanitize data before display

**3. Error Handling:**
- Don't expose sensitive errors
- Log security violations
- Monitor for suspicious activity

## Security Audit

### Policy Verification

**Check All Tables Have RLS:**
```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
AND rowsecurity = false;
```

**List All Policies:**
```sql
SELECT 
  schemaname,
  tablename,
  policyname,
  cmd,
  qual,
  with_check
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;
```

### Testing Security

**Test as Different Users:**
```sql
-- Test as user
SET ROLE authenticated;
SET request.jwt.claim.sub = 'user-id-here';
SELECT * FROM events;  -- Should only see own family's data

-- Reset
RESET ROLE;
```

**Test Service Role:**
```sql
SET ROLE service_role;
SELECT * FROM events;  -- Should see all data
RESET ROLE;
```

## Common Security Issues

### Issue: RLS Recursion

**Problem:**
- Policy checks family_members table
- family_members has RLS
- Infinite recursion

**Solution:**
- Use SECURITY DEFINER functions
- Functions bypass RLS for internal checks

### Issue: Missing Policies

**Problem:**
- Table has RLS enabled
- No policies defined
- All queries blocked

**Solution:**
- Always create policies when enabling RLS
- Test policies thoroughly
- Document policy purpose

### Issue: Performance

**Problem:**
- RLS policies slow queries
- Complex policy conditions

**Solution:**
- Use indexes on foreign keys
- Simplify policy conditions
- Use helper functions

## Compliance

### GDPR Compliance

**Data Access:**
- Users can export their data
- Users can delete their data
- RLS ensures data isolation

**Data Retention:**
- Automatic cleanup policies
- User-initiated deletion
- Audit logs for compliance

### HIPAA Considerations

**Note:** Nuzzle is not HIPAA compliant by default. For HIPAA compliance:
- Use Supabase HIPAA-compliant plan
- Enable additional encryption
- Implement audit logging
- Sign Business Associate Agreement (BAA)

## Related Documentation

- `DATA_MODEL.md` - Database schema
- `DB_OPERATIONS.md` - Database operations
- `supabase/migrations/20250120000000_comprehensive_rls_security.sql` - Complete RLS policies
