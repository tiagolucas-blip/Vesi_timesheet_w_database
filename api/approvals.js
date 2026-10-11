/**
 * GET  /api/approvals?bukrs=PT01&period=2026-W38
 *   The approval queue for a company/period, from ztime_approval. Replaces
 *   app.js's APPROVALS_PT01/APPROVALS_PT02.
 * POST /api/approvals  { ids:[...], approverPernr }  (approve one or many)
 *   Marks the queue entries approved. Real SAP would also flip the
 *   underlying CATSDB rows' STATUS to APPROVED; out of scope for this
 *   sample queue table (see SCHEMA.md).
 */
import { query, sendError } from "./_db.js";

export default async function handler(req, res) {
  if (req.method === "GET") {
    const { bukrs, period } = req.query;
    if (!bukrs || !period) {
      return sendError(res, 400, "bukrs_and_period_required");
    }
    try {
      const result = await query(
        `SELECT a.approval_id, a.pernr, pd.full_name AS who, oa.job_classification AS role,
                a.pspid, a.total_hours, a.in_project_hours, a.deviation_hours,
                a.has_exception, a.exception_note, a.approved, a.approver_pernr, a.approved_at
         FROM ztime_approval a
         JOIN pa0002_personal_data pd ON pd.pernr = a.pernr
         JOIN pa0001_org_assignment oa ON oa.pernr = a.pernr
         WHERE a.bukrs = $1 AND a.period_key = $2
         ORDER BY pd.full_name`,
        [bukrs, period]
      );
      res.status(200).json(result.rows);
    } catch (err) {
      sendError(res, 500, "query_failed", err.message);
    }
    return;
  }

  if (req.method === "POST") {
    const { ids = [], approverPernr } = req.body || {};
    if (!ids.length || !approverPernr) {
      return sendError(res, 400, "ids_and_approverPernr_required");
    }
    try {
      const result = await query(
        `UPDATE ztime_approval SET approved = TRUE, approver_pernr = $1, approved_at = now()
         WHERE approval_id = ANY($2) AND approved = FALSE
         RETURNING approval_id`,
        [approverPernr, ids]
      );
      res.status(200).json({ approved: result.rows.map((r) => r.approval_id) });
    } catch (err) {
      sendError(res, 500, "query_failed", err.message);
    }
    return;
  }

  sendError(res, 405, "method_not_allowed");
}
