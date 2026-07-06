# lghj-v2-db-migrations

Single source of truth for the `lgh_system_v2` Flyway migrations shared by
`lghj-v2-admin-api` and `lghj-v2-public-api`. Both apps depend on this as a
Maven artifact instead of keeping their own copy of
`src/main/resources/db/migration` — Flyway's `classpath:db/migration`
scanning picks up migrations from any jar on the classpath, including this
one, so there is exactly one physical copy of every migration file.

## Adding a migration

1. Add the new `V<n>__description.sql` file under
   `src/main/resources/db/migration/`, continuing the existing version
   sequence (see the highest `V<n>` already present).
2. Bump the version in `pom.xml` (e.g. `1.0.0` → `1.1.0`).
3. Open a PR. Once merged to `main`, CI (`.github/workflows/publish.yml`)
   publishes the new version to GitHub Packages automatically.
4. In whichever app(s) need the new migration (`lghj-v2-admin-api` and/or
   `lghj-v2-public-api`), bump the `db-migrations` dependency version in
   that repo's `pom.xml` and deploy.

Consumers pin an **exact** version — never a range or `LATEST` — so picking
up a new migration is always a deliberate, reviewable one-line change in the
consuming repo, not something that happens silently on the next build.

## Why this exists

Previously each app carried its own `db/migration` folder while both wrote
to the same physical database and the same `flyway_schema_history` table.
That meant migration version numbers had to be coordinated by hand across
two repos, and the two copies had already drifted (see `V19` — one repo had
`CREATE TABLE`, the other `CREATE TABLE IF NOT EXISTS`, silently masked by
both apps calling `flyway.repair()` before every `migrate()`, which
overwrites the recorded checksum to match whatever's on the classpath
instead of failing loudly). This module removes the coordination problem by
construction: there is only one migration folder, so there is nothing to
keep in sync.

## Local publishing

Publishing is handled by CI on push to `main`. If you ever need to publish
manually, you'll need a GitHub PAT with `write:packages` (and `read:packages`
to resolve this module's own build, if it had dependencies) configured as
the `github` server in `~/.m2/settings.xml`, then:

```
mvn deploy
```
