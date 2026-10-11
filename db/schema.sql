-- ============================================================================
-- Vesi Timesheet ERP — schema
-- ----------------------------------------------------------------------------
-- A relational model standing in for what SAP ECC/S4 actually stores behind
-- this app's screens, close enough to the real table and field names that an
-- OData service (Fiori-style, or a CDS-based custom API) could plausibly sit
-- in front of it with the entities below as its EntitySets.
--
-- Two kinds of tables:
--   - Standard SAP tables (PA0001, CATSDB, PRPS, ...): real table and column
--     names, trimmed to the fields this app actually uses. A production
--     system carries many more fields; these are not full replicas.
--   - ZTIME_* tables: customer-built (Z-namespace), not standard SAP. SAP
--     ships no table for "approval queue" or "which CATS profile a company
--     uses" — those are customizing/workflow in real systems. Modeled here
--     as plain Z-tables so the mock data has somewhere concrete to live.
--
-- All data is fictional (see ../README.md, Confidentiality).
-- ============================================================================

-- ============================================================================
-- HR master data (Personnel Administration, infotypes as tables)
-- ============================================================================

-- PA0002 — Personal Data (Infotype 0002). One current row per employee here;
-- a real system keeps validity-dated history, omitted for this mock.
CREATE TABLE pa0002_personal_data (
  pernr         CHAR(8)       PRIMARY KEY,                  -- Personnel number
  first_name    VARCHAR(40)   NOT NULL,
  last_name     VARCHAR(40)   NOT NULL,
  full_name     VARCHAR(81)   GENERATED ALWAYS AS (first_name || ' ' || last_name) STORED
);
COMMENT ON TABLE pa0002_personal_data IS 'SAP PA0002 (Infotype 0002, Personal Data) — name only, trimmed for this mock.';

-- T001 — Company Codes
CREATE TABLE t001_company_code (
  bukrs   CHAR(4)      PRIMARY KEY,           -- e.g. PT01, PT02
  butxt   VARCHAR(60)  NOT NULL,              -- Company name
  land1   CHAR(3)      NOT NULL DEFAULT 'PT'  -- Country
);
COMMENT ON TABLE t001_company_code IS 'SAP T001 (Company Codes).';

-- CSKS — Cost Center master data (current segment only, no validity history)
CREATE TABLE csks_cost_center (
  kostl   CHAR(8)      PRIMARY KEY,                           -- Cost center, e.g. PT4010
  bukrs   CHAR(4)      NOT NULL REFERENCES t001_company_code(bukrs),
  ktext   VARCHAR(40)  NOT NULL                                -- Cost center name (CSKT in real SAP)
);
COMMENT ON TABLE csks_cost_center IS 'SAP CSKS (Cost Center master). Name folded in from CSKT for simplicity.';

-- CSLA — Activity Type master
CREATE TABLE csla_activity_type (
  lstar   CHAR(6)      PRIMARY KEY,   -- Activity type, e.g. CONS01
  ltext   VARCHAR(40)  NOT NULL       -- Activity type text
);
COMMENT ON TABLE csla_activity_type IS 'SAP CSLA (Activity Type master, Controlling).';

-- PA0001 — Organizational Assignment (Infotype 0001). Current segment only.
CREATE TABLE pa0001_org_assignment (
  pernr              CHAR(8)      PRIMARY KEY REFERENCES pa0002_personal_data(pernr),
  bukrs              CHAR(4)      NOT NULL REFERENCES t001_company_code(bukrs),
  kostl              CHAR(8)      NOT NULL REFERENCES csks_cost_center(kostl),
  job_classification VARCHAR(40)  NOT NULL,   -- e.g. "Consultant", "Senior consultant" (PLANS/stellen text in real SAP)
  begda              DATE         NOT NULL,
  endda              DATE         NOT NULL DEFAULT '9999-12-31'
);
COMMENT ON TABLE pa0001_org_assignment IS 'SAP PA0001 (Infotype 0001, Organizational Assignment).';

-- PA0007 — Planned Working Time (daily capacity). Current segment only.
CREATE TABLE pa0007_planned_hours (
  pernr        CHAR(8)   PRIMARY KEY REFERENCES pa0002_personal_data(pernr),
  daily_hours  NUMERIC(4,2) NOT NULL DEFAULT 8.0,
  begda        DATE      NOT NULL,
  endda        DATE      NOT NULL DEFAULT '9999-12-31'
);
COMMENT ON TABLE pa0007_planned_hours IS 'SAP PA0007 (Infotype 0007, Planned Working Time) — daily hours only, trimmed.';

-- T554T — Absence/Attendance Type texts (doubles as the type master for this mock)
CREATE TABLE t554t_absence_type (
  awart   CHAR(4)      PRIMARY KEY,    -- Absence type, e.g. 0100
  atext   VARCHAR(40)  NOT NULL        -- e.g. "Vacation"
);
COMMENT ON TABLE t554t_absence_type IS 'SAP T554T (Absence/Attendance Type texts).';

-- T512W / T512T — Wage Type characteristics + texts, merged for this mock
CREATE TABLE t512w_wage_type (
  lgart          CHAR(4)      PRIMARY KEY,   -- Wage type, e.g. 1200
  code           VARCHAR(10)  NOT NULL UNIQUE,  -- app-facing short code, e.g. AJC_NAC
  ltext          VARCHAR(40)  NOT NULL,          -- Wage type name (T512T)
  unit           VARCHAR(10)  NOT NULL,          -- days / km / amount
  is_amount      BOOLEAN      NOT NULL DEFAULT FALSE,  -- carries CATSAMOUNT (e.g. bonus) vs plain ANZHL
  needs_project  BOOLEAN      NOT NULL DEFAULT TRUE,
  note_label     VARCHAR(40)  DEFAULT '',          -- required free-text field's label, if any
  self_entry     BOOLEAN      NOT NULL DEFAULT TRUE -- false = project-owner-only (bonus)
);
COMMENT ON TABLE t512w_wage_type IS 'SAP T512W (Wage Type Characteristics) + T512T (texts), merged.';

-- ============================================================================
-- Project System (Controlling objects the timesheet books to)
-- ============================================================================

-- PROJ — Project Definition
CREATE TABLE proj_project_definition (
  pspid            VARCHAR(12)  PRIMARY KEY,   -- Project code, e.g. BNK-2026
  post1            VARCHAR(80)  NOT NULL,      -- Project name
  bukrs            CHAR(4)      REFERENCES t001_company_code(bukrs),  -- NULL = shared/internal, not tied to one company
  is_billable      BOOLEAN      NOT NULL DEFAULT TRUE,  -- FALSE = internal/admin work (e.g. AXI-INT)
  budget_hours      NUMERIC(8,1),               -- NULL where no budget is tracked
  responsible_pernr CHAR(8)      REFERENCES pa0002_personal_data(pernr)  -- project leader
);
COMMENT ON TABLE proj_project_definition IS 'SAP PROJ (Project Definition).';

-- PRPS — WBS Element, the actual receiver object time books to
CREATE TABLE prps_wbs_element (
  posid   VARCHAR(20)  PRIMARY KEY,    -- WBS element, e.g. BNK-2026.1.3 (empty for non-project activities)
  pspid   VARCHAR(12)  NOT NULL REFERENCES proj_project_definition(pspid),
  post1   VARCHAR(40)  NOT NULL,       -- WBS element short text
  lstar   CHAR(6)      NOT NULL REFERENCES csla_activity_type(lstar),
  skostl  CHAR(8)      REFERENCES csks_cost_center(kostl),  -- sending cost center
  rkostl  CHAR(8)      REFERENCES csks_cost_center(kostl),  -- receiving cost center (non-project bookings)
  aufnr   VARCHAR(12)                  -- internal order, unused today but modeled (always NULL here)
);
COMMENT ON TABLE prps_wbs_element IS 'SAP PRPS (WBS Element). AXI-INT (internal work) has no WBS, books to rkostl only.';

-- ============================================================================
-- Time recording — the center of the whole app
-- ============================================================================

-- CATSDB — CATS: Database table for working times. One row per day/project
-- (hours) or per day/wage-type (allowance/bonus), exactly as the real table
-- mixes both record kinds via LGART. This is the table the "CATS mapping"
-- screen's field list already describes field-by-field.
CREATE TABLE catsdb (
  catsdb_id    BIGSERIAL    PRIMARY KEY,                -- surrogate key; real CATSDB keys on WORKDATE+PERNR+COUNTER
  pernr        CHAR(8)      NOT NULL REFERENCES pa0002_personal_data(pernr),
  workdate     DATE         NOT NULL,                   -- one row per calendar day, never aggregated to the week
  posid        VARCHAR(20)  REFERENCES prps_wbs_element(posid),  -- RPROJ; NULL only impossible in practice, every row books somewhere
  lstar        CHAR(6)      REFERENCES csla_activity_type(lstar),
  catshours    NUMERIC(5,2) NOT NULL DEFAULT 0,          -- recorded hours (Z_CONS duration, or computed from BEGUZ/ENDUZ)
  beguz        TIME,                                     -- start time, Z_BSRV only
  enduz        TIME,                                     -- end time, Z_BSRV only (may cross midnight; see overnight flag)
  overnight    BOOLEAN      NOT NULL DEFAULT FALSE,       -- ENDUZ < BEGUZ: window crosses midnight, stays on WORKDATE
  lgart        CHAR(4)      REFERENCES t512w_wage_type(lgart),  -- set only on an allowance/bonus row
  anzhl        NUMERIC(6,2),                              -- allowance quantity (days/km), paired with LGART
  catsamount   NUMERIC(13,2),                             -- bonus amount, native CATSDB field (CURR 13,2)
  awart        CHAR(4)      REFERENCES t554t_absence_type(awart),  -- set when this row IS an absence marker, else NULL
  long_text    VARCHAR(300),                              -- free-text description (LTXA1 truncates this to 40 on transfer)
  status       VARCHAR(12)  NOT NULL DEFAULT 'DRAFT'       -- DRAFT / SAVED / APPROVED / TRANSFERRED / REJECTED
    CHECK (status IN ('DRAFT','SAVED','APPROVED','TRANSFERRED','REJECTED')),
  origin       VARCHAR(12)  NOT NULL DEFAULT 'Manual'
    CHECK (origin IN ('Manual','Suggested','Joule')),
  created_by   CHAR(8)      REFERENCES pa0002_personal_data(pernr),  -- CPUID/ERNAM equivalent: who actually typed it in
  on_behalf_of CHAR(8)      REFERENCES pa0002_personal_data(pernr),  -- usually = pernr, differs when a leader mass-enters for someone
  created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
  changed_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),

  CHECK (
    (lgart IS NULL AND awart IS NULL)      -- a plain hours row, or
    OR (lgart IS NOT NULL AND awart IS NULL)  -- an allowance/bonus row, or
    OR (lgart IS NULL AND awart IS NOT NULL)  -- an absence marker row
  )
);
COMMENT ON TABLE catsdb IS 'SAP CATSDB (CATS: Database table for working times). Hours, allowances and the bonus amount all live here, exactly as in the real table.';
CREATE INDEX idx_catsdb_pernr_date ON catsdb(pernr, workdate);
CREATE INDEX idx_catsdb_posid ON catsdb(posid);

-- CATSDB correction chain: SAP never edits a TRANSFERRED/APPROVED row in
-- place — a correction creates a new row pointing back to the original via
-- REFCOUNTER, and goes through approval again (see docs/cats-mapping.md,
-- "RULE" callouts already in the app's own CATS mapping screen).
ALTER TABLE catsdb ADD COLUMN refcounter BIGINT REFERENCES catsdb(catsdb_id);

-- PA2001 — Absences (Infotype 2001). The leave-request side; a row here can
-- drive one or more AWART marker rows in CATSDB for the days it covers.
CREATE TABLE pa2001_absences (
  pa2001_id       BIGSERIAL    PRIMARY KEY,
  pernr           CHAR(8)      NOT NULL REFERENCES pa0002_personal_data(pernr),
  awart           CHAR(4)      NOT NULL REFERENCES t554t_absence_type(awart),
  begda           DATE         NOT NULL,
  endda           DATE         NOT NULL,
  hours           NUMERIC(5,2) NOT NULL,          -- total hours for the range (full day vs partial)
  status          VARCHAR(10)  NOT NULL DEFAULT 'pending'
    CHECK (status IN ('pending','approved','rejected')),
  request_number  VARCHAR(20)                      -- ESS Leave Request number, e.g. "4500301"
);
COMMENT ON TABLE pa2001_absences IS 'SAP PA2001 (Infotype 2001, Absences) — the Leave Request this app reads as read-only.';
CREATE INDEX idx_pa2001_pernr ON pa2001_absences(pernr, begda);

-- ============================================================================
-- ZTIME_* — customer-built (Z-namespace), not standard SAP
-- ============================================================================

-- CATS data entry profile master. Standard SAP configures this across several
-- IMG/customizing tables (V_T555A and friends); collapsed to one Z-table here.
CREATE TABLE ztime_profile (
  profile_code   VARCHAR(10)  PRIMARY KEY,   -- Z_CONS, Z_BSRV
  is_clock_entry BOOLEAN      NOT NULL,       -- FALSE = duration only, TRUE = BEGUZ/ENDUZ with computed duration
  fields_shown   VARCHAR(80)  NOT NULL        -- human-readable, for the CATS mapping screen's own display
);
COMMENT ON TABLE ztime_profile IS 'Z-table: CATS data entry profile master (standard SAP spreads this across customizing, not one table).';

-- Company → CATS profile, read at the date of the entry. Named after the
-- field this app's own UI already calls ZTIME_COMPANY_CFG.
CREATE TABLE ztime_company_cfg (
  bukrs         CHAR(4)      NOT NULL REFERENCES t001_company_code(bukrs),
  profile_code  VARCHAR(10)  NOT NULL REFERENCES ztime_profile(profile_code),
  begda         DATE         NOT NULL,
  endda         DATE         NOT NULL DEFAULT '9999-12-31',
  PRIMARY KEY (bukrs, begda)
);
COMMENT ON TABLE ztime_company_cfg IS 'Z-table: maps a company code to its CATS data entry profile, validity-dated.';

-- Approval queue / workflow state. In a real system this is largely derived
-- from CATSDB.STATUS plus a workflow log, not its own master table; modeled
-- here as a Z-table so the Approval screen has a concrete source to read.
CREATE TABLE ztime_approval (
  approval_id         BIGSERIAL    PRIMARY KEY,
  bukrs               CHAR(4)      NOT NULL REFERENCES t001_company_code(bukrs),
  period_type         VARCHAR(5)   NOT NULL CHECK (period_type IN ('WEEK','MONTH')),
  period_key          VARCHAR(10)  NOT NULL,     -- week number ("2026-W38") or month ("2026-09")
  pernr               CHAR(8)      NOT NULL REFERENCES pa0002_personal_data(pernr),
  pspid               VARCHAR(12)  REFERENCES proj_project_definition(pspid),
  total_hours         NUMERIC(6,2) NOT NULL,
  in_project_hours    NUMERIC(6,2) NOT NULL,
  deviation_hours     NUMERIC(6,2) NOT NULL,
  has_exception       BOOLEAN      NOT NULL DEFAULT FALSE,
  exception_note      VARCHAR(120),
  approved            BOOLEAN      NOT NULL DEFAULT FALSE,
  approver_pernr      CHAR(8)      REFERENCES pa0002_personal_data(pernr),
  approved_at         TIMESTAMPTZ
);
COMMENT ON TABLE ztime_approval IS 'Z-table: per-person/period approval queue entry (Approval screen). Real SAP derives this from CATSDB.STATUS + workflow.';

-- Project leader roster: who can act as leader for mass entry, and which
-- projects/WBS elements they are scoped to (ownership, not line management).
CREATE TABLE ztime_leader (
  leader_id   VARCHAR(10)  PRIMARY KEY,   -- e.g. "RN"
  pernr       CHAR(8)      NOT NULL REFERENCES pa0002_personal_data(pernr),
  label       VARCHAR(60)  NOT NULL,      -- short label shown in "Acting as", e.g. "RTL-TT + AXI-INT"
  bukrs       CHAR(4)      NOT NULL REFERENCES t001_company_code(bukrs)
);
COMMENT ON TABLE ztime_leader IS 'Z-table: mass-entry leader roster (project ownership, not org-chart line management).';

CREATE TABLE ztime_leader_project (
  leader_id  VARCHAR(10)  NOT NULL REFERENCES ztime_leader(leader_id),
  pspid      VARCHAR(12)  NOT NULL REFERENCES proj_project_definition(pspid),
  PRIMARY KEY (leader_id, pspid)
);
COMMENT ON TABLE ztime_leader_project IS 'Z-table: which projects each leader owns, for Team mass-entry scoping.';

-- Team roster membership: who belongs to which leader's team for mass entry
-- (ownership-based, independent of PA0001's own cost-center/line reporting).
CREATE TABLE ztime_team_member (
  leader_id  VARCHAR(10)  NOT NULL REFERENCES ztime_leader(leader_id),
  pernr      CHAR(8)      NOT NULL REFERENCES pa0002_personal_data(pernr),
  PRIMARY KEY (leader_id, pernr)
);
COMMENT ON TABLE ztime_team_member IS 'Z-table: team membership for mass entry, scoped by project ownership (see ztime_leader_project).';

-- ============================================================================
-- Explicitly out of scope: AI suggestions (chat.* state, "sugs" arrays) are
-- an application-layer feature, not SAP data of any kind, and stay out of
-- this schema entirely — they are computed client-side / by the assistant
-- backend from CATSDB + PA2001 content, never persisted as their own table.
-- ============================================================================
