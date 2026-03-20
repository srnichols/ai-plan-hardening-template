# Database Migration Skill

## Trigger
"Create a database migration for..." / "Add column..." / "Change schema..."

## Steps

### 1. Generate Migration
```bash
# Using knex
npx knex migrate:make <migration_name>

# Using Prisma
npx prisma migrate dev --name <migration_name>

# Using raw SQL
# Create file: migrations/NNNN_description.sql
```

### 2. Review the SQL
- Verify column types, nullability, defaults
- Check for backward compatibility
- Ensure indexes on frequently queried columns
- Add rollback logic in `down()` function

### 3. Test Locally
```bash
# Knex
npx knex migrate:latest --env development

# Prisma
npx prisma migrate dev

# Raw SQL
psql -h localhost -d contoso_dev -f migrations/NNNN_description.sql
```

### 4. Validate
```bash
npm run test:integration
```

### 5. Deploy to Staging
```bash
npx knex migrate:latest --env staging
```

## Safety Rules
- NEVER drop columns without a deprecation period
- ALWAYS include `down()` migration for rollback
- ALWAYS add `IF NOT EXISTS` / `IF EXISTS` guards in raw SQL
- Test migration on a copy of production data when possible
