/**
 * GET /api/leaders?bukrs=PT01
 * The "Acting as" list for the Team screen: every person who manages at
 * least one project in this company, derived straight from
 * proj_project_definition.responsible_pernr (see SCHEMA.md) — no stored
 * leader roster. Replaces app.js's LEADERS[]/leadersForCompany().
 */
import { query, sendError } from "./_db.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return sendError(res, 405, "method_not_allowed");
  }
  const { bukrs } = req.query;
  if (!bukrs) {
    return sendError(res, 400, "bukrs_required");
  }
  try {
    const result = await query(
      `SELECT p.responsible_pernr AS pernr, mgr.full_name AS name,
              string_agg(p.pspid, ' + ' ORDER BY p.pspid) AS label,
              array_agg(p.pspid ORDER BY p.pspid) AS pspids
       FROM proj_project_definition p
       JOIN pa0001_org_assignment oa ON oa.pernr = p.responsible_pernr
       JOIN pa0002_personal_data mgr ON mgr.pernr = p.responsible_pernr
       WHERE oa.bukrs = $1
       GROUP BY p.responsible_pernr, mgr.full_name
       ORDER BY mgr.full_name`,
      [bukrs]
    );
    res.status(200).json(result.rows);
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
