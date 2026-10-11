# Timesheet Fiori Prototype

Clickable prototype of project time recording, designed as a Fiori extension on SAP BTP, with recording read into CATS. Serves as a visual and functional reference for development and for client conversations.

Documents that accompany this repository:

- UX/UI Specification, 23 sections, from principles to acceptance criteria
- Annex A, mapping the interface to SAP concepts and CATSDB fields
- `db/SCHEMA.md`, the SAP-representative PostgreSQL schema behind this
  app, and `db/API.md`/`db/DEPLOY.md` for the API layer and production
  deploy

This fork is backed by a real PostgreSQL database modeled on the SAP
tables a production CATS integration would actually read and write (see
`db/SCHEMA.md`). The frontend loads everything from `api/bootstrap.js` on
start and writes through `api/*.js` on Save, Submit, Team mass entry and
Approval — not from the in-memory literals the original prototype used.

## What the prototype does

Everything below works end to end, against a real database (see
"Data" further down for exactly what is and isn't persisted).

**Recording**
- Weekly grid with inline editing, accepts `1.5`, `1:30` and `90m`, rounded to 15 minutes
- Calendar view (7 days) with project blocks and external events to convert
- Quick add with natural language interpretation and correctable chips
- Copy previous week (pulls the real previous week's rows once one exists in the sample), apply template, favorites per project
- Week navigation (arrows or `←`/`→`) across a multi-week sample per company: PT01 (`Z_CONS`) spans weeks 32–44, PT02 (`Z_BSRV`) spans weeks 36–41, each range mixing posted weeks, one submitted and in approval, the current draft, and upcoming ones with an empty grid

**Absences, read from the leave request**
- An approved full-day absence closes that day to time entry, in both the grid and the calendar
- A partial absence reduces day capacity and the week's expected total
- A pending request raises a warning, doesn't block
- The `Simulate approval` button shows the conflict that arises when a request is approved after hours were already recorded, with assisted resolution
- Suggestions that fall on days with an approved absence aren't proposed

**Allowances against a project**
- Catalogue of wage types with unit and mandatory fields: domestic and foreign per diem, own-car kilometres, shift allowance, project bonus
- Recorded as quantity and unit, never as a value. Payroll does the valuation
- An allowance can exist on a day with no hours, for example kilometres for a Saturday trip
- Kilometres and foreign per diem block submission until origin and destination, or the country, is filled in
- The bonus is the exception: it carries an amount, it is not on the employee's screen, and only the project owner records it

**Entry mode by company, profile Z_CONS or Z_BSRV**
- The company comes from the employee's IT0001 and `ZTIME_COMPANY_CFG` maps it to a CATS data entry profile, read at the date of the entry
- `Z_CONS` records duration only. `Z_BSRV` records start and end, `BEGUZ` and `ENDUZ`, with the duration computed and never editable
- Overnight windows are allowed in `Z_BSRV` and the entry stays on the starting day
- Overlapping windows on the same day block submission
- The switch in the shellbar changes IT0001, which is the same as opening the sheet as someone assigned to the other company

**Team leader mass entry**
- Scope is by project ownership only, never by line hierarchy: each project has one owner, and mass entry shows everyone allocated to that project regardless of who they report to in IT0001/OM. Rui Tavares is the example, he works on both Pedro Alves's project (AER-WFM) and Ana Ferreira's (BNK-2026)
- Has its own week navigator (same arrows and `←`/`→`), so switching weeks doesn't mean leaving the screen
- A read-only grid shows what each person already has recorded this week, live as new hours are staged, so a day already at or past capacity is visible before saving anything on top of it
- Fill a project, a duration or a start and end time, and the days, select people, apply. Duration fills people on a duration profile (`Z_CONS`), start/end fills people on `Z_BSRV`, in the same click, since a team can mix both companies. Nothing is saved until the leader reviews the grid
- The save is partial on purpose: lines that fail keep their reason on screen, the rest are written
- Every line keeps `CREATED_BY` and `ON_BEHALF_OF`. There is no self-confirmation step
- Allowances can be mass entered too, staged as a list rather than a grid since each one is a single occurrence, not a per-day cell
- The project owner records and approves the bonus in the same act, on the same screen

**Period control**
- Monthly, per company. A closed period rejects entries and changes, in the personal sheet and in mass entry

**Conversational assistant, Joule pattern**
- Recording by conversation, checking the week's status, checking absences, copying the week, applying suggestions, submitting
- Interpreted by Claude (`api/chat.js`, function calling), with the browser's regex interpreter as an automatic fallback when the key isn't configured or the call fails
- Never saves without explicit confirmation, and always shows the receiver object and activity type before saving
- Refuses days with an approved absence and proposes the next free day
- Entries created by the assistant are marked with origin `Joule`

**Validation and approval**
- Three severities: error blocks, warning doesn't block, info guides
- Summary per project and receiver object before submission
- Approval screen with bulk approval and exceptions singled out

**CATS mapping**
- Field-by-field table, state chain through to transfer
- Live generation of CATS records from the filled week, as a table or as a payload
- Hours and allowances in the same record set: `CATSHOURS` with `BEGUZ` and `ENDUZ`, or `LGART` with `ANZHL`
- The bonus amount goes to `CATSAMOUNT`, a native CATSDB field (CURR 13,2), not a customer-field workaround. Whether the standard `CAT6` transfer already maps it to `IT2010 BETRG` still needs confirming with the client

## Structure

```
body.html         page content, single source of truth for the markup
styles.css        color and typography tokens, light and dark theme
app.js            all the logic; loads data from api/bootstrap.js on start
index.html        the complete document, what Vercel serves  (generated)
artifact.html     the same page without the shell, to publish as an Artifact  (generated)
tools/build.py     generates the two files above from body.html
api/_db.js        shared Postgres pool (pg), not a route
api/bootstrap.js  one-call load of everything the frontend needs
api/timesheet.js  My Timesheet: read a week, Save (POST)
api/timesheet-submit.js   Submit a saved week
api/team.js       Team mass-entry roster
api/team-entry.js Team mass-entry Save
api/approvals.js  Approval queue read + approve
api/employee.js, api/projects.js, api/leaders.js, api/absences.js, api/reference.js
                  smaller read-only endpoints, mostly superseded by bootstrap.js
api/chat.js       optional serverless function (the assistant), off by default
db/schema.sql     PostgreSQL DDL (SAP-representative tables + Z-custom ones)
db/seed.sql       fictional sample data matching the schema
db/SCHEMA.md      what each table is and what it replaces
db/API.md         the API surface
db/DEPLOY.md      production deploy steps (Neon/Vercel Postgres)
vercel.json       static site + functions configuration
```

After editing `body.html`, run:

```bash
python3 tools/build.py
```

## Running locally

Needs a real Postgres (the frontend fetches `api/bootstrap.js` on load, which needs `DATABASE_URL`):

```bash
# once: create a local Postgres database, then
psql $DATABASE_URL -f db/schema.sql
psql $DATABASE_URL -f db/seed.sql

npm install    # pg + @anthropic-ai/sdk
cp .env.example .env    # adjust DATABASE_URL if needed
vercel dev     # serves the static files AND api/*.js together
```

A plain `python3 -m http.server` only serves static files — `app.js` will fetch `api/bootstrap.js`, get a 404, and the boot screen never clears. `vercel dev` (or an equivalent local server that also runs `api/*.js`, see `db/API.md`) is required, not optional, for this fork.

Without `ANTHROPIC_API_KEY`, the assistant's natural-language input still falls back to the local regex interpreter — that part is unrelated to the database and works the same as before.

## Publishing to Vercel

See `db/DEPLOY.md` for the full step-by-step (creating the Vercel project, provisioning Postgres via Neon, loading `db/schema.sql`/`db/seed.sql`, environment variables). Short version: import the repository into Vercel (framework preset **Other**, `vercel.json` already carries the rest of the configuration), add a Postgres database from the project's Storage tab (sets `DATABASE_URL` automatically), load the schema+seed against it, then set `ANTHROPIC_API_KEY` if you want the Claude-powered assistant too.

## Data

Employee, projects, WBS, cost centers, team, absences and the weekly timesheet data are real rows in Postgres (`db/schema.sql`, seeded with fictional sample data by `db/seed.sql` — see `db/SCHEMA.md` for how each table maps to a real SAP table or a documented Z-custom extension). `app.js` holds no mock arrays of that data anymore; it loads everything from `api/bootstrap.js` on start and writes through `api/*.js`. Two small things stay as static client-side samples, by design, because neither has a real SAP table to live in (see `api/bootstrap.js`'s own header comment): assistant suggestions, and each Team-screen member's day-level absence flag for everyone except the self-service user. No request leaves the browser except to this app's own `api/*.js` and, when Claude is enabled, to `api/chat.js`. No local storage, no cookies, beyond the language preference.

## Known limits, by design

- Week navigation covers a fixed sample range per company (PT01: weeks 32–44, PT02: weeks 36–41), mixing posted, submitted, current-draft and upcoming empty weeks; going further back or forward than that is out of sample, not simulated
- Whether the standard `CAT6` transfer maps `CATSAMOUNT` to `IT2010 BETRG` automatically, or needs configuring, is flagged as an open question in the payload, not solved
- Without `ANTHROPIC_API_KEY` configured, the natural-language interpreter is deterministic, based on regular expressions. It recognizes duration, day and project prefix, and nothing else. See the next section to connect Claude
- Each request to the assistant is independent, with no memory of the previous turn
- There's no authentication or profiles, the user is fixed — and the API accepts any `pernr` in a request without checking who's actually calling it; fine for this demo, not for an environment with real data (see `db/DEPLOY.md`)
- Assistant suggestions and each Team-screen member's day-level absence flag (except the self-service user's own) are static client-side samples, not read from the database — neither has a real SAP table to live in (`api/bootstrap.js` explains why)

## Connecting Claude to the assistant

`api/chat.js` already calls Claude (`claude-opus-5`, function calling) to interpret free text. To enable it:

1. Set the `ANTHROPIC_API_KEY` environment variable on the Vercel project (Settings → Environment Variables)
2. Redeploy

Without the key, the function returns 501 and the client automatically falls back to the browser's regex interpreter, without breaking the demo.

The engine picks one of six closed functions (`registar_horas`, `consultar_semana`, `listar_ausencias`, `copiar_semana`, `aplicar_sugestoes`, `submeter_semana`) based on the context the client sends with every question: the projects the person is allocated to, the week's absences and capacity per day. It never writes to the timesheet, it only returns the function and its arguments; saving and confirmation stay on the client side, exactly as in the local interpreter.

## What's missing for the assistant to be real in an SAP production setting

The prototype demonstrates the interaction pattern, which is the part that needs validation with users. Connected to Claude, it already covers free-text interpretation, closed function calling and per-user grounding. To operationalize it for real in an SAP scenario, three pieces are missing:

1. **Authentication and identity propagation.** XSUAA or IAS with principal propagation through to the S/4HANA API, so that the write happens on the person's behalf and the audit trail is correct
2. **Conversation state.** Short-retention session storage, to keep context across turns without storing history indefinitely. Each request to `api/chat.js` is currently independent, with no memory of the previous turn
3. **Evaluation.** A set of test cases with real consultant phrasing, including hard cases, to measure accuracy before opening it up to users

In the SAP scenario, the standard path is to expose these functions as a Joule capability, with Joule Studio on SAP Build, instead of building a bespoke chat inside the application. The advantage is that the user gets a single assistant on the launchpad instead of one per application. This prototype imitates the interaction pattern, not the product.

## Notice

This prototype's assistant is called Assistant and is labeled `Joule pattern`. It is not SAP's Joule, doesn't use SAP's brand or services, and only serves to demonstrate the interaction pattern. When connected to Claude, it's Anthropic that processes the text sent to `api/chat.js`, within the context described above.
