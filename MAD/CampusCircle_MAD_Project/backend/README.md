# Campus Circle — Backend API

Thin Node.js + Express REST API for the CSE3709 MAD project. Reads go through the views defined in `03_views.sql`; writes go through the stored procedures in `04_procedures.sql`. The schema itself (`01_schema.sql`) is the CSE2021 DBMS submission.

## Setup

1. Install Node.js 18 or newer.
2. Install dependencies:
   ```
   npm install
   ```
3. Make sure MySQL 8 is running and the `campus_circle` database is loaded:
   ```
   mysql -u root -p < ../sql/01_schema.sql
   mysql -u root -p campus_circle < ../sql/02_seed.sql
   mysql -u root -p campus_circle < ../sql/03_views.sql
   mysql -u root -p campus_circle < ../sql/04_procedures.sql
   mysql -u root -p campus_circle < ../sql/05_triggers.sql
   mysql -u root -p campus_circle < ../demo_accounts.sql
   ```
4. Copy `.env.example` to `.env` and fill in your MySQL password.
5. Start the server:
   ```
   npm start
   ```

## Endpoints at a glance

| Method | Path | What it does | DB object used |
|---|---|---|---|
| GET  | `/api/health` | liveness ping | — |
| POST | `/api/auth/signup` | create a new user | `INSERT INTO users` |
| POST | `/api/auth/login`  | email+password check | `SELECT FROM users` |
| GET  | `/api/categories`  | dropdown list | `SELECT FROM categories` |
| GET  | `/api/items`       | home feed | `v_active_listings` |
| GET  | `/api/items/:id`   | item detail | join items+users+categories |
| POST | `/api/items`       | seller lists item | `sp_list_new_item` |
| GET  | `/api/items/seller/:user_id` | "My Listings" | items where seller_id=? |
| POST | `/api/transactions`             | buyer requests | `sp_create_transaction` |
| GET  | `/api/transactions/buyer/:user_id` | buyer's requests | joins |
| GET  | `/api/transactions/seller/:user_id`| seller dashboard | joins |
| PUT  | `/api/transactions/:id/status`  | approve / reject | `UPDATE transactions` |
| PUT  | `/api/transactions/:id/complete`| mark done | `sp_complete_transaction` |
| GET  | `/api/transactions/:id`         | detail | joins |
| POST | `/api/reviews`                  | submit review | `sp_submit_review` |
| GET  | `/api/reviews/user/:id`         | reviews received | joins |
| GET  | `/api/users/:id`                | basic profile | `SELECT FROM users` |
| GET  | `/api/users/:id/profile`        | profile + stats | UDFs + `v_seller_dashboard` |
| GET  | `/api/users/leaderboard/top`    | top rated | `v_top_rated_users` |

## For the real-device demo

- Bind MySQL to your LAN: edit `my.cnf` → `bind-address = 0.0.0.0` and restart.
- Find your laptop's LAN IP: `ipconfig` (Windows) or `ifconfig` (Mac/Linux).
- Start the API on the same machine as MySQL.
- On the phone, make sure it's on the same WiFi as the laptop.
- In the Android app, set `ApiClient.BASE_URL = "http://<laptop-ip>:3000/"`.


