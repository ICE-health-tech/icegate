# PostgreSQL Database Testing Guide

This guide explains how to set up and test the PostgreSQL version of your Drift database schema.

## Quick Start

### 1. Install PostgreSQL (if not already installed)

**macOS (using Homebrew):**
```bash
brew install postgresql@15
brew services start postgresql@15
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

### 2. Create a Test Database

```bash
# Access PostgreSQL as the default user
psql postgres

# In the PostgreSQL prompt, create a test database:
CREATE DATABASE ice_shield_test;

# Create a test user (optional but recommended)
CREATE USER test_user WITH PASSWORD 'test_password';
GRANT ALL PRIVILEGES ON DATABASE ice_shield_test TO test_user;

# Exit
\q
```

### 3. Load the Schema

```bash
# Load the schema into your test database
psql -U test_user -d ice_shield_test -f test_database_schema.sql

# Or if using default user:
psql -d ice_shield_test -f test_database_schema.sql
```

## Database Overview

The schema includes the following table groups:

### Widget Tables
- `internal_widgets` - Internal application widgets
- `external_widgets` - External/plugin widgets
- `themes` - UI themes

### Person Management
- `persons` - Basic person information
- `email_addresses` - Email addresses with verification status
- `user_accounts` - User authentication and authorization
- `profiles` - Extended user profile information
- `detail_information` - CV/Resume contact information

### Skills & Development
- `skills` - User skills and proficiency levels

### Finance
- `financial_accounts` - Bank accounts and financial accounts
- `assets` - Personal assets and property

### Goals & Growth
- `goals` - Personal and professional goals
- `habits` - Habit tracking

### Content
- `blog_posts` - Blog posts and articles
- `project_notes` - Project notes and documentation
- `person_widgets` - User-specific widget configurations

## Custom Types (Enums)

The schema uses PostgreSQL ENUMs for:
- `user_role`: user, admin, viewer
- `post_status`: draft, published, archived, deleted
- `email_status`: pending, verified, bounced, disabled
- `currency_type`: USD, EUR, VND, JPY, GBP, CNY
- `skill_level`: beginner, intermediate, advanced, expert

## Sample Data

The schema includes sample data for testing:
- 1 sample person (John Doe)
- Email address and user account
- Profile and CV information
- Sample skill, financial account, and goal

## Useful Commands

### Connect to the Database
```bash
psql -U test_user -d ice_shield_test
```

### View All Tables
```sql
\dt
```

### View Table Structure
```sql
\d table_name
```

### View All Custom Types
```sql
\dT
```

### Query Sample Data
```sql
-- Get all persons with their emails
SELECT p.first_name, p.last_name, e.email_address
FROM persons p
LEFT JOIN email_addresses e ON p.person_id = e.person_id;

-- Get user profile information
SELECT 
    p.first_name || ' ' || p.last_name as full_name,
    pr.occupation,
    pr.location,
    cv.github_url,
    cv.linkedin_url
FROM persons p
LEFT JOIN profiles pr ON p.person_id = pr.person_id
LEFT JOIN detail_information cv ON p.person_id = cv.person_id;

-- Get skills by proficiency level
SELECT skill_name, proficiency_level, years_of_experience
FROM skills
ORDER BY proficiency_level DESC, years_of_experience DESC;
```

### Test Data Insertion
```sql
-- Insert a new person
INSERT INTO persons (first_name, last_name, gender, phone_number)
VALUES ('Jane', 'Smith', 'female', '+9876543210')
RETURNING person_id;

-- Add email for the new person (replace ID)
INSERT INTO email_addresses (person_id, email_address, is_primary, status)
VALUES (2, 'jane.smith@example.com', true, 'pending');
```

### Performance Testing
```sql
-- Check execution plan
EXPLAIN ANALYZE SELECT * FROM persons WHERE person_id = 1;

-- View index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
ORDER BY idx_scan DESC;
```

### Database Maintenance
```sql
-- Vacuum and analyze for performance
VACUUM ANALYZE;

-- Check database size
SELECT pg_size_pretty(pg_database_size('ice_shield_test'));

-- Check table sizes
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;
```

## Testing Scenarios

### 1. Test User Registration Flow
```sql
BEGIN;

-- Create person
INSERT INTO persons (first_name, last_name, gender)
VALUES ('Test', 'User', 'other')
RETURNING person_id; -- Note the returned ID

-- Add email (use the ID from above)
INSERT INTO email_addresses (person_id, email_address, is_primary)
VALUES (3, 'test@example.com', true);

-- Create user account
INSERT INTO user_accounts (person_id, username, password_hash, role)
VALUES (3, 'testuser', 'hashed_password', 'user');

-- Create profile
INSERT INTO profiles (person_id, bio, occupation)
VALUES (3, 'Test user bio', 'Tester');

COMMIT;
```

### 2. Test Foreign Key Constraints
```sql
-- This should fail (person doesn't exist)
INSERT INTO email_addresses (person_id, email_address)
VALUES (999, 'invalid@example.com');

-- This should work (cascade delete)
DELETE FROM persons WHERE person_id = 3;
-- All related records should be deleted automatically
```

### 3. Test Triggers
```sql
-- Create a person
INSERT INTO persons (first_name, last_name)
VALUES ('Trigger', 'Test')
RETURNING person_id, created_at, updated_at;

-- Update and check timestamp
UPDATE persons 
SET first_name = 'Updated' 
WHERE first_name = 'Trigger'
RETURNING person_id, created_at, updated_at;
-- Note: updated_at should be newer than created_at
```

## Cleanup

### Drop Database
```bash
psql postgres -c "DROP DATABASE ice_shield_test;"
```

### Reset Schema (keeps database but drops all tables)
```sql
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;
GRANT ALL ON SCHEMA public TO test_user;
GRANT ALL ON SCHEMA public TO public;
```

## Differences from Drift

Key differences to be aware of:

1. **Auto-increment**: PostgreSQL uses `SERIAL` instead of `autoIncrement()`
2. **Timestamps**: PostgreSQL has native `TIMESTAMP` type vs Drift's `dateTime()`
3. **Enums**: PostgreSQL has native ENUM types
4. **Text constraints**: VARCHAR with explicit lengths vs Drift's `withLength()`
5. **Triggers**: Auto-update timestamps require explicit triggers in PostgreSQL

## Integration Testing

To use this database for integration testing with your Flutter app:

1. Update your database connection settings
2. Use a PostgreSQL driver (e.g., `postgres` package)
3. Adapt DAOs to use SQL queries instead of Drift syntax
4. Run tests against this schema

## Additional Resources

- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- [Drift Documentation](https://drift.simonbinder.eu/)
- [PostgreSQL Best Practices](https://wiki.postgresql.org/wiki/Don't_Do_This)
