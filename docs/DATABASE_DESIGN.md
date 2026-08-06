# Database Design — `lgh_system_v2`

**Status:** current as of `db-migrations` V48 (`V48__user_communication_preferences_schema.sql`), plus V51
(`V51__articles_schema.sql`, blog domain), 2026-07-29. **V49/V50/V52** (vendor & destination master-data
tables, and the V52 booking-companies consolidation) are not yet reflected in this document.

## Source of truth

The actual schema lives entirely in this repo as Flyway migrations
(`src/main/resources/db/migration/V1...V48`). Both `lghj-v2-admin-api` and `lghj-v2-public-api` consume
this repo as a pinned Maven dependency — neither app owns its own copy of the schema. **This document is
a derived, human-readable summary; the migrations are always the authority.** When they diverge, trust
the migrations and update this file.

A companion ER diagram source lives at [`docs/lghjV2.dbml`](./lghjV2.dbml) (importable at
[dbdiagram.io](https://dbdiagram.io)) — it was regenerated alongside this document to match the current
schema; previously (as `lghj-v2-admin-api/docs/lghjV2.dbml`, before both docs were relocated here) it
only reflected the original V6 case-management baseline and was missing every domain added since
(vehicle catalog, inventory, auto parts, orders/Stripe, notifications, etc.).

This document and the diagram used to live in `lghj-v2-admin-api/docs/`; they were moved here so the
schema documentation sits next to the migrations it describes, rather than in one of the two consuming
apps.

## How to keep this updated

Whenever a migration is added to this repo:
1. Update the relevant domain table below (new table / altered columns / new FK).
2. Update `docs/lghjV2.dbml` if the change affects the ER diagram.
3. If the migration renames/removes something documented in "Schema evolution & gotchas" below, note the follow-up or remove the stale gotcha.
4. Bump the "Status" line at the top of this file to the new highest `V<n>`.

---

## Domain map

| Domain | Tables |
|---|---|
| Auth & RBAC | `roles`, `permissions`, `user_roles`, `role_permissions` |
| Users & profile | `users`, `users_meta`, `user_status_history`, `otp_tokens` |
| Account recovery & session security | `email_verification_tokens`, `password_reset_tokens`, `recovery_codes`, `recovery_questions`, `user_recovery_answers`, `session_termination_logs` |
| Consent & preferences | `user_consents`, `user_communication_preferences`, `user_favourite_items` |
| Audit logging | `audit_logs` |
| Public marketing forms | `contact_messages`, `newsletter_subscribers` |
| Orders (generic) | `orders`, `order_items`, `order_statuses`, `order_item_statuses`, `order_documents` |
| Stripe / payments / subscriptions | `payments`, `payment_events`, `refunds`, `subscriptions`, `subscription_items`, `subscription_events` |
| Case management (auction bidding workflow) | `cases`, `case_bid_groups`, `case_vehicles`, `case_bid_group_vehicles`, `case_vehicle_metadata`, `case_documents`, `case_advance_payments`, `case_bid_group_remarks`, `case_shipments`, `case_shipment_vehicles`, `case_status_history`, `case_messages`, `case_activities`, `case_staff_assignments`, `case_feedback` |
| Manual inventory (vehicle stock) | `inventory_vehicles`, `inventory_vehicle_metadata`, `inventory_images`, `inventory_videos`, `inventory_documents`, `inventory_vehicle_features`, `inventory_vehicle_tags` |
| Vehicle catalog / taxonomy (avto.jp-synced reference data) | `vehicle_brands`, `vehicle_models`, `vehicle_grades`, `vehicle_drives`, `vehicle_colors`, `vehicle_transmissions`, `vehicle_fuel_types`, `vehicle_body_styles`, `vehicle_features`, `vehicle_tags` |
| Auto parts | `auto_parts`, `auto_part_images`, `auto_part_prices`, `auto_part_tags`, `auto_parts_inquiries`, `auto_parts_meta` |
| Public stock site support | `stock_vehicle_views`, `stock_price_inquiries` |
| Notifications | `notifications` |
| Blog | `blog_articles`, `blog_tags`, `blog_article_tags` |

Cross-domain link: a won bid in **Case management** can be "promoted" into **Manual inventory**
(`inventory_vehicles.case_vehicle_id` / `.source_case_id`, loosely coupled — see gotcha #12 below).
Both **Case management** (`case_vehicles.vehicle_id`) and **User favourites**
(`user_favourite_items.vehicle_id`) reference vehicles in an *external* AVTO auction catalog that this
database does not own, so those columns are intentionally not FK'd.

---

## 1. Auth & RBAC

| Table | Purpose | Key columns / constraints | FKs |
|---|---|---|---|
| `roles` | Role definitions | `id` CHAR(36) PK; `name` UNIQUE; `is_locked` BOOLEAN (V13) | — |
| `permissions` | Permission definitions | `id` PK; `name` UNIQUE | — |
| `user_roles` | User↔Role join | PK(`user_id`,`role_id`) | `user_id`→users.id; `role_id`→roles.id |
| `role_permissions` | Role↔Permission join | PK(`role_id`,`permission_id`) | `role_id`→roles.id; `permission_id`→permissions.id |

**Roles** (seeded once in V1, unchanged since): `ADMIN`, `BIDDING`, `SALES`, `FINANCE`, `SHIPPING`,
`CUSTOMER`, `SUPPORT`.

### Permission growth by migration

| Migration | Permissions added | Grants |
|---|---|---|
| V1 | `USER_READ/WRITE/DELETE`, `ROLE_READ/WRITE/DELETE` | none yet |
| V13 | — | Backfills **all** existing permissions to `ADMIN`, but only if `role_permissions` is empty (defensive, won't clobber a curated deployment) |
| V20 | `CASE_SUBMIT`, `CASE_REVIEW`, `CASE_DEPOSIT_VERIFY`, `CASE_BID_MANAGE`, `CASE_PRICING_PUBLISH`, `CASE_LC_VERIFY`, `CASE_BALANCE_VERIFY`, `CASE_SHIPPING_MANAGE`, `CASE_CANCEL` | ADMIN all; BIDDING→(SUBMIT,REVIEW,BID_MANAGE); SALES→(SUBMIT,PRICING_PUBLISH); FINANCE→(DEPOSIT_VERIFY,LC_VERIFY,BALANCE_VERIFY); SHIPPING→(SHIPPING_MANAGE) |
| V21 | `CASE_APPROVE`, `CASE_SET_DEPOSIT`, `CASE_DEPOSIT_SUBMIT` | ADMIN all; BIDDING→(APPROVE,SET_DEPOSIT); SALES→(DEPOSIT_SUBMIT) |
| V26 | `CASE_BID_CREATE`, `CASE_BID_OUTCOME` (split from `CASE_BID_MANAGE`) | ADMIN all; BIDDING→both |
| V27 | `CATALOG_READ/WRITE/DELETE/SYNC` | ADMIN only |
| V28 | `CASE_READ` | ADMIN, BIDDING, SALES |
| V29 | `INVENTORY_READ/WRITE/DELETE` | ADMIN all; BIDDING/SALES→READ |
| V30 | `SUBSCRIPTION_READ` | ADMIN, SALES |
| V31 | — | Extends `CASE_READ` to FINANCE and SHIPPING (all 5 staff roles can now view cases) |
| V40 | `AUTO_PARTS_READ/WRITE/DELETE`, `AUTO_PARTS_INQUIRY_READ/WRITE` | ADMIN all; BIDDING/SALES→READ; SALES also gets both INQUIRY perms |
| V44 | `STOCK_INQUIRY_READ/WRITE` | ADMIN, SALES |

Conventions: permission names are `<DOMAIN>_<ACTION>`; every migration that adds a permission
re-grants the full permission set to `ADMIN` via `INSERT IGNORE ... CROSS JOIN permissions`, so ADMIN
is always a superset. V20's comment notes these permissions already existed in application enum code
(`PermissionName`, enforced by `CaseStateValidator`) but had never been seeded in non-dev environments —
several of these migrations exist purely to backfill schema/application drift, not to add new features.

---

## 2. Users, profile, recovery & preferences

| Table | Purpose | Key columns / constraints | FKs |
|---|---|---|---|
| `users` | Core account record | `id` PK; `username`/`email` UNIQUE; `status` CHECK IN (`UNVERIFIED`,`PENDING`,`ACTIVE`,`SUSPENDED`,`LOCKED`,`CLOSED`); `stripe_customer_id` UNIQUE; `payment_method_configured` BIT | — |
| `users_meta` | EAV profile attributes (first/last name, avatar, ...) | UNIQUE(`user_id`,`meta_key`) | `user_id`→users.id |
| `user_status_history` | Status-transition audit trail | CHECK on previous/new status | `user_id`→users.id |
| `otp_tokens` | Email OTP codes | idx(email, used, expires_at) | none (email-keyed) |
| `email_verification_tokens` | Email verification tokens | `token` UNIQUE | `user_id`→users.id (CASCADE) |
| `password_reset_tokens` | Password reset tokens | `token` UNIQUE | `user_id`→users.id (CASCADE) |
| `recovery_codes` | One-time account recovery codes | — | `user_id`→users.id (CASCADE) |
| `recovery_questions` | Security question catalog | `question` UNIQUE, 8 seeded rows | — |
| `user_recovery_answers` | Hashed answers per user | UNIQUE(`user_id`,`question_id`) | `user_id`→users.id (CASCADE); `question_id`→recovery_questions.id (RESTRICT) |
| `session_termination_logs` | Forced logout/session-kill log | — | `user_id`→users.id (CASCADE) |
| `user_consents` | Terms/privacy/marketing consent | UNIQUE(`user_id`) | `user_id`→users.id (CASCADE) |
| `user_communication_preferences` | Per-user contact-channel opt-ins | UNIQUE(`user_id`) | `user_id`→users.id (CASCADE) |
| `user_favourite_items` | Saved auction vehicles (groups A–E) | `group_name` ENUM(A..E); `vehicle_type` ENUM(CAR,BIKE); UNIQUE(`user_id`,`vehicle_id`,`status`) | `user_id`→users.id (CASCADE); `vehicle_id` is an external AVTO id, not FK'd |

---

## 3. Audit logging & public forms

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `audit_logs` | Security/system event log (login attempts, etc.) | idx(email), idx(event_type), idx(ip_address, created_at) | none (email-keyed) |
| `contact_messages` | Public "contact us" submissions | — | none |
| `newsletter_subscribers` | Footer newsletter signups | `email` UNIQUE | none |

---

## 4. Orders (generic)

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `orders` | Order header | `status` INT; `deleted_at` (soft delete) | `user_id`→users.id |
| `order_items` | Order line items | `status`/`type` INT; `qty` | `order_id`→orders.id |
| `order_statuses` | Order status history | — | `order_id`→orders.id; `user_id`→users.id |
| `order_item_statuses` | Order item status history | — | `order_item_id`→order_items.id; `user_id`→users.id |
| `order_documents` | Documents attached to an order | `type`/`status` INT | `order_id`→orders.id |

## 5. Stripe / payments / subscriptions

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `payments` | Stripe PaymentIntent record | `stripe_payment_intent_id` UNIQUE; `idempotency_key` | `order_id`, `user_id` — **indexed only, no FK constraint** |
| `payment_events` | Raw Stripe webhook events | `stripe_event_id` UNIQUE | `payment_id` — indexed only, no FK constraint |
| `refunds` | Refunds against a payment | — | `payment_id` — indexed only, no FK constraint |
| `subscriptions` | Stripe subscription per user | `stripe_id` UNIQUE; idx(user_id, stripe_status) | `user_id` — indexed only, no FK constraint |
| `subscription_items` | Subscription line items | `stripe_id` UNIQUE; UNIQUE(`subscription_id`,`stripe_price`) | `subscription_id`, `membership_package_id` — indexed only, no FK constraint |
| `subscription_events` | Raw Stripe webhook events for subscriptions | `stripe_event_id` UNIQUE | `subscription_id` nullable, no FK constraint |

> ⚠️ Unlike almost every other domain, this one omits real `FOREIGN KEY` constraints on its relational
> columns (see gotcha #11). Treat `order_id`/`payment_id`/`user_id`/`subscription_id` as soft references.

---

## 6. Case management (auction bidding workflow) — largest domain

All originated in **V6**, a single migration whose internal comments still say "Merged from V4+V5+V6+V7
— clean baseline"; don't assume those in-file references map to actual separate files in this repo.

| Table | Purpose | Key columns / enums | FKs |
|---|---|---|---|
| `cases` | Top-level customer case (1 case → 1+ bid groups → 1+ vehicles) | `status` VARCHAR(50) default `DRAFT`; totals (`total_cif_amount`, `total_deposit_required`, `total_lc_amount`, `total_balance_amount`, `total_paid_amount`); `is_manual` BIT (V16) | `customer_id`→users.id (CASCADE); `created_by_user_id`/`customer_assigned_by_admin_id`→users.id (SET NULL) |
| `case_bid_groups` | Group of vehicles bid together | UNIQUE(`case_id`,`bid_group_id`); `num_vehicles_included`, `max_bid_value`, `num_vehicles_required` (V15) | `case_id`→cases.id (CASCADE); `bid_group_id` is external, not FK'd |
| `case_vehicles` | Per-vehicle bidding/pricing/deposit/LC/balance tracking | `vehicle_status` ENUM(`PENDING`,`IN_BIDDING`,`BID_WIN`,`BID_LOSS`,`IGNORED`,`IN_INVENTORY`†); `cif_breakdown_json`/`metadata_json` JSON | `case_id`→cases.id (CASCADE) |
| `case_bid_group_vehicles` | Vehicle↔bid-group join | Composite PK(`case_bid_group_id`,`case_vehicle_id`) — see gotcha #3 | `case_bid_group_id`→case_bid_groups.id (CASCADE); `case_vehicle_id`→case_vehicles.id (CASCADE) |
| `case_vehicle_metadata` | EAV metadata per case vehicle (now also holds `auction_date`/`auction_time`, see gotcha #8) | idx(meta_key) | `case_vehicle_id`→case_vehicles.id (CASCADE) |
| `case_documents` | Case/vehicle document uploads + verification | `verification_status` ENUM(`PENDING`,`APPROVED`,`REJECTED`) | `case_id`→cases.id (CASCADE); `case_vehicle_id`→case_vehicles.id (CASCADE, nullable); `uploaded_by_user_id`/`verified_by_user_id`→users.id (SET NULL) |
| `case_advance_payments` | Deposit requirement + proof + finance verification | `verification_status` ENUM(`PENDING`,`VERIFIED`,`REJECTED`) | `case_id`→cases.id (CASCADE); `required_by_admin_id`/`verified_by_finance_id`→users.id (SET NULL); `payment_proof_document_id`→case_documents.id (SET NULL) |
| `case_bid_group_remarks` | One remarks note per bid group | UNIQUE(`case_bid_group_id`) | `case_bid_group_id`→case_bid_groups.id (CASCADE) |
| `case_shipments` | Shipment grouping of vehicles | `shipment_status` ENUM(`PENDING`,`IN_YARD`,`INSPECTING`,`BOOKED`,`IN_TRANSIT`,`DELIVERED`) | `case_id`→cases.id (CASCADE) |
| `case_shipment_vehicles` | Vehicle→shipment mapping + inspection | `inspection_result` ENUM(`PENDING`,`PASS`,`FAIL`); UNIQUE(`case_vehicle_id`,`shipment_id`) | `shipment_id`→case_shipments.id (CASCADE); `case_vehicle_id`→case_vehicles.id (CASCADE) |
| `case_status_history` | Case status-transition audit trail | microsecond `created_at` for stable ordering — **values may not match the current valid enum for old rows, see gotcha #4** | `case_id`→cases.id (CASCADE); `changed_by_user_id`/`acte_by_user_id`→users.id (SET NULL) |
| `case_messages` | Threaded case/vehicle messages | `message_type` ENUM(`USER_MESSAGE`,`SYSTEM_NOTE`,`STATUS_CHANGE`); `visibility` ENUM(`CUSTOMER_AND_STAFF`,`STAFF_ONLY`) | `case_id`→cases.id (CASCADE); `case_vehicle_id`→case_vehicles.id (CASCADE, nullable); `sender_user_id`→users.id (SET NULL) |
| `case_activities` | Generic activity/audit trail | `metadata_json` JSON; microsecond `created_at` | `case_id`→cases.id (CASCADE); `case_vehicle_id`→case_vehicles.id (CASCADE, nullable); `actor_user_id`→users.id (SET NULL) |
| `case_staff_assignments` | Staff role assignment per case | — | `case_id`→cases.id (CASCADE); `assigned_to_user_id`/`assigned_by_user_id`→users.id (SET NULL) |
| `case_feedback` | One customer feedback/rating per vehicle | `case_vehicle_id` UNIQUE | `case_vehicle_id`→case_vehicles.id (CASCADE); `submitted_by_user_id`→users.id (SET NULL) |

† `IN_INVENTORY` added in V25 to support promoting a bid-won vehicle into Manual Inventory.

### Case status state machine (post-V21 redesign)

`DRAFT` → `WAITING_FOR_APPROVAL` (was `SUBMITTED`) → `APPROVED` (new) → `AWAITING_DEPOSIT_VERIFICATION`
(was `DEPOSIT_SUBMITTED`) → `IN_BIDDING` (verification now transitions straight here; the old
`DEPOSIT_VERIFIED` state was dropped) → ... See gotcha #4 for the historical-data caveat.

---

## 7. Manual inventory (vehicle stock)

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `inventory_vehicles` | Vehicle stock record (from won bids or manual entry) | `id` DEFAULT(UUID()); `stock_id` NOT NULL + UNIQUE (V47, see gotcha #9); `status` default `ACTIVE`; `case_vehicle_id`/`source_case_id` | `case_vehicle_id`/`source_case_id` — indexed only, no FK (see gotcha #12) |
| `inventory_vehicle_metadata` | EAV metadata per inventory vehicle | idx(meta_key) | `vehicle_id`→inventory_vehicles.id (CASCADE) |
| `inventory_images` | Stock images | `is_primary`, `sort_order` | `vehicle_id`→inventory_vehicles.id (CASCADE) |
| `inventory_videos` | Stock videos | — | `vehicle_id`→inventory_vehicles.id (CASCADE) |
| `inventory_documents` | Stock documents | — | `vehicle_id`→inventory_vehicles.id (CASCADE) |
| `inventory_vehicle_features` | Vehicle↔feature join | PK(`vehicle_id`,`feature_id`) | `vehicle_id`→inventory_vehicles.id (CASCADE); `feature_id`→vehicle_features.id (CASCADE, since V33) |
| `inventory_vehicle_tags` | Vehicle↔tag join | PK(`vehicle_id`,`tag_id`) | `vehicle_id`→inventory_vehicles.id (CASCADE); `tag_id`→vehicle_tags.id (CASCADE, since V33) |

---

## 8. Vehicle catalog / taxonomy (avto.jp-synced reference data)

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `vehicle_brands` | Brand catalog | `slug` UNIQUE; soft-delete; `code` UNIQUE (V38, raw vendor `MARKA_NAME`) | — |
| `vehicle_models` | Model catalog | `slug` UNIQUE; `code` UNIQUE scoped to `(vehicle_brand_id, code)` | `vehicle_brand_id`→vehicle_brands.id (CASCADE) |
| `vehicle_grades` | Grade/trim catalog | `slug` UNIQUE; `code` UNIQUE scoped to `(vehicle_model_id, code)` | `vehicle_model_id`→vehicle_models.id (CASCADE) |
| `vehicle_drives` | Drivetrain catalog | `slug` UNIQUE; `code` UNIQUE (raw vendor `PRIV`) | — |
| `vehicle_colors` | Color catalog | `slug` UNIQUE; `code` UNIQUE | — |
| `vehicle_transmissions` | Transmission catalog | `slug` UNIQUE; `code` UNIQUE (raw vendor `KPP`); `style` (CVT/AM/MT/AT) | — |
| `vehicle_fuel_types` | Fuel type catalog | `slug` UNIQUE, 9 seeded rows | — |
| `vehicle_body_styles` | Body style catalog | `slug` UNIQUE, ~17 seeded rows | — |
| `vehicle_features` | Canonical feature catalog, ~130 seeded rows | `slug` UNIQUE | — |
| `vehicle_tags` | Canonical tag catalog, 9 seeded rows | `slug` UNIQUE | — |

`vehicle_features`/`vehicle_tags` replace legacy CHAR(36)-keyed `features`/`tags` tables (created V24,
data-migrated in and dropped in V33 — see gotcha #6). `lghj-v2-admin-api` also runs a Redis cache-aside
layer on top of this whole catalog domain (brands, models, grades, colors, drives, transmissions) — see
that repo's `AuctionCacheService`-style caching for brands/models/grades/colors/drives/transmissions.

---

## 9. Auto parts

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `auto_parts` | Auto parts catalog item | `slug` UNIQUE; `stock_id` NOT NULL + UNIQUE (V47); `stock_type` default `'Real Stock'`; `status` default `ACTIVE` | `vehicle_brand_id`→vehicle_brands.id (SET NULL); `vehicle_model_id`→vehicle_models.id (SET NULL) |
| `auto_part_images` | Part images | `is_primary`, `sort_order` | `auto_part_id`→auto_parts.id (CASCADE) |
| `auto_part_prices` | Price/qty (1:1) | UNIQUE(`auto_part_id`) | `auto_part_id`→auto_parts.id (CASCADE) |
| `auto_part_tags` | Part↔tag join | PK(`auto_part_id`,`tag_id`) | `auto_part_id`→auto_parts.id (CASCADE); `tag_id`→vehicle_tags.id (CASCADE) |
| `auto_parts_inquiries` | Public "inquire about this part" submissions | `status` default `NEW` | none |
| `auto_parts_meta` | EAV metadata (color, weight, dimensions, ...) | idx(meta_key) | `auto_part_id`→auto_parts.id (CASCADE) |

---

## 10. Public stock site support & notifications

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `stock_vehicle_views` | Page-view counter per public stock vehicle — **a table, not a DB view, despite the migration filename** `V41__create_stock_vehicle_views.sql` (no `CREATE VIEW` exists anywhere in the migration set) | `vehicle_id` PK; `view_count`; owned/written by `public-api` only | none |
| `stock_price_inquiries` | Public "get a price quote" requests | `status` default `NEW` | `user_id`→users.id (SET NULL, nullable) |
| `notifications` | In-app notifications (e.g. staff alerts on case status changes) | `type`, `reference_type`/`reference_id`; `read_at` nullable | `user_id`→users.id (CASCADE) |

---

## 11. Blog

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `blog_articles` | Blog post/article managed via the Admin Portal, consumed by the public site once published | `slug` UNIQUE; `status` default `0` (0=draft, 1=published); soft-deleted via `deleted_at` | none |
| `blog_tags` | Blog tag catalog (independent of `vehicle_tags` — this is content taxonomy, not vehicle taxonomy) | `slug` UNIQUE; `status` default `0` (0=draft, 1=active); soft-deleted via `deleted_at` | none |
| `blog_article_tags` | Article↔tag join | UNIQUE(`article_id`,`art_tag_id`) | `article_id`→blog_articles.id (CASCADE); `art_tag_id`→blog_tags.id (CASCADE) |

Permissions: `ARTICLE_READ`/`ARTICLE_WRITE`/`ARTICLE_DELETE` (V51), granted in full to `ADMIN`.

---

## 12. Free brand of the week (home hero auction vehicles)

| Table | Purpose | Key columns | FKs |
|---|---|---|---|
| `free_brands` | Admin-set "which brand is free this week"; the row with the highest `id` (excluding soft-deleted) is the active one | soft-deleted via `deleted_at` | `vehicle_brand_id`→vehicle_brands.id (CASCADE) |
| `free_auction_vehicles` | Cache of vehicles fetched from the external avto.jp API for the active free brand; fully truncated and re-fetched by a `public-api` scheduled job every 30 min | `vehicle_id`, `thumbnail_url`, `brand`, `model`, `auction_date` (all denormalized snapshot fields, not FKs into vehicle catalog) | `free_brand_id`→free_brands.id (CASCADE) |

Owned by `lghj-v2-admin-api` (CRUD on `free_brands` — creating a new row is what "rotates" the free brand) and
`lghj-v2-public-api` (read-only `free_brands` access + all `free_auction_vehicles` writes via the refresh job,
plus the public `GET /auctions/cars/free-brand` read endpoint).

Permissions: `FREE_BRAND_READ`/`FREE_BRAND_WRITE`/`FREE_BRAND_DELETE` (V55), granted in full to `ADMIN`.

---

## Schema evolution & gotchas

Numbered for reference; check this list before writing code that assumes "obvious" behavior.

1. **V6 is a squashed baseline.** Column comments inside it reference "(V5)"/"(V6)"/"(V7)" waves that no longer exist as separate files — the whole case-management domain shipped as one migration.
2. **V10 adds `UNVERIFIED`** to both `users.status` and `user_status_history` CHECK constraints, to distinguish unverified-email accounts from `PENDING`.
3. **V14 fixed an ORM/schema mismatch**: `case_bid_group_vehicles` originally had a standalone UUID `id` PK that Hibernate's `@ManyToMany` join-table mapping never populated, breaking manual-case creation. Fixed by switching to a composite PK on the two FK columns.
4. **V21 renamed/restructured the case status machine** (see state machine above) as a **data-only** migration (`cases.status` is just VARCHAR). Old `case_status_history` rows keep their original, now-obsolete status strings — don't assume historical `from_status`/`to_status` values are valid against the current enum.
5. **V25 added `IN_INVENTORY`** to `case_vehicles.vehicle_status` to support promoting a bid-won vehicle into Manual Inventory.
6. **V33 consolidated feature/tag systems**: legacy CHAR(36)-keyed `features`/`tags` (V24) were merged into the richer BIGINT-keyed `vehicle_features`/`vehicle_tags` catalog, repointing `inventory_vehicle_features.feature_id`/`inventory_vehicle_tags.tag_id`, then dropping the old tables. Because those join columns are `ON DELETE CASCADE`, **V36/V37 reseeding `vehicle_features`/`vehicle_tags` via `DELETE FROM ...` silently cascade-deleted all existing inventory feature/tag associations** — a real data-loss gotcha if you ever reseed those catalogs again; prefer upsert over delete-and-reseed.
7. **V38 adds vendor `code` columns** to `vehicle_brands`/`vehicle_models`/`vehicle_grades`/`vehicle_drives` for avto.jp resync dedup. Uniqueness scope differs: brands/drives are flat (globally unique `code`); models/grades are scoped to their parent since the same raw vendor code can repeat across different parents.
8. **V46 migrated `case_vehicles.bid_date`** (free-text VARCHAR) into `case_vehicle_metadata` as `auction_date`/`auction_time` EAV keys, matching the shape already used by the public bid flow, then dropped the column. Only backfilled rows missing that metadata key, so richer pre-existing metadata wasn't overwritten.
9. **V47 requires pre-migration backfill.** It adds `NOT NULL` + `UNIQUE` on `inventory_vehicles.stock_id` and `auto_parts.stock_id` — **not safe to run blind** against a DB with NULL/blank/duplicate `stock_id` values; the migration comment points to an external `admin-api` script (`scripts/backfill-stock-ids.sh`) that must run first.
10. **V12/V13 seed non-production accounts** (`admin@`, `bidding@`, `sales@`, `finance@`, `shipping@`, `customer@`, `support@` at `@miraisei.com`, fixed bcrypt passwords). These are dev/QA seed data baked into the migration history, not real users — be aware they exist in every environment that runs the full migration chain.
11. **Stripe/Orders domain has inconsistent FK discipline.** `payments`, `payment_events`, `refunds`, `subscriptions`, `subscription_items` only index their relational columns (`order_id`, `payment_id`, `user_id`, `subscription_id`) rather than declaring real FK constraints, unlike almost every other domain. Treat these as soft references — don't rely on the DB to enforce referential integrity here.
12. **Case Management ↔ Manual Inventory is intentionally loosely coupled.** `inventory_vehicles.case_vehicle_id`/`.source_case_id` have no FK constraint, so promoting/archiving a case never hard-blocks on inventory records (and vice versa).
13. **Two external vehicle-ID patterns, neither FK'd internally**: `user_favourite_items.vehicle_id` (VARCHAR) and `case_vehicles.vehicle_id` (CHAR(36)) both point at vehicles in an external AVTO auction catalog this database doesn't own.
14. **V51's `blog_tags` is a deliberately separate tag catalog from `vehicle_tags`**, not a reuse of it (unlike `auto_part_tags`/`inventory_vehicle_tags`, which both point at `vehicle_tags`). Blog content tags and vehicle/parts tags are different taxonomies that happen to share a shape — don't conflate `art_tag_id` with `tag_id` elsewhere in the schema.
15. **V51's tables were renamed in place** (`articles`→`blog_articles`, `art_tags`→`blog_tags`, `article_art_tags`→`blog_article_tags`), editing the V51 file directly rather than shipping a follow-up rename migration — even though `1.5.0` was already published to GitHub Packages with the old names. Judged safe only because no application code had shipped against the old names yet; required a manual local-DB reset (drop + re-migrate) since Flyway checksums/history for any DB that had already applied the old V51 would otherwise no longer match. Prefer "fix forward" (a new migration) over editing a published migration once real data/consumers exist — this was a narrow, deliberate exception.

Related: as of this writing, local dev environments for `admin-api`/`public-api` can't run `flyway migrate`
past V47 until pre-existing `inventory_vehicles.stock_id` duplicates in the local dev DB are cleaned up
(see gotcha #9) — this is a local-data problem, not a bug in the migration itself.
