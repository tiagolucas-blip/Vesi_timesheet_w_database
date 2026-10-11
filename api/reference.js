/**
 * GET /api/reference
 * Static-ish master/customizing data every screen needs: companies, wage
 * types, absence types, activity types and the CATS entry profile per
 * company. Replaces app.js's COMPANIES, WAGETYPES, PROFILES and
 * ZTIME_COMPANY_CFG constants.
 */
import { query, sendError } from "./_db.js";

export default async function handler(req, res) {
  if (req.method !== "GET") {
    return sendError(res, 405, "method_not_allowed");
  }
  try {
    const [companies, wageTypes, absenceTypes, activityTypes, companyProfiles] = await Promise.all([
      query("SELECT bukrs, butxt AS name FROM t001_company_code ORDER BY bukrs"),
      query(`SELECT lgart, code, ltext AS name, unit, is_amount, needs_project, note_label, self_entry
             FROM t512w_wage_type ORDER BY lgart`),
      query("SELECT awart, atext AS name FROM t554t_absence_type ORDER BY awart"),
      query("SELECT lstar, ltext AS name FROM csla_activity_type ORDER BY lstar"),
      query(`SELECT c.bukrs, c.profile_code, p.is_clock_entry, p.fields_shown
             FROM ztime_company_cfg c
             JOIN ztime_profile p ON p.profile_code = c.profile_code
             WHERE c.begda <= CURRENT_DATE AND c.endda >= CURRENT_DATE
             ORDER BY c.bukrs`),
    ]);
    res.status(200).json({
      companies: companies.rows,
      wageTypes: wageTypes.rows,
      absenceTypes: absenceTypes.rows,
      activityTypes: activityTypes.rows,
      companyProfiles: companyProfiles.rows,
    });
  } catch (err) {
    sendError(res, 500, "query_failed", err.message);
  }
}
