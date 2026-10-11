/**
 * GET  /api/timesheet?pernr=00104567&start=2026-09-14&bukrs=PT01
 *   One person's week (Monday start), straight off CATSDB/PA2001: hours
 *   rows, allowance/bonus rows and absences overlapping the week, plus a
 *   derived "submitted" flag. Replaces app.js's WEEKS_PT01/WEEKS_PT02
 *   entries and ABSENCES for that week.
 *
 * POST /api/timesheet  { pernr, weekStart, bukrs, hours:[...], allow:[...] }
 *   Replaces the week's own hours+allowance rows (Save). Refuses if the
 *   week is already submitted/approved/transferred — "Save obrigatório
 *   antes do Submit" still means the DB, not just the UI, protects a
 *   released week from a stray save.
 *
 * bukrs is required on both: PT01 and PT02 weeks can share the exact same
 * calendar dates (same person, two company "views" of their own
 * timesheet — see SCHEMA.md/api/bootstrap.js), so every query here is
 * scoped to rows whose receiver actually belongs to that company — a WBS
 * element under a project with that bukrs, or a direct cost-center
 * booking using that company's own cost center — never by date range
 * alone. Saving one company's week must never touch the other's rows for
 * the same dates.
 */
import { query, withTransaction, weekDates, sendError } from "./_db.js";

const LOCKED_STATUSES = ["SUBMITTED", "APPROVED", "TRANSFERRED"];
const COMPANY_KOSTL = { PT01: "PT4010", PT02: "PT4020" };

function receiverScopeSql(paramIndexBukrs, paramIndexKostl) {
  return `(w.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $${paramIndexBukrs})
           OR TRIM(c.rkostl) = $${paramIndexKostl})`;
}

async function getWeek(pernr, weekStart, bukrs) {
  const dates = weekDates(weekStart);
  const [monday, sunday] = [dates[0], dates[6]];
  const kostl = COMPANY_KOSTL[bukrs];

  const hours = await query(
    `SELECT c.catsdb_id, c.workdate, c.posid AS wbs, w.pspid, p.post1 AS pspid_name,
            TRIM(c.rkostl) AS rkostl, ck.ktext AS rkostl_name, c.lstar, c.catshours AS hours,
            c.long_text AS desc, c.status, c.origin
     FROM catsdb c
     LEFT JOIN prps_wbs_element w ON w.posid = c.posid
     LEFT JOIN proj_project_definition p ON p.pspid = w.pspid
     LEFT JOIN csks_cost_center ck ON ck.kostl = c.rkostl
     WHERE c.pernr = $1 AND c.workdate BETWEEN $2 AND $3
       AND c.lgart IS NULL AND c.awart IS NULL
       AND ${receiverScopeSql(4, 5)}
     ORDER BY c.workdate, c.catsdb_id`,
    [pernr, monday, sunday, bukrs, kostl]
  );

  const allow = await query(
    `SELECT c.catsdb_id, c.workdate, c.posid AS wbs, w2.pspid, p.post1 AS pspid_name,
            TRIM(c.rkostl) AS rkostl, w.code AS wage_code, w.ltext AS wage_name, w.unit,
            c.anzhl AS qty, c.catsamount AS amount, c.long_text AS note,
            c.status, c.created_by, c.on_behalf_of
     FROM catsdb c
     JOIN t512w_wage_type w ON w.lgart = c.lgart
     LEFT JOIN prps_wbs_element w2 ON w2.posid = c.posid
     LEFT JOIN proj_project_definition p ON p.pspid = w2.pspid
     WHERE c.pernr = $1 AND c.workdate BETWEEN $2 AND $3 AND c.lgart IS NOT NULL
       AND (w2.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $4) OR TRIM(c.rkostl) = $5)
     ORDER BY c.workdate, c.catsdb_id`,
    [pernr, monday, sunday, bukrs, kostl]
  );

  const absences = await query(
    `SELECT a.pa2001_id, a.awart, t.atext AS awart_name, a.begda, a.endda,
            a.hours, a.status, a.request_number
     FROM pa2001_absences a
     JOIN t554t_absence_type t ON t.awart = a.awart
     WHERE a.pernr = $1 AND a.begda <= $3 AND a.endda >= $2
     ORDER BY a.begda`,
    [pernr, monday, sunday]
  );

  const anyRow = hours.rows.length > 0 || allow.rows.length > 0;
  const allLocked = anyRow && [...hours.rows, ...allow.rows].every((r) => LOCKED_STATUSES.includes(r.status));
  // A week with no rows at all (every working day fully absent) counts as
  // submitted only when every Mon-Fri date is covered by an approved absence.
  const weekdays = dates.slice(0, 5);
  const fullyAbsent =
    !anyRow &&
    weekdays.every((d) => absences.rows.some((a) => a.status === "approved" && a.begda <= d && a.endda >= d));
  const submitted = allLocked || fullyAbsent;

  return { weekStart: monday, dates, submitted, hours: hours.rows, allow: allow.rows, absences: absences.rows };
}

export default async function handler(req, res) {
  const { pernr, start, bukrs } = req.query;

  if (req.method === "GET") {
    if (!pernr || !start || !bukrs) {
      return sendError(res, 400, "pernr_start_and_bukrs_required");
    }
    try {
      res.status(200).json(await getWeek(pernr, start, bukrs));
    } catch (err) {
      sendError(res, 500, "query_failed", err.message);
    }
    return;
  }

  if (req.method === "POST") {
    const body = req.body || {};
    const { pernr: bodyPernr, weekStart, bukrs: bodyBukrs, hours = [], allow = [] } = body;
    if (!bodyPernr || !weekStart || !bodyBukrs) {
      return sendError(res, 400, "pernr_weekStart_and_bukrs_required");
    }
    const dates = weekDates(weekStart);
    const [monday, sunday] = [dates[0], dates[6]];
    const kostl = COMPANY_KOSTL[bodyBukrs];
    try {
      await withTransaction(async (client) => {
        const existing = await client.query(
          `SELECT c.status FROM catsdb c
           LEFT JOIN prps_wbs_element w ON w.posid = c.posid
           WHERE c.pernr = $1 AND c.workdate BETWEEN $2 AND $3
             AND ${receiverScopeSql(4, 5)}`,
          [bodyPernr, monday, sunday, bodyBukrs, kostl]
        );
        if (existing.rows.some((r) => LOCKED_STATUSES.includes(r.status))) {
          throw Object.assign(new Error("week_locked"), { httpStatus: 409 });
        }
        await client.query(
          `DELETE FROM catsdb c
           USING (SELECT catsdb_id FROM catsdb c2
                  LEFT JOIN prps_wbs_element w ON w.posid = c2.posid
                  WHERE c2.pernr = $1 AND c2.workdate BETWEEN $2 AND $3
                    AND (w.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $4) OR TRIM(c2.rkostl) = $5)
                 ) del
           WHERE c.catsdb_id = del.catsdb_id`,
          [bodyPernr, monday, sunday, bodyBukrs, kostl]
        );
        for (const r of hours) {
          if (!r.hours) continue;
          await client.query(
            `INSERT INTO catsdb (pernr, workdate, posid, rkostl, lstar, catshours, long_text, status, origin, created_by, on_behalf_of)
             VALUES ($1,$2,$3,$4,$5,$6,$7,'SAVED',$8,$1,$1)`,
            [bodyPernr, r.workdate, r.pspid || null, r.rkostl || null, r.lstar || null, r.hours, r.desc || null, r.origin || "Manual"]
          );
        }
        for (const a of allow) {
          await client.query(
            `INSERT INTO catsdb (pernr, workdate, posid, rkostl, lgart, anzhl, catsamount, long_text, status, origin, created_by, on_behalf_of)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'SAVED','Manual',$1,$1)`,
            [bodyPernr, a.workdate, a.pspid || null, a.rkostl || null, a.lgart, a.qty || null, a.amount || null, a.note || null]
          );
        }
      });
      res.status(200).json(await getWeek(bodyPernr, weekStart, bodyBukrs));
    } catch (err) {
      if (err.httpStatus === 409) return sendError(res, 409, "week_locked");
      sendError(res, 500, "query_failed", err.message);
    }
    return;
  }

  sendError(res, 405, "method_not_allowed");
}
