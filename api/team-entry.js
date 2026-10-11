/**
 * POST /api/team-entry
 * { actingAsPernr, pspid, lstar, entries: [{pernr, workdate, hours, desc, origin}] }
 * or { actingAsPernr, pspid, allow: [{pernr, workdate, lgart, qty, amount, note}] }
 *
 * Mass entry for a leader's team (Team screen): stages new catsdb rows for
 * several people at once, on_behalf_of the person entered, created_by the
 * leader acting. Entries add to whatever is already saved for that
 * person/day — real CATS allows several line items per day — so this
 * never deletes existing rows the way the personal Save does.
 */
import { query, withTransaction, sendError } from "./_db.js";

const LOCKED_STATUSES = ["SUBMITTED", "APPROVED", "TRANSFERRED"];

export default async function handler(req, res) {
  if (req.method !== "POST") {
    return sendError(res, 405, "method_not_allowed");
  }
  const { actingAsPernr, pspid, rkostl, lstar, entries = [], allow = [] } = req.body || {};
  if (!actingAsPernr || (!pspid && !rkostl) || (!entries.length && !allow.length)) {
    return sendError(res, 400, "missing_fields");
  }
  const pernrs = [...new Set([...entries, ...allow].map((e) => e.pernr))];
  const dates = [...new Set([...entries, ...allow].map((e) => e.workdate))];

  try {
    await withTransaction(async (client) => {
      const locked = await client.query(
        `SELECT pernr, workdate FROM catsdb
         WHERE pernr = ANY($1) AND workdate = ANY($2) AND status = ANY($3)`,
        [pernrs, dates, LOCKED_STATUSES]
      );
      if (locked.rows.length) {
        throw Object.assign(new Error("day_locked"), { httpStatus: 409, rows: locked.rows });
      }
      for (const e of entries) {
        if (!e.hours) continue;
        await client.query(
          `INSERT INTO catsdb (pernr, workdate, posid, rkostl, lstar, catshours, long_text, status, origin, created_by, on_behalf_of)
           VALUES ($1,$2,$3,$4,$5,$6,$7,'SAVED',$8,$9,$1)`,
          [e.pernr, e.workdate, pspid || null, rkostl || null, lstar || null, e.hours, e.desc || null, e.origin || "Manual", actingAsPernr]
        );
      }
      for (const a of allow) {
        await client.query(
          `INSERT INTO catsdb (pernr, workdate, posid, rkostl, lgart, anzhl, catsamount, long_text, status, origin, created_by, on_behalf_of)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8,'SAVED','Manual',$9,$1)`,
          [a.pernr, a.workdate, pspid || null, rkostl || null, a.lgart, a.qty || null, a.amount || null, a.note || null, actingAsPernr]
        );
      }
    });
    res.status(200).json({ staged: entries.length + allow.length });
  } catch (err) {
    if (err.httpStatus === 409) return res.status(409).json({ error: "day_locked", rows: err.rows });
    sendError(res, 500, "query_failed", err.message);
  }
}
