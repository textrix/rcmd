# Database Configuration

RCMD supports both SQLite3 and PostgreSQL databases with flexible configuration.

## Default Configuration

- **Development/Electron**: SQLite3 (default)
- **Production Web**: PostgreSQL (optional)

## Directory Structure

```
data/
├── sqlite3/          # SQLite database files
│   └── rcmd.db      # Main SQLite database
└── pgsql/           # PostgreSQL data (if used)
```

## Environment Variables

```bash
# Database Type Selection
DATABASE_TYPE=sqlite    # or 'postgres'

# SQLite Configuration
SQLITE_PATH=/workspace/data/sqlite3/rcmd.db

# PostgreSQL Configuration (when DATABASE_TYPE=postgres)
POSTGRES_URL=postgresql://user:password@host:5432/dbname
```

## Build Configuration

### Web Build
- Supports both SQLite and PostgreSQL
- Database type controlled by `DATABASE_TYPE` environment variable
- Default: SQLite

### Electron Build
- Always uses SQLite (embedded database)
- Database stored in `data/sqlite3/rcmd.db`

## Docker Volumes

The Docker setup maps database directories as volumes:
- `./data/sqlite3` → `/workspace/data/sqlite3`
- `./data/pgsql` → `/workspace/data/pgsql`

This ensures data persistence across container restarts.

## Switching Databases

1. **To use SQLite** (default):
   ```bash
   export DATABASE_TYPE=sqlite
   ```

2. **To use PostgreSQL**:
   ```bash
   export DATABASE_TYPE=postgres
   export POSTGRES_URL=postgresql://...
   ```

## Database Module Usage

```typescript
import { getDatabase } from '$lib/db';
import { databaseConfig, isSQLite } from '$lib/config/database';

// Get database instance
const db = await getDatabase();

// Check database type
if (isSQLite()) {
  console.log('Using SQLite');
} else {
  console.log('Using PostgreSQL');
}

// Execute queries
await db.query('SELECT * FROM users WHERE id = ?', [userId]);
```