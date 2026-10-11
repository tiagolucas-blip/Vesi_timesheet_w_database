/**
 * POST /api/timesheet-submit  { pernr, weekStart }
 * Releases a saved week for approval: SAVED -> SUBMITTED on every hours/
 * allowance row in that week. Refuses if any row is missing (nothing
 * saved yet) or already past SAVED — "Save obrigatório antes do Submit"
 * enforced in the database, not just the UI.
 */
import { query, weekDates, sendError } from "./_db.js";

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendError(res, 405, "method_not_allowed");
  }
  const { pernr, weekStart } = req.body || {};
  if (!pernr || !weekStart) {
    return sendError(res, 400, "pernr_and_weekStart_required");
  }
  const dates = weekDates(weekStart);
  const [monday, sunday] = [dates[0], dates[6]];
  try {
    const existing = await query(`SELECT catsdb_id, status FROM catsdb WHERE pernr = $1 AND workdate BETWEEN $2 AND $3`, [
      pernr,
      monday,
      sunday,
    ]);
    if (!existing.rows.length) {
      return sendError(res, 409, "nothing_saved");
    }
    if (existing.rows.some((r) => r.status !== "SAVED")) {
      return sendError(res, 409, "not_all_saved");
    }
    await query(`UPDATE catsdb SET status = 'SUBMITTED', changed_at = now() WHERE pernr = $1 AND workdate BETWEEN $2 AND $3`, [
      pernr,
      monday,
      sunday,
    ]);
    res.status(200).json({ submitted: true });
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
