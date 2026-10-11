/**
 * GET /api/bootstrap?pernr=00104567
 *
 * Everything app.js needs to hydrate on load, shaped as closely as
 * possible to the mock literals it used to declare (PROJECTS, COMPANIES,
 * WAGETYPES, PROFILES/ZTIME_COMPANY_CFG, LEADERS, TEAM, WEEKS_PT01/PT02,
 * APPROVALS_PT01/PT02) — one call instead of a dozen, so the app can
 * still boot into a single synchronous render() once this resolves,
 * same as it always has.
 *
 * Two things stay deliberately OUT of this response, per SCHEMA.md's own
 * scope boundary (AI suggestions have no table) plus one further
 * simplification made here for the same reason — neither is persisted,
 * so there's nothing to fetch:
 *   - assistant suggestions (week.sugs) — app.js keeps its own static
 *     sample, merged in by week number after this loads.
 *   - each team member's day-level "approved absence" flag (TEAM[].abs,
 *     only ever used to grey out a cell in the Team mass-entry grid) —
 *     seeding real PA2001 rows for all 29 team members was out of scope
 *     for this pass; app.js keeps the same static sample it always had.
 */
import { query, sendError } from "./_db.js";

function isoWeekAndMonday(dateISO) {
  const d = new Date(dateISO + "T00:00:00Z");
  const day = (d.getUTCDay() + 6) % 7; // 0=Mon
  const monday = new Date(d);
  monday.setUTCDate(d.getUTCDate() - day);
  const thursday = new Date(monday);
  thursday.setUTCDate(monday.getUTCDate() + 3);
  const yearStart = new Date(Date.UTC(thursday.getUTCFullYear(), 0, 1));
  const week = Math.ceil(((thursday - yearStart) / 86400000 + 1) / 7);
  return { num: week, monday: monday.toISOString().slice(0, 10) };
}

const LOCKED_STATUSES = ["SUBMITTED", "APPROVED", "TRANSFERRED"];

/** Groups flat catsdb hours rows into app.js's week.rows shape (one entry
 * per receiver+description, with an h[7] array), and allowance rows into
 * its flat per-day allow[] shape. Both take a pspidToIndex map so output
 * uses PROJECTS[] indices, exactly like the original mock literals. */
function buildWeeks(hoursRows, allowRows, absenceRows, pspidToIndex, noWbsIndex) {
  const weeksByMonday = {};
  function weekFor(dateISO) {
    const { num, monday } = isoWeekAndMonday(dateISO);
    if (!weeksByMonday[monday]) {
      weeksByMonday[monday] = { num, start: monday.replace(/-/g, ""), rows: [], allow: [], absences: [], sugs: [], _rowsByKey: {} };
    }
    return weeksByMonday[monday];
  }
  function projIndexFor(pspid) {
    return pspid ? pspidToIndex[pspid] : noWbsIndex;
  }

  hoursRows.forEach((r) => {
    const workdate = r.workdate.toISOString().slice(0, 10);
    const week = weekFor(workdate);
    const { monday } = isoWeekAndMonday(workdate);
    const dayIdx = Math.round((new Date(workdate) - new Date(monday)) / 86400000);
    const pIdx = projIndexFor(r.pspid);
    const key = pIdx + "|" + (r.desc || "") + "|" + r.origin;
    let row = week._rowsByKey[key];
    if (!row) {
      row = { id: Number(r.catsdb_id), p: pIdx, desc: r.desc || "", h: [0, 0, 0, 0, 0, 0, 0], origin: r.origin, _status: r.status };
      week._rowsByKey[key] = row;
      week.rows.push(row);
    }
    row.h[dayIdx] += Number(r.hours);
    if (LOCKED_STATUSES.includes(r.status)) row._status = r.status;
  });

  allowRows.forEach((a) => {
    const workdate = a.workdate.toISOString().slice(0, 10);
    const week = weekFor(workdate);
    const { monday } = isoWeekAndMonday(workdate);
    const dayIdx = Math.round((new Date(workdate) - new Date(monday)) / 86400000);
    week.allow.push({
      id: "al" + a.catsdb_id,
      day: dayIdx,
      p: projIndexFor(a.pspid),
      code: a.wage_code,
      qty: a.qty !== null ? Number(a.qty) : 0,
      amount: a.amount !== null ? Number(a.amount) : 0,
      note: a.note || "",
      by: a.created_by,
      onBehalf: a.on_behalf_of,
      _status: a.status,
    });
  });

  // Absences (PA2001) aren't company-scoped in the real data — only
  // hours/allowance rows are. Only attach one to a week inside THIS
  // company's own date range (hours/allow rows already built above), so
  // an absence from the other company's period doesn't conjure up a
  // phantom week with zero bookings here.
  const contentMondays = Object.keys(weeksByMonday).sort();
  const minMonday = contentMondays[0];
  const maxMonday = contentMondays[contentMondays.length - 1];

  absenceRows.forEach((ab) => {
    const begdaISO = ab.begda.toISOString().slice(0, 10);
    const { monday } = isoWeekAndMonday(begdaISO);
    if (!minMonday || monday < minMonday || monday > maxMonday) return;
    const week = weekFor(begdaISO);
    const dayIdx = Math.round((new Date(begdaISO) - new Date(monday)) / 86400000);
    week.absences.push({
      id: "ab" + ab.pa2001_id,
      day: dayIdx,
      type: ab.awart_name,
      awart: ab.awart,
      hours: Number(ab.hours),
      status: ab.status,
      src: "Request " + ab.request_number,
    });
  });

  const weeks = Object.values(weeksByMonday).sort((a, b) => (a.start < b.start ? -1 : 1));
  weeks.forEach((w) => {
    const anyRow = w.rows.length > 0 || w.allow.length > 0;
    const allLocked = anyRow && [...w.rows, ...w.allow].every((r) => LOCKED_STATUSES.includes(r._status));
    const weekDates = Array.from({ length: 5 }, (_, i) => {
      const d = new Date(w.start.slice(0, 4) + "-" + w.start.slice(4, 6) + "-" + w.start.slice(6, 8));
      d.setUTCDate(d.getUTCDate() + i);
      return d.toISOString().slice(0, 10);
    });
    const fullyAbsent = !anyRow && weekDates.every((d) => w.absences.some((ab) => {
      const abDate = new Date(w.start.slice(0, 4) + "-" + w.start.slice(4, 6) + "-" + w.start.slice(6, 8));
      abDate.setUTCDate(abDate.getUTCDate() + ab.day);
      return ab.status === "approved" && abDate.toISOString().slice(0, 10) === d;
    }));
    w.submitted = allLocked || fullyAbsent;
    w.rows.forEach((r) => delete r._status);
    w.allow.forEach((a) => delete a._status);
    delete w._rowsByKey;
  });
  return weeks;
}

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return sendError(res, 405, "method_not_allowed");
  }
  const pernr = req.query.pernr || "00104567";

  try {
    const [employeeQ, companiesQ, wageTypesQ, profilesQ, projectsQ, teamQ, approvalsQ] = await Promise.all([
      query(
        `SELECT pd.full_name, oa.bukrs, TRIM(oa.kostl) AS kostl, oa.job_classification, ph.daily_hours
         FROM pa0002_personal_data pd
         JOIN pa0001_org_assignment oa ON oa.pernr = pd.pernr
         JOIN pa0007_planned_hours ph ON ph.pernr = pd.pernr
         WHERE pd.pernr = $1`,
        [pernr]
      ),
      query("SELECT bukrs, butxt AS name FROM t001_company_code ORDER BY bukrs"),
      query(`SELECT lgart, code, ltext AS name, unit, is_amount, needs_project, note_label, self_entry FROM t512w_wage_type ORDER BY lgart`),
      query(`SELECT c.bukrs, c.profile_code, p.is_clock_entry, p.fields_shown FROM ztime_company_cfg c
             JOIN ztime_profile p ON p.profile_code = c.profile_code
             WHERE c.begda <= CURRENT_DATE AND c.endda >= CURRENT_DATE ORDER BY c.bukrs`),
      query(
        `SELECT p.pspid, p.post1 AS name, p.bukrs, p.is_billable, p.budget_hours, p.responsible_pernr,
                mgr.full_name AS responsible_name, w.posid AS wbs, w.lstar
         FROM proj_project_definition p
         JOIN pa0002_personal_data mgr ON mgr.pernr = p.responsible_pernr
         LEFT JOIN prps_wbs_element w ON w.pspid = p.pspid
         ORDER BY CASE p.pspid
           WHEN 'BNK-2026' THEN 0 WHEN 'RTL-TT' THEN 1 WHEN 'AER-WFM' THEN 2
           WHEN 'AXI-INT' THEN 3 WHEN 'HSP-FAC' THEN 4 WHEN 'AER-FAC' THEN 5
           ELSE 99 END, p.pspid`
        // This fixed order matches app.js's original PROJECTS[] literal
        // exactly. Several call sites in app.js hardcode a project INDEX
        // (copyWeek's fallback template, applyMassAllow's "no project
        // needed" case, the sample suggestion overlay) rather than looking
        // a project up by code — same risk a hand-edited literal array
        // always had if entries were reordered. Matching the original
        // order here, instead of hunting down every such site, is the
        // lower-risk fix.
      ),
      query(
        `SELECT pd.pernr, pd.full_name AS name, oa.job_classification, oa.bukrs, ph.daily_hours,
                array_agg(tm.pspid ORDER BY tm.pspid) AS pspids
         FROM ztime_team_member tm
         JOIN pa0002_personal_data pd ON pd.pernr = tm.pernr
         JOIN pa0001_org_assignment oa ON oa.pernr = pd.pernr
         JOIN pa0007_planned_hours ph ON ph.pernr = pd.pernr
         GROUP BY pd.pernr, pd.full_name, oa.job_classification, oa.bukrs, ph.daily_hours
         ORDER BY pd.pernr`
      ),
      query(
        `SELECT a.approval_id, a.bukrs, pd.full_name AS who, oa.job_classification AS role, a.pspid,
                a.total_hours AS tot, a.in_project_hours AS inproj, a.deviation_hours AS dev,
                a.has_exception AS warn, a.exception_note AS note, a.approved
         FROM ztime_approval a
         JOIN pa0002_personal_data pd ON pd.pernr = a.pernr
         JOIN pa0001_org_assignment oa ON oa.pernr = a.pernr
         WHERE a.period_key = '2026-W38'
         ORDER BY a.bukrs, pd.full_name`
      ),
    ]);

    if (!employeeQ.rows.length) {
      return sendError(res, 404, "employee_not_found");
    }

    const pspidToIndex = {};
    const projects = projectsQ.rows.map((p, i) => {
      pspidToIndex[p.pspid] = i;
      return {
        code: p.pspid,
        wbs: p.wbs || "",
        name: p.name,
        act: p.wbs ? null /* filled below once activity types are known */ : "Administrative",
        proj: p.is_billable,
        bukrs: p.bukrs,
        budget: p.budget_hours !== null ? Number(p.budget_hours) : undefined,
        responsiblePernr: p.responsible_pernr,
        responsibleName: p.responsible_name,
        sap: {
          rproj: p.wbs || "",
          lstar: p.lstar || "ADMIN1",
          skostl: "PT4010", // see comment above buildWeeks: display-only, matches the mock's own fixed label
          rkostl: p.wbs ? "" : "PT4010",
          aufnr: "",
        },
      };
    });
    const noWbsIndex = projects.findIndex((p) => !p.wbs);
    const activityNames = await query("SELECT lstar, ltext FROM csla_activity_type");
    const actByLstar = Object.fromEntries(activityNames.rows.map((r) => [r.lstar, r.ltext]));
    projects.forEach((p) => {
      if (p.act === null) p.act = actByLstar[p.sap.lstar] || "";
    });

    const team = teamQ.rows.map((m) => ({
      pernr: m.pernr,
      name: m.name,
      role: m.job_classification,
      bukrs: m.bukrs,
      dailyHours: Number(m.daily_hours),
      projs: m.pspids.map((pspid) => pspidToIndex[pspid]).filter((i) => i !== undefined),
    }));

    const leadersByCompany = { PT01: [], PT02: [] };
    const byLeader = {};
    projects.forEach((p, i) => {
      if (!p.responsiblePernr) return;
      (byLeader[p.responsiblePernr] ||= { pernr: p.responsiblePernr, name: p.responsibleName, projs: [] }).projs.push(i);
    });
    const leaderCompany = {};
    const leaderBukrs = await query(
      `SELECT DISTINCT p.responsible_pernr AS pernr, oa.bukrs
       FROM proj_project_definition p
       JOIN pa0001_org_assignment oa ON oa.pernr = p.responsible_pernr`
    );
    leaderBukrs.rows.forEach((r) => { leaderCompany[r.pernr] = r.bukrs; });
    Object.values(byLeader).forEach((l) => {
      const bukrs = leaderCompany[l.pernr];
      l.label = l.projs.map((i) => projects[i].code).join(" + ");
      if (leadersByCompany[bukrs]) leadersByCompany[bukrs].push(l);
    });

    const companyKostl = { PT01: "PT4010", PT02: "PT4020" };
    const weeksByCompany = {};
    for (const bukrs of ["PT01", "PT02"]) {
      const kostl = companyKostl[bukrs];
      const hoursQ = await query(
        `SELECT c.catsdb_id, c.workdate, w.pspid, c.catshours AS hours, c.long_text AS desc, c.status, c.origin
         FROM catsdb c
         LEFT JOIN prps_wbs_element w ON w.posid = c.posid
         WHERE c.pernr = $1 AND c.lgart IS NULL AND c.awart IS NULL
           AND (w.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $2) OR TRIM(c.rkostl) = $3)
         ORDER BY c.workdate, c.catsdb_id`,
        [pernr, bukrs, kostl]
      );
      const allowQ = await query(
        `SELECT c.catsdb_id, c.workdate, w.pspid, wt.code AS wage_code, c.anzhl AS qty, c.catsamount AS amount,
                c.long_text AS note, c.status, c.created_by, c.on_behalf_of
         FROM catsdb c
         JOIN t512w_wage_type wt ON wt.lgart = c.lgart
         LEFT JOIN prps_wbs_element w ON w.posid = c.posid
         WHERE c.pernr = $1
           AND (w.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $2) OR TRIM(c.rkostl) = $3)
         ORDER BY c.workdate, c.catsdb_id`,
        [pernr, bukrs, kostl]
      );
      const absQ = await query(
        `SELECT a.pa2001_id, a.awart, t.atext AS awart_name, a.begda, a.endda, a.hours, a.status, a.request_number
         FROM pa2001_absences a JOIN t554t_absence_type t ON t.awart = a.awart
         WHERE a.pernr = $1
         ORDER BY a.begda`,
        [pernr]
      );
      weeksByCompany[bukrs] = buildWeeks(hoursQ.rows, allowQ.rows, absQ.rows, pspidToIndex, noWbsIndex);
    }

    const approvalsByCompany = { PT01: [], PT02: [] };
    approvalsQ.rows.forEach((a) => {
      approvalsByCompany[a.bukrs].push({
        approvalId: a.approval_id,
        who: a.who,
        role: a.role,
        proj: a.pspid,
        tot: Number(a.tot),
        inproj: Number(a.inproj),
        dev: Number(a.dev),
        warn: a.warn ? 1 : 0,
        note: a.note || undefined,
        sel: false,
        approved: a.approved,
      });
    });

    const emp = employeeQ.rows[0];
    res.status(200).json({
      pernr,
      employeeName: emp.full_name,
      employeeBukrs: emp.bukrs,
      dailyHours: Number(emp.daily_hours),
      companies: companiesQ.rows,
      wageTypes: wageTypesQ.rows.map((w) => ({
        code: w.code,
        lgart: w.lgart,
        name: w.name,
        unit: w.unit,
        amount: w.is_amount,
        needProj: w.needs_project,
        noteLabel: w.note_label || "",
        selfEntry: w.self_entry,
      })),
      profiles: Object.fromEntries(
        profilesQ.rows.map((p) => [p.profile_code, { code: p.profile_code, clock: p.is_clock_entry, overnight: p.is_clock_entry, fields: p.fields_shown }])
      ),
      companyProfileMap: Object.fromEntries(profilesQ.rows.map((p) => [p.bukrs, p.profile_code])),
      projects: projects.map(({ responsiblePernr, responsibleName, ...p }) => p),
      leadersByCompany,
      team,
      weeksByCompany,
      approvalsByCompany,
    });
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
