# Normalization Proof — Campus Circle

**Course:** CSE2021 Database Management Systems
**Project:** Campus Circle — a verified peer-to-peer campus marketplace
**Author:** Saksham Lodha (240626)
**Team:** Rishit Rebant (240608), Gauri Pandey (240959), Prerit Shrivastava (240593)
**Supervisor:** Dr. Nishtha Phutela

---

## 1. Purpose

This document proves that the Campus Circle relational schema (defined in
`01_schema.sql`) satisfies the first three normal forms: 1NF, 2NF, and 3NF.
The proof follows the standard approach used in Elmasri & Navathe: begin
with an unnormalized relation (UNF), show the anomalies it exhibits, and
apply successive decompositions until each relation satisfies the required
normal form.

---

## 2. Unnormalized relation (UNF)

A naive single-table design capturing every transaction on the platform
would look like this:

```
MarketplaceLog (
    transaction_id,
    buyer_name, buyer_email, buyer_phone, buyer_hostel,
    seller_name, seller_email, seller_phone, seller_hostel,
    item_title, item_category, item_price, rent_per_day, item_type,
    total_amount, status,
    meetup_slot_1, meetup_slot_2, meetup_slot_3,
    review_by_buyer_rating, review_by_buyer_comment,
    review_by_seller_rating, review_by_seller_comment
)
```

### 2.1 Anomalies observed in UNF

| Anomaly type | Example |
|---|---|
| Insertion anomaly | A seller cannot be added until they have at least one transaction (seller_name would otherwise be NULL). |
| Update anomaly | Changing a user's hostel requires touching every row in which they appear, either as buyer or as seller. |
| Deletion anomaly | Deleting the last transaction of a user erases all information about that user. |
| Multi-valued fields | `meetup_slot_1, meetup_slot_2, meetup_slot_3` violates atomicity. |
| Repeating groups | `review_by_buyer_*` and `review_by_seller_*` are parallel repeating attributes. |

---

## 3. First Normal Form (1NF)

**Rule.** A relation is in 1NF iff every attribute holds a single atomic
value and the relation contains no repeating groups.

**Violations removed.**

1. The three `meetup_slot_*` columns are replaced by a separate relation
   `MEETUP_SLOTS(slot_id, transaction_id, proposed_time_slot, selected)`.
   Each slot is now a separate tuple.
2. The parallel `review_by_buyer_*` / `review_by_seller_*` columns are
   replaced by a single relation
   `REVIEWS(review_id, transaction_id, reviewer_id, review_for_user_id,
   rating, comment)`, with one tuple per review.

After this step, every attribute of every relation is a scalar and no
attribute carries a list of values. All seven relations in the final
schema are therefore in 1NF.

---

## 4. Second Normal Form (2NF)

**Rule.** A relation is in 2NF iff it is in 1NF and every non-prime
attribute is fully functionally dependent on the whole of every candidate
key. In practice this means no partial dependency on any part of a
composite key.

**Analysis.**

Every table in the Campus Circle schema uses an auto-increment integer
surrogate key as the primary key:

- `admin.admin_id`
- `users.user_id`
- `categories.category_id`
- `items.item_id`
- `transactions.transaction_id`
- `meetup_slots.slot_id`
- `reviews.review_id`

Because each primary key is a single attribute, partial dependency on a
proper subset of the key is **logically impossible**. Consequently every
relation is automatically in 2NF once it is in 1NF.

### 4.1 Composite-key stress test — reviews

The only relation that contains a composite uniqueness constraint is
`reviews`, which declares

```
UNIQUE (transaction_id, reviewer_id)
```

to prevent a user from reviewing the same transaction twice. This is a
secondary candidate key; its non-prime attributes are
`{review_for_user_id, rating, comment, created_at}`.

Each of these depends on the whole pair `(transaction_id, reviewer_id)`,
not on either attribute alone. Hence no partial dependency exists and the
relation is in 2NF under this candidate key as well.

---

## 5. Third Normal Form (3NF)

**Rule.** A relation is in 3NF iff it is in 2NF and there is no transitive
dependency of a non-prime attribute on the primary key. Equivalently, for
every non-trivial FD `X → A`, either `X` is a superkey or `A` is a prime
attribute.

**Transitive dependencies identified in the UNF.**

In `MarketplaceLog` the following transitive chains existed:

```
transaction_id → buyer_id  → buyer_hostel
transaction_id → seller_id → seller_hostel
transaction_id → item_id   → item_title
transaction_id → item_id   → item_category
```

`buyer_hostel` depends on the key only through `buyer_id`; likewise for
seller attributes and item attributes. These are textbook transitive
dependencies and must be removed.

### 5.1 Decomposition applied

| Transitive chain removed | Target relation that now stores the attribute |
|---|---|
| `transaction_id → buyer_id → buyer_hostel, buyer_phone, …` | `users(user_id, name, email, phone_number, hostel_block, …)` |
| `transaction_id → seller_id → seller_hostel, …` | `users` (same relation, different FK) |
| `transaction_id → item_id → item_title, price, item_type, …` | `items(item_id, seller_id, category_id, title, price, …)` |
| `item_id → category_id → category_name` | `categories(category_id, category_name)` |

The resulting schema has each fact stored **once and only once**, which is
the operational definition of 3NF.

### 5.2 Verification, relation by relation

| Relation | Prime attrs | Non-prime attrs | FDs | 3NF? |
|---|---|---|---|---|
| `admin` | `admin_id` | `name, email, password, role, created_at` | PK → all | Yes |
| `users` | `user_id` | `name, email, password, phone_number, hostel_block, is_verified, verified_by, created_at, updated_at` | PK → all; `email → user_id` (candidate key) | Yes |
| `categories` | `category_id` | `category_name` | PK → category_name; `category_name → category_id` (candidate key) | Yes |
| `items` | `item_id` | `seller_id, category_id, moderated_by, title, price, rent_price_per_day, item_type, availability_status, …` | PK → all | Yes |
| `transactions` | `transaction_id` | `item_id, buyer_id, seller_id, transaction_type, start_date, end_date, total_amount, payment_status, status, meetup_location, …` | PK → all | Yes |
| `meetup_slots` | `slot_id` | `transaction_id, proposed_time_slot, selected` | PK → all | Yes |
| `reviews` | `review_id` | `transaction_id, reviewer_id, review_for_user_id, rating, comment, created_at` | PK → all; `(transaction_id, reviewer_id) → review_id` | Yes |

For each relation, every non-trivial FD either has a superkey on its
left-hand side or has only prime attributes on its right-hand side.
Therefore no transitive dependency exists and **every relation is in 3NF**.

---

## 6. Note on BCNF

BCNF additionally requires that for every non-trivial FD `X → Y`, `X`
must be a superkey. The only relation with a non-trivial FD whose LHS is
not the primary key is `users` (`email → user_id`) and `categories`
(`category_name → category_id`). In both cases the LHS is a candidate
key, which is itself a superkey. Hence the schema is **also in BCNF**.
This was a favourable side-effect of the surrogate-key design choice.

---

## 7. Benefits realised by the 3NF / BCNF decomposition

1. **No update anomalies.** Updating a user's hostel touches exactly one
   row in `users`; every transaction involving that user sees the change
   via foreign key.
2. **No insertion anomalies.** A new user can exist independently of any
   transaction. A new category can exist independently of any item.
3. **No deletion anomalies.** Deleting a transaction does not remove
   information about the parties or the item; those facts live in their
   own relations and are referenced by foreign key.
4. **Controlled redundancy.** Each fact is stored exactly once; joins
   recover the denormalized view when needed (see `v_active_listings` and
   `v_seller_dashboard` in `03_views.sql`).
5. **Referential integrity.** All inter-table links are declared as
   foreign keys with explicit `ON DELETE / ON UPDATE` actions
   (see `01_schema.sql`, 11 foreign-key constraints).

---

## 8. Summary

The Campus Circle schema is in 3NF (and in fact in BCNF). The proof
proceeded as follows:

- 1NF achieved by eliminating multi-valued meetup slots and the parallel
  buyer/seller review attributes, yielding the `MEETUP_SLOTS` and
  `REVIEWS` relations.
- 2NF achieved automatically because every relation uses a single-attribute
  surrogate primary key, making partial dependency impossible.
- 3NF achieved by projecting the user, item, and category attributes out
  of the transaction relation into their own relations, thereby removing
  every transitive dependency on the transaction primary key.

The final schema has seven relations, eleven foreign keys, seven CHECK
constraints, and four UNIQUE constraints, all consistent with 3NF / BCNF.