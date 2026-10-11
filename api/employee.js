/**
 * GET /api/employee?pernr=00104567
 * One employee's identity + org assignment + planned hours, joined from
 * PA0002/PA0001/PA0007. Replaces app.js's EMPLOYEE_NAME/PERNR/IT0001/
 * DAYCAP constants and each TEAM[] member's name/role/bukrs/dailyHours.
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
      `SELECT pd.pernr, pd.first_name, pd.last_name, pd.full_name,
              oa.bukrs, TRIM(oa.kostl) AS kostl, oa.job_classification,
              ph.daily_hours
       FROM pa0002_personal_data pd
       JOIN pa0001_org_assignment oa ON oa.pernr = pd.pernr
       JOIN pa0007_planned_hours ph ON ph.pernr = pd.pernr
       WHERE pd.pernr = $1`,
      [pernr]
    );
    if (!result.rows.length) {
      return sendError(res, 404, "employee_not_found");
    }
    res.status(200).json(result.rows[0]);
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
