/**
 * GET /api/team?pspid=BNK-2026&weekStart=2026-09-14
 * The mass-entry roster for a project: its manager (straight from
 * proj_project_definition.responsible_pernr) and every ztime_team_member,
 * each with their already-recorded hours that week across ALL their
 * projects (not just this one) — same notion as app.js's alreadyHoursFor.
 * Replaces LEADERS[]/TEAM[] for the Team screen.
 */
import { query, weekDates, sendError } from "./_db.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return sendError(res, 405, "method_not_allowed");
  }
  const { pspid, weekStart } = req.query;
  if (!pspid || !weekStart) {
    return sendError(res, 400, "pspid_and_weekStart_required");
  }
  const dates = weekDates(weekStart);
  const [monday, sunday] = [dates[0], dates[6]];

  try {
    const project = await query(
      `SELECT p.pspid, p.post1 AS name, p.bukrs, p.responsible_pernr, mgr.full_name AS responsible_name
       FROM proj_project_definition p
       JOIN pa0002_personal_data mgr ON mgr.pernr = p.responsible_pernr
       WHERE p.pspid = $1`,
      [pspid]
    );
    if (!project.rows.length) {
      return sendError(res, 404, "project_not_found");
    }

    const members = await query(
      `SELECT pd.pernr, pd.full_name AS name, oa.job_classification, ph.daily_hours
       FROM ztime_team_member tm
       JOIN pa0002_personal_data pd ON pd.pernr = tm.pernr
       JOIN pa0001_org_assignment oa ON oa.pernr = pd.pernr
       JOIN pa0007_planned_hours ph ON ph.pernr = pd.pernr
       WHERE tm.pspid = $1
       ORDER BY pd.pernr`,
      [pspid]
    );

    const already = await query(
      `SELECT pernr, workdate, SUM(catshours) AS hours
       FROM catsdb
       WHERE pernr = ANY($1) AND workdate BETWEEN $2 AND $3 AND lgart IS NULL AND awart IS NULL
       GROUP BY pernr, workdate`,
      [members.rows.map((m) => m.pernr), monday, sunday]
    );
    const byPernr = {};
    already.rows.forEach((r) => {
      (byPernr[r.pernr] ||= {})[r.workdate.toISOString().slice(0, 10)] = Number(r.hours);
    });

    const result = members.rows.map((m) => ({
      ...m,
      alreadyHours: dates.map((d) => (byPernr[m.pernr] && byPernr[m.pernr][d]) || 0),
    }));

    res.status(200).json({ project: project.rows[0], dates, members: result });
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
