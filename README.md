# DivarBasu

### Project Members
- Amir Mohammad Nasiri
- Reyhaneh Sadat Khosravi

## 🎓 University Marketplace Database

A PostgreSQL-backed university marketplace schema designed for real-world features: users, booths, goods, services, orders, subscriptions, discounts, and full audit logging. This project is intended as a production-style backend schema for a course-level database project.

---

## 🧾 Project Overview

This project models a marketplace platform where students and staff can:

- **Create and manage booths** (shops) owned by users.
- **Sell goods and services** with separate inventory and scheduling models.
- **Handle VIP subscriptions**, golden booth plans, and booth badges.
- **Manage carts and orders**, including VIP-only cart locking.
- **Issue flexible discounts** with complex scoping rules.
- **Operate a support/admin panel** with detailed action logs.
- **Track user behavior** and subscription/booth lifecycle events for analytics.

The core deliverable is a **normalized PostgreSQL schema** that focuses on correctness, extensibility, and observability.

---

## 🏗️ System Architecture

At a high level, the system is structured into the following logical modules:

- **Identity & Access**
  - `users`, `roles` (if applicable), `vip_subscriptions`, `support_agents`
- **Marketplace Core**
  - `booths`, `booth_members`, `seller_requests`, `booth_collaboration_requests`
  - `goods`, `services`, `service_schedules` (reservations)
- **Commerce**
  - `carts`, `cart_items`, `cart_locks`
  - `orders`, `order_items`, `payments` (if defined)
- **Monetization & Promotion**
  - `golden_booth_plans`, `booth_subscriptions`, `subscription_plan_history`
  - `badges`, `booth_badges`
  - `discounts`, `discount_scopes`, `discount_usages`
- **Governance & Compliance**
  - `booth_suspensions`
  - `audit_log_user_events`, `audit_log_support_actions`

Each module is isolated via clear foreign key boundaries, with **read-heavy paths** (e.g., searching booths and products) optimized via indexing, and **write-heavy paths** (orders, logs) optimized via append-only tables where appropriate.

---

## 🧱 Entity Design Philosophy

### Separate `goods` and `services` (no product supertable)

Instead of a single polymorphic `products` table with type flags, the schema defines:

- **`goods`**: Tangible, stock-based items (quantity, SKU, physical delivery).
- **`services`**: Intangible offerings with **time-based availability** (duration, capacity per slot, reservation rules).

**Why separate?**

- **Different lifecycle**:
  - Goods are inventory-driven (stock decrement, restocking).
  - Services are schedule-driven (time slots, no traditional “stock”).
- **Different constraints**:
  - Goods may require shipping info, packaging, and weight.
  - Services require calendars, time windows, and overbooking protection.
- **Cleaner constraints & indexes**:
  - Each table can enforce its own NOT NULLs and check constraints (e.g., `duration_minutes > 0` only for services).
- **Simpler queries**:
  - No need for polymorphic joins or nullable fields that only apply to one subtype.

This mirrors real-world design where a unified abstraction would become **too generic and hard to validate**.

---

## 💸 Discount System

The discount system is modeled as a **composable, scope-aware promotion engine**.

### Core Concepts

- **Discount types**
  - **Percent**: e.g., 10% off.
  - **Fixed amount**: e.g., 50,000 IRR off.
- **Usage model**
  - **One-time** per user or per discount (depending on schema).
  - Tracked via a `discount_usages` table referencing `user_id`, `order_id`, and `discount_id`.

### Ownership & Creation

Discounts can be created by:

- **Support**: Platform-wide or targeted campaigns.
- **Booth owners**: Booth-specific promotions.

Ownership is tracked with references such as `created_by_support_id` or `created_by_user_id`, enabling governance and reporting.

### Scoping & “Inheritance” Logic

To avoid rigid table inheritance, the schema uses **scoping tables / columns**:

- **Unrestricted**: No user or booth restrictions.
- **User-restricted**: Only specific users can use it.
- **Booth-restricted**: Only applies to orders from specific booths.
- **User & booth restricted**: Must satisfy both constraints.

Implementation pattern:

- A base `discounts` table:

  - `id`, `code`, `kind` (`PERCENT` / `FIXED`), `value`, `max_uses`, `starts_at`, `ends_at`, etc.

- Optional scoping via:
  - `discount_user_scopes (discount_id, user_id)`
  - `discount_booth_scopes (discount_id, booth_id)`

At runtime, the effective applicability of a discount is determined by checking:

1. **Validity window** and active status.
2. **Usage count** vs. `max_uses` / “one-time” rule.
3. **User and booth scope** tables.

This design provides **inheritance-like specialization** (different behavior per type/scope) without complex SQL inheritance features.

---

## 📊 Logging, Auditing & Analytics

The project includes **first-class observability** to support debugging, compliance, and BI.

### User Behavioral Events

Table(s) like `audit_log_user_events` capture:

- **Who**: `user_id`, `session_id`, user role.
- **What**: event type (e.g., `VIEW_BOOTH`, `ADD_TO_CART`, `CHECKOUT_STARTED`).
- **Where**: booth/product identifiers.
- **When**: timestamp with time zone.
- **Context**: optional JSON payload (e.g., referrer, device, A/B test variant).

These events enable **sales funnel analysis**, such as:

- Drop-off between `VIEW_GOOD` → `ADD_TO_CART` → `CHECKOUT_COMPLETED`.
- Conversion rates per booth, per badge, or per discount campaign.

### Support Action Logging

`audit_log_support_actions` records:

- Admin/support identity.
- Action type (e.g., `SUSPEND_BOOTH`, `GRANT_BADGE`, `CREATE_DISCOUNT`).
- Target entities (user/booth/discount).
- Old/new values when available.

This provides:

- **Accountability**: who changed what, and when.
- **Traceability for disputes**: easily re-construct state changes.

### Subscription & Suspension History

- **`subscription_plan_history`**: Tracks each subscription change (plan, effective date, reason).
- **`booth_suspensions`**: Models suspension intervals with reason codes and notes.

Both tables use **append-only, time-interval-based design**, making it easy to:

- Audit historical states.
- Reconstruct “what the system looked like” at a past timestamp.

---

## 🗄️ Database Design Decisions

### Foreign Keys & `ON DELETE` Choices

- **User-owned data** (e.g., booths, carts) generally uses:
  - `ON DELETE RESTRICT` when deletion would break domain invariants.
  - `ON DELETE CASCADE` for purely dependent details (e.g., `cart_items` when a cart is deleted).
- **Historical / financial records** (e.g., `orders`, audit logs) typically:
  - Use `ON DELETE RESTRICT` to **prevent destructive deletion**, or
  - Keep a soft deletion approach (e.g., `deleted_at`) while preserving references.
- **Lookup tables** (e.g., plans, badges) often use:
  - `ON DELETE RESTRICT` to avoid orphaning references in historical data.

This balance preserves **referential integrity**, prevents accidental loss of financial/audit data, and keeps the schema **self-consistent over time**.

### Audit Log Logic

- Logs are **append-only**: no updates or deletes in normal operation.
- Time-based indexes on timestamps and foreign keys (user/booth/support) optimize analytic queries.
- JSON columns (if used) are constrained to validated shapes where possible (via check constraints or application-level validation).

---

## 🧬 ER Diagram Overview

While the actual ER diagram is not embedded here, the conceptual layout is:

- **Users ↔ Booths**
  - One user owns many booths.
  - Many-to-many collaboration via `booth_members` or `booth_collaborations`.
- **Booths ↔ Goods / Services**
  - Each good/service belongs to exactly one booth.
  - Services have linked `service_schedules` (time slots & reservations).
- **Users ↔ Carts ↔ Orders**
  - One active cart per user (with historical carts allowed).
  - Orders snapshot cart contents into `orders` and `order_items`.
- **Booths ↔ Subscriptions / Badges**
  - Booths can have a current golden plan and associated history in `subscription_plan_history`.
  - Booths get zero or more badges via `booth_badges`.
- **Discounts ↔ Users / Booths**
  - Discounts can be global or scoped using bridge tables.
- **Audit logs**
  - Reference primary actors (user/support) and targets (booth/order/etc.) without circular dependencies.

You can generate a diagram from the schema (e.g., using `pgModeler`, `dbdiagram.io`, or `schemaspy`) to visualize these relationships.

---

## 🚀 Getting Started

### ✅ 1. Prerequisites

- **PostgreSQL** 14+ installed and running.
- A database user with privileges to:
  - Create schemas.
  - Create tables, indexes, and constraints.
- `psql` CLI or a compatible GUI (e.g., DBeaver, pgAdmin).

### 🧩 2. Database Setup

Create a new database for the project:

```bash
createdb university_marketplace
```

(Optional) Connect and verify:

```bash
psql -d university_marketplace -c "SELECT version();"
```

### 📜 3. Applying the Schema

From the project root (where the `schema` folder is located):

```bash
psql -d university_marketplace -f schema/01_create_tables.sql
```

If you maintain separate scripts (e.g., for seed data or views), apply them in order:

```bash
psql -d university_marketplace -f schema/02_seed_data.sql
psql -d university_marketplace -f schema/03_views_and_indexes.sql
```

---

## 🔍 Example Queries

> Note: Adjust table and column names to match the final schema.

### 1. List Active Golden Booths with Badges and Owner

```sql
SELECT
  b.id              AS booth_id,
  b.name            AS booth_name,
  u.id              AS owner_id,
  u.full_name       AS owner_name,
  gb.plan_name,
  array_agg(DISTINCT badge.name) AS badges
FROM booths b
JOIN users u
  ON u.id = b.owner_id
JOIN booth_subscriptions bs
  ON bs.booth_id = b.id
 AND bs.is_active = TRUE
JOIN golden_booth_plans gb
  ON gb.id = bs.plan_id
LEFT JOIN booth_badges bb
  ON bb.booth_id = b.id
LEFT JOIN badges badge
  ON badge.id = bb.badge_id
GROUP BY
  b.id, b.name, u.id, u.full_name, gb.plan_name
ORDER BY
  b.name;
```

### 2. Find Available Service Slots for a Booth

```sql
SELECT
  s.id            AS service_id,
  s.name          AS service_name,
  sch.slot_start,
  sch.slot_end,
  sch.capacity,
  sch.capacity - COALESCE(res.count_reservations, 0) AS remaining_capacity
FROM services s
JOIN service_schedules sch
  ON sch.service_id = s.id
LEFT JOIN (
  SELECT
    schedule_id,
    COUNT(*) AS count_reservations
  FROM service_reservations
  GROUP BY schedule_id
) res
  ON res.schedule_id = sch.id
WHERE
  s.booth_id = :booth_id
  AND sch.slot_start >= NOW()
  AND (sch.capacity - COALESCE(res.count_reservations, 0)) > 0
ORDER BY
  sch.slot_start;
```

### 3. Apply a Discount to a Cart (If Allowed)

```sql
SELECT
  c.id                     AS cart_id,
  d.code                   AS discount_code,
  d.kind,
  d.value,
  cart_totals.subtotal,
  CASE
    WHEN d.kind = 'PERCENT'
      THEN GREATEST(0, cart_totals.subtotal * (1 - d.value / 100.0))
    WHEN d.kind = 'FIXED'
      THEN GREATEST(0, cart_totals.subtotal - d.value)
  END AS total_after_discount
FROM carts c
JOIN (
  SELECT
    ci.cart_id,
    SUM(ci.quantity * ci.unit_price) AS subtotal
  FROM cart_items ci
  GROUP BY ci.cart_id
) cart_totals
  ON cart_totals.cart_id = c.id
JOIN discounts d
  ON d.code = :discount_code
WHERE
  c.user_id = :user_id
  AND c.status = 'ACTIVE'
  AND d.starts_at <= NOW()
  AND d.ends_at   >= NOW()
  AND NOT EXISTS (
    SELECT 1
    FROM discount_usages du
    WHERE du.discount_id = d.id
      AND du.user_id     = c.user_id
  );
```

### 4. Simple Funnel Analysis (View → Add to Cart → Purchase)

```sql
SELECT
  booth_id,
  COUNT(*) FILTER (WHERE event_type = 'VIEW_GOOD')              AS views,
  COUNT(*) FILTER (WHERE event_type = 'ADD_TO_CART')            AS adds_to_cart,
  COUNT(*) FILTER (WHERE event_type = 'CHECKOUT_COMPLETED')     AS purchases
FROM audit_log_user_events
WHERE occurred_at >= NOW() - INTERVAL '30 days'
GROUP BY booth_id
ORDER BY purchases DESC;
```

---

## ⚖️ Design Decisions & Tradeoffs

- **Strong normalization vs. simplicity**: The schema favors normalization and explicit relationships over a minimal table count, making analytics and constraints clearer at the cost of more joins.
- **Append-only logs**: Audit and history tables are append-only, simplifying reasoning about historical data while increasing storage usage (acceptable for a university project and realistic for production).
- **Separate entities for goods/services and discounts/scopes**: Avoids polymorphic anti-patterns and keeps constraints precise, but introduces more tables and slightly more complex queries.
- **Conservative deletes**: Use of `ON DELETE RESTRICT` for financial and historical data protects integrity but requires explicit “cleanup” operations when necessary.
