/**
 * GET /api/projects?bukrs=PT01
 * Projects for a company (plus shared ones with no bukrs), their WBS
 * element and receiver object, and the manager's name — all sourced from
 * PROJ/PRPS, with the manager coming straight from
 * proj_project_definition.responsible_pernr (see SCHEMA.md). Replaces
 * app.js's PROJECTS[] and part of LEADERS[].
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
      `SELECT p.pspid, p.post1 AS name, p.bukrs, p.is_billable, p.budget_hours,
              p.responsible_pernr, mgr.full_name AS responsible_name,
              w.posid AS wbs, w.lstar, TRIM(w.skostl) AS skostl,
              CASE WHEN w.posid IS NULL THEN TRIM(rc.kostl) END AS direct_kostl
       FROM proj_project_definition p
       JOIN pa0002_personal_data mgr ON mgr.pernr = p.responsible_pernr
       LEFT JOIN prps_wbs_element w ON w.pspid = p.pspid
       LEFT JOIN csks_cost_center rc ON rc.bukrs = $1 AND w.posid IS NULL
       WHERE p.bukrs = $1 OR p.bukrs IS NULL
       ORDER BY p.pspid`,
      [bukrs]
    );
    res.status(200).json(result.rows);
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
