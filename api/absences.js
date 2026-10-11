/**
 * GET /api/absences?pernr=00104567
 * All absences for a person, from PA2001, read-only (the Leave Request
 * system of record is outside this app). Replaces app.js's per-week
 * ABSENCES[] slices.
 */
import { query, sendError } from "./_db.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return sendError(res, 405, "method_not_allowed");
  }
  const { pernr } = req.query;
  if (!pernr) {
    return sendError(res, 400, "pernr_required");
  }
  try {
    const result = await query(
      `SELECT a.pa2001_id, a.awart, t.atext AS awart_name, a.begda, a.endda,
              a.hours, a.status, a.request_number
       FROM pa2001_absences a
       JOIN t554t_absence_type t ON t.awart = a.awart
       WHERE a.pernr = $1
       ORDER BY a.begda`,
      [pernr]
    );
    res.status(200).json(result.rows);
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
