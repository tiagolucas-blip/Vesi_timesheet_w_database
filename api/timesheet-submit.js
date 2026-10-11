/**
 * POST /api/timesheet-submit  { pernr, weekStart, bukrs }
 * Releases a saved week for approval: SAVED -> SUBMITTED on every hours/
 * allowance row in that week. Refuses if any row is missing (nothing
 * saved yet) or already past SAVED — "Save obrigatório antes do Submit"
 * enforced in the database, not just the UI.
 *
 * bukrs is required for the same reason as in api/timesheet.js: PT01 and
 * PT02 weeks can share the exact same calendar dates, so every query here
 * is scoped to rows whose receiver belongs to that company, never by
 * date range alone — otherwise submitting one company's week would also
 * flip the other's same-dated rows to SUBMITTED.
 */
import { query, weekDates, sendError } from "./_db.js";

const COMPANY_KOSTL = { PT01: "PT4010", PT02: "PT4020" };

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendError(res, 405, "method_not_allowed");
  }
  const { pernr, weekStart, bukrs } = req.body || {};
  if (!pernr || !weekStart || !bukrs) {
    return sendError(res, 400, "pernr_weekStart_and_bukrs_required");
  }
  const dates = weekDates(weekStart);
  const [monday, sunday] = [dates[0], dates[6]];
  const kostl = COMPANY_KOSTL[bukrs];
  try {
    const existing = await query(
      `SELECT c.catsdb_id, c.status FROM catsdb c
       LEFT JOIN prps_wbs_element w ON w.posid = c.posid
       WHERE c.pernr = $1 AND c.workdate BETWEEN $2 AND $3
         AND (w.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $4) OR TRIM(c.rkostl) = $5)`,
      [pernr, monday, sunday, bukrs, kostl]
    );
    if (!existing.rows.length) {
      return sendError(res, 409, "nothing_saved");
    }
    if (existing.rows.some((r) => r.status !== "SAVED")) {
      return sendError(res, 409, "not_all_saved");
    }
    await query(
      `UPDATE catsdb c SET status = 'SUBMITTED', changed_at = now()
       FROM (SELECT catsdb_id FROM catsdb c2
             LEFT JOIN prps_wbs_element w ON w.posid = c2.posid
             WHERE c2.pernr = $1 AND c2.workdate BETWEEN $2 AND $3
               AND (w.pspid IN (SELECT pspid FROM proj_project_definition WHERE bukrs = $4) OR TRIM(c2.rkostl) = $5)
            ) upd
       WHERE c.catsdb_id = upd.catsdb_id`,
      [pernr, monday, sunday, bukrs, kostl]
    );
    res.status(200).json({ submitted: true });
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
