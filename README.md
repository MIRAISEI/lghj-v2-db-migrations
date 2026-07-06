# lghj-v2-db-migrations

Single source of truth for the `lgh_system_v2` Flyway migrations shared by
`lghj-v2-admin-api` and `lghj-v2-public-api`. Both apps depend on this as a
Maven artifact instead of keeping their own copy of
`src/main/resources/db/migration` — Flyway's `classpath:db/migration`
scanning picks up migrations from any jar on the classpath, including this
one, so there is exactly one physical copy of every migration file.

## Consuming this package

Any project that needs these migrations adds the GitHub Packages repository
and the dependency to its `pom.xml`:

```xml
<repositories>
  <repository>
    <id>github</id>
    <name>GitHub Packages</name>
    <url>https://maven.pkg.github.com/MIRAISEI/lghj-v2-db-migrations</url>
  </repository>
</repositories>

<dependencies>
  <dependency>
    <groupId>com.lghj.v2</groupId>
    <artifactId>db-migrations</artifactId>
    <version>1.0.0</version> <!-- pin an exact version, see "Versioning" below -->
  </dependency>
</dependencies>
```

GitHub Packages requires authentication to *read* a package, even though
this repo is public. Two ways to provide it, depending on where the build
runs:

- **Local dev machine**: add a `github` server entry to `~/.m2/settings.xml`
  with a PAT that has `read:packages` scope:
  ```xml
  <settings>
    <servers>
      <server>
        <id>github</id>
        <username>YOUR_GITHUB_USERNAME</username>
        <password>YOUR_PAT</password>
      </server>
    </servers>
  </settings>
  ```
- **CI/deploy server**: `lghj-v2-admin-api` and `lghj-v2-public-api` read
  `GITHUB_PACKAGES_USERNAME` / `GITHUB_PACKAGES_TOKEN` from `.env` and their
  `scripts/deploy.sh` generates a scoped `.deploy/maven-settings.xml` from
  those on every deploy — see either repo's `CONFIGURATION.md` § 2 for
  details. Any new consumer should follow the same pattern rather than
  requiring a global `~/.m2/settings.xml` on the server.

Once configured, confirm resolution works:
```
mvn dependency:resolve -Dincludes=com.lghj.v2:db-migrations
```

## Adding / publishing a migration

There's no difference between "first publish" and "re-publish" — every
change to this repo follows the same steps:

1. Add the new `V<n>__description.sql` file under
   `src/main/resources/db/migration/`, continuing the existing version
   sequence (check the highest `V<n>` already present).
2. Bump `<version>` in `pom.xml` (see "Versioning" below). CI refuses to
   silently overwrite an already-published version — GitHub Packages
   rejects re-publishing the same version number — so forgetting this step
   fails loudly in CI rather than corrupting the published artifact.
3. Open a PR. Once merged to `main`, `.github/workflows/publish.yml` runs
   `mvn deploy` automatically — no manual step needed.
4. Verify the publish succeeded:
   - `gh run list --repo MIRAISEI/lghj-v2-db-migrations --limit 1` should
     show `completed success` for the `Publish` workflow.
   - The new version should appear at
     https://github.com/MIRAISEI/lghj-v2-db-migrations/packages
5. In whichever consuming repo(s) need the new migration, bump the
   `db-migrations` `<version>` in that repo's `pom.xml` to match, then
   deploy that repo. This is a separate, deliberate step — see "Versioning"
   below for why.

### Versioning

- Bump the **minor** version for a normal migration addition (`1.0.0` →
  `1.1.0`).
- Bump the **patch** version only for a correction to something not yet
  consumed by any app in production (`1.1.0` → `1.1.1`) — never edit an
  already-published, already-consumed migration file's contents; add a new
  migration to fix forward instead.
- Consumers pin an **exact** version — never a range or `LATEST`. Picking up
  a new migration is always a one-line, reviewable `pom.xml` change in the
  consuming repo, not something that happens silently on that repo's next
  build.

### Publishing manually (fallback only)

CI handles publishing on every push to `main`. If you ever need to publish
from your own machine — e.g. CI is down and it's urgent — you need a GitHub
PAT with `write:packages` scope configured as the `github` server in
`~/.m2/settings.xml` (same server id as consumption, see above), then:

```
mvn deploy
```

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
