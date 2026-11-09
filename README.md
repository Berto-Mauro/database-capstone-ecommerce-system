# ShopGrid: Multi-Tenant E-Commerce Database (Capstone)

PostgreSQL 16 (system of record) + Redis (carts, cache). Built in the five stages of the capstone lab.

| Day | Deliverable | Where |
|---|---|---|
| 1 | Requirements summary, ER diagram | `docs/01_requirements.md`, `docs/02_er_diagram.md` (Mermaid), `docs/02_er_diagram.dbml` (dbdiagram.io) |
| 2 | Versioned migrations V1-V6 | `migrations/`, `flyway.conf`, `scripts/migrate.sh` |
| 3 | NoSQL layer and justification | `docs/03_nosql_design.md`, `nosql/redis_demo.sh`, `nosql/redis_demo_output.txt` |
| 4 | Query optimization with before/after plans | `docs/04_query_optimization.md`, `queries/`, `queries/plans/` |
| 5 | Security checklist, backup and restore | `docs/05_security_and_backup.md`, `security/verify_security.sh`, `scripts/backup.sh` |
| 5 | Walkthrough presentation (8 slides) | `presentation/ShopGrid_Capstone.pptx` |

## Run it

```bash
# 1. Build from an empty database (real Flyway, if installed)
flyway -configFiles=flyway.conf clean migrate
# ...or the bundled Flyway-compatible runner (needs only psql)
./scripts/migrate.sh clean migrate info

# 2. Redis cart + cache demo (needs redis-server on :6379)
./nosql/redis_demo.sh

# 3. Reproduce the optimization evidence
psql -d capstone -c "VACUUM (ANALYZE) orders"
./scripts/explain.sh queries/q1_monthly_revenue.sql

# 4. Security checklist (29 assertions) and backup + verified restore
./security/verify_security.sh
./scripts/backup.sh          # pg_dump -Fc, restores into a scratch DB, compares counts
```

Environment variables: `PGHOST`, `PGPORT`, `PGUSER`, `DB` (defaults: localhost, 5432, postgres, capstone).

## Headline results (measured, not estimated)
* `clean migrate` succeeds from an empty database (6 migrations, about 60 s, mostly the 150k-order seed).
* Q1 19.7 -> 6.7 ms (Seq Scan -> Index Only Scan), Q2 7.9 -> 0.2 ms, Q3 824 -> 1.7 ms.
* Cache hit vs miss: 6 ms vs 104 ms.
* Backup restored with identical row counts and revenue checksum.

## Honest notes
* Flyway itself was not available offline, so migrations were executed with `scripts/migrate.sh`, which follows the same
  naming, ordering and checksum rules. `flyway.conf` is provided for the real tool but was not run.
* `app/shop_queries.py` was syntax-checked only (no `psycopg`/`redis` Python packages offline).
* MongoDB was deliberately not used; see `docs/03_nosql_design.md`.
* Known security limitations are listed in `docs/05_security_and_backup.md`. The demo role passwords are placeholders.
* Timings come from a small sandbox VM; use them as relative evidence.
