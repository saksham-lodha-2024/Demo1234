# Campus Circle — MAD Project (CSE3709)

Verified peer-to-peer BMU marketplace. The **same MySQL database** we built for the DBMS project (CSE2021) is wrapped by a thin Node.js REST API and consumed by a native Android (Java) app. One project, two subjects, one database, one demo.

**Team:** Saksham Lodha (240626),Gauri Pandey (240959), Rishit Rebant (240608), Prerit Shrivastava (240593)
**MAD Faculty:** Mr. Gautam Gupta 
**DBMS Supervisor:** Dr. Kiran Sharma

---

## Architecture

```
┌─────────────────────┐       HTTP + JSON        ┌───────────────────┐         mysql2       ┌─────────────────────┐
│  Android app (Java) │ ───────────────────────► │  Node.js + Express │ ───────────────────► │  MySQL 8            │
│  Retrofit client    │ ◄─────────────────────── │  ~15 REST endpoints│ ◄─────────────────── │  campus_circle db   │
└─────────────────────┘                          └───────────────────┘                      └─────────────────────┘
         Tier 1                                          Tier 2                                      Tier 3
         (client)                                   (application)                          (the CSE2021 DBMS work)
```

The backend is intentionally thin — reads go through **views** (`v_active_listings`, `v_seller_dashboard`, `v_top_rated_users`), writes go through **stored procedures** (`sp_list_new_item`, `sp_create_transaction`, `sp_complete_transaction`, `sp_submit_review`), and analytics go through **scalar UDFs** (`fn_user_avg_rating`, `fn_user_review_count`, `fn_user_total_earnings`). That means all business rules, validations, and ACID guarantees live in MySQL — the app + API are UI over the DB, which is exactly the point of the combined submission.

## Course topics this covers (CSE3709 syllabus)

| Topic from syllabus | Where it appears |
|---|---|
| Activities & Activity Lifecycle | Every `*Activity` extends `AppCompatActivity`; Splash→Login→Main chain |
| Intents & passing data | `startActivity(...).putExtra("item_id", id)` across ItemDetail, RequestDetail, etc. |
| Permissions | `INTERNET` + `ACCESS_NETWORK_STATE` in manifest |
| ConstraintLayout / LinearLayout | All `res/layout/*.xml` |
| Views — TextView, EditText, Button, ImageView, ProgressBar, Spinner, RatingBar | Login, Signup, PostItem, Review |
| RecyclerView + Adapter + ViewHolder | `HomeFragment`, `MyListingsFragment`, `RequestsFragment` use `ItemAdapter` / `TransactionAdapter` |
| Material components, Cards, Toast | Bottom nav, cards on every row, Toast on all errors |
| Styles & Themes | `values/themes.xml` (`CcButton`, `CcInput`) |
| BottomNavigationView + 3rd-party | `MainActivity` hosts 4 fragments |
| SharedPreferences data storage | `util/SessionManager.java` |
| Networking — Retrofit + JSON | `api/ApiClient.java`, `api/ApiService.java` |

> We **don't** use SQLite/Room (Lecture 10) because our persistence lives in the central MySQL. We **don't** use Firebase (Lecture 12), Google Maps (Lecture 13), camera/sensors, or SMS/email — all skipped intentionally to keep the scope university-level.

---

## Folder layout

```
mad_project/
├── backend/                       Node.js REST API
│   ├── package.json
│   ├── server.js                  Express app
│   ├── db.js                      mysql2 pool
│   ├── routes/
│   │   ├── auth.js
│   │   ├── categories.js
│   │   ├── items.js
│   │   ├── transactions.js
│   │   ├── reviews.js
│   │   └── users.js
│   ├── .env.example
│   └── README.md                  backend-specific run/deploy notes
│
├── android/                       Android Studio (Java) project
│   ├── build.gradle
│   ├── settings.gradle
│   └── app/
│       ├── build.gradle
│       └── src/main/
│           ├── AndroidManifest.xml
│           ├── java/com/campuscircle/
│           │   ├── MainActivity.java
│           │   ├── activities/    (Splash, Login, Signup, ItemDetail, PostItem, RequestDetail, Handover, Review)
│           │   ├── fragments/     (Home, MyListings, Requests, Profile)
│           │   ├── adapters/      (ItemAdapter, TransactionAdapter)
│           │   ├── models/        (User, Item, Transaction, Review, Category, ...)
│           │   ├── api/           (ApiClient, ApiService — Retrofit)
│           │   └── util/          (SessionManager)
│           └── res/
│               ├── layout/        (15 XML layouts)
│               ├── menu/          (bottom_nav.xml)
│               ├── drawable/      (bg_card, bg_chip)
│               └── values/        (colors, strings, themes)
│
├── demo_accounts.sql              Resets passwords for 4 viva-demo users
└── README.md                      (this file)
```

---

## Setup — end-to-end

### 1. Database (one-time)

```bash
# From the CSE2021 DBMS submission, run in order:
mysql -u root -p < sql/01_schema.sql
mysql -u root -p campus_circle < sql/02_seed.sql
mysql -u root -p campus_circle < sql/03_views.sql
mysql -u root -p campus_circle < sql/04_procedures.sql
mysql -u root -p campus_circle < sql/05_triggers.sql

# Then the MAD demo-account reset:
mysql -u root -p campus_circle < demo_accounts.sql
```

### 2. Backend

```bash
cd backend
cp .env.example .env        # edit DB_PASSWORD
npm install
npm start
```

Expected output:
```
[db] Connected to campus_circle
Campus Circle API running on port 3000
  * Local      : http://127.0.0.1:3000/api/health
  * Emulator   : http://10.0.2.2:3000/api/health
  * LAN        : http://<your-laptop-ip>:3000/api/health  (for real device)
```

### 3. Android app

1. Open Android Studio → **Open** → pick the `android/` folder. Gradle will sync.
2. Plug in an Android phone (USB debugging on) — **or** start an emulator.
3. Edit `app/src/main/java/com/campuscircle/api/ApiClient.java`:
   - Emulator: leave `BASE_URL = "http://10.0.2.2:3000/"` as-is
   - Real phone: change to `"http://<your-laptop-lan-ip>:3000/"`
4. Click **Run** (Shift+F10). The app installs + launches.

---

## Demo accounts

All four share the password `demo@123` after you run `demo_accounts.sql`.

| Name | Email | Role in demo |
|---|---|---|
| Saksham Lodha      | `saksham.lodha.240626@bmu.edu.in`      | seller — has listings, receives requests |
| Gauri Pandey       | `gauri.pandey.240959@bmu.edu.in`       | dual role — sells and buys |
| Rishit Rebant      | `rishit.rebant.240608@bmu.edu.in`      | buyer — requests items |
| Prerit Shrivastava | `prerit.shrivastava.240593@bmu.edu.in` | reviewer — completes and rates |

Recommended **viva demo flow** (5 min):

1. Log in as **Saksham** → Post a new item ("JBL Speaker", Electronics, BUY, Rs.1500)
2. Log out → log in as **Rishit** → Open home feed → tap Saksham's new listing → tap *Request to Buy*
3. Log out → log in as **Saksham** → Requests tab → *As Seller* → tap the new request → *Approve*
4. Log out → log in as **Rishit** → Requests tab → *As Buyer* → open the approved request → *Mark Completed*
5. Same screen → *Submit Review* → 5 stars → "Great exchange on campus"
6. Open **Profile** → see `avg_rating`, `total_earnings`, dashboard update live

That covers: signup/login, listing, browsing, requesting, approving, completing, reviewing, profile stats — every P1 screen and every stored procedure. Total flow hits ~11 of the 15 viva rubric topics in one go.

---

## Rubric coverage (End Term = 40 marks)

| Component | Max | What hits it |
|---|---|---|
| Project running in real device | 15 | APK installs on phone, hits backend on laptop's LAN IP, full lifecycle works |
| Group presentation | 10 | 10-slide deck (architecture, DBMS integration, Android stack, lifecycle walkthrough) |
| Individual viva | 10 × 4 | Activity lifecycle, Intents, RecyclerView/Adapter, Retrofit, fragment swap, SharedPreferences — each teammate owns one |
| Project report PDF | 5 | 8-12 page MAD report — can reuse Problem Statement + Methodology from the DBMS report |

---

## Viva-friendly notes (what to say when asked)

- **Why Node.js and not Firebase?** We already have a normalized MySQL schema from the DBMS project — wrapping it in a REST API was cheaper than re-modelling the data in Firebase and it keeps both subjects on a single source of truth.
- **Why procedures instead of plain INSERTs in the backend?** Validations (seller verified, buyer ≠ seller, price ≥ 0, rating 1-5) are in `SIGNAL SQLSTATE` branches inside the procedures. The Node API just forwards the error as HTTP 400. Zero duplication of business rules.
- **How does ACID hold?** Each procedure wraps its multi-row writes in `START TRANSACTION ... COMMIT` with a `DECLARE EXIT HANDLER FOR SQLEXCEPTION` that rolls back on any mid-flight failure.
- **Why a single Activity with fragments instead of 4 separate Activities for the tabs?** BottomNavigationView + FragmentManager is the standard Android idiom (Lecture 9), and it preserves state across tab switches without re-creating whole Activities.
- **How do you handle network calls off the main thread?** Retrofit's `enqueue()` automatically runs the network call on a worker thread and posts the callback back to the main thread — that's what lets us update UI directly in `onResponse`.
