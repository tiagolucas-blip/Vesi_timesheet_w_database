-- ============================================================================
-- Seed data for vesi-timesheet-erp, transcribed from vesi_timesheet's app.js
-- mock arrays (PROJECTS, COMPANIES, WAGETYPES, LEADERS, TEAM, WEEKS_PT01,
-- WEEKS_PT02, APPROVALS_PT01/PT02). All data fictional (see ../README.md).
-- Run after schema.sql, in a fresh database: psql -f schema.sql -f seed.sql
-- ============================================================================

-- Companies (COMPANIES)
INSERT INTO t001_company_code (bukrs, butxt, land1) VALUES
  ('PT01', 'Consulting and digital services', 'PT'),
  ('PT02', 'Building solutions and maintenance', 'PT');

-- Cost centers. The mock data uses a single 'PT4010' string for both
-- companies; a real cost center belongs to exactly one company code, so
-- this seed splits it into PT4010 (PT01) and PT4020 (PT02) — see SCHEMA.md.
INSERT INTO csks_cost_center (kostl, bukrs, ktext) VALUES
  ('PT4010', 'PT01', 'Consulting delivery'),
  ('PT4020', 'PT02', 'Facilities delivery');

-- Activity types (CSLA), text reused from PROJECTS[].act in the mock
INSERT INTO csla_activity_type (lstar, ltext) VALUES
  ('CONS01', 'Functional consulting'),
  ('PMGT01', 'Project management'),
  ('MAINT1', 'Field service'),
  ('ADMIN1', 'Administrative');

-- Absence types (T554T) — the two AWART codes used in the mock absences
INSERT INTO t554t_absence_type (awart, atext) VALUES
  ('0100', 'Vacation'),
  ('0210', 'Medical appointment');

-- Wage types (T512W/T512T), from WAGETYPES
INSERT INTO t512w_wage_type (lgart, code, ltext, unit, is_amount, needs_project, note_label, self_entry) VALUES
  ('1200', 'AJC_NAC', 'Domestic per diem', 'days', FALSE, TRUE, '', TRUE),
  ('1210', 'AJC_INT', 'Foreign per diem', 'days', FALSE, TRUE, 'Country', TRUE),
  ('1300', 'KMS', 'Own-car kilometres', 'km', FALSE, TRUE, 'Origin and destination', TRUE),
  ('1500', 'TURNO', 'Shift allowance', 'days', FALSE, FALSE, '', TRUE),
  ('1400', 'BONUS', 'Project bonus', 'amount', TRUE, TRUE, 'Reason', FALSE);

-- People: the self-service user, the 5 mass-entry leaders, the 29-person
-- team roster (TEAM) and 5 names that only ever appear in the sample
-- Approval queue (APPROVALS_PT01), not in TEAM or LEADERS.
INSERT INTO pa0002_personal_data (pernr, first_name, last_name) VALUES
  ('00104567', 'Tiago', 'Leal'),
  ('00104506', 'Ricardo', 'Nunes'),
  ('00104507', 'Pedro', 'Alves'),
  ('00104508', 'Ana', 'Ferreira'),
  ('00104509', 'Carlos', 'Pinto'),
  ('00104522', 'Marco', 'Silva'),
  ('00104501', 'Marta', 'Silva'),
  ('00104504', 'Rui', 'Tavares'),
  ('00104513', 'Beatriz', 'Costa'),
  ('00104514', 'Tiago', 'Almeida'),
  ('00104515', 'Mariana', 'Neves'),
  ('00104502', 'João', 'Costa'),
  ('00104503', 'Inês', 'Braga'),
  ('00104516', 'Vera', 'Antunes'),
  ('00104517', 'Gonçalo', 'Pinheiro'),
  ('00104518', 'Teresa', 'Correia'),
  ('00104505', 'Sofia', 'Marques'),
  ('00104519', 'Vasco', 'Pereira'),
  ('00104520', 'Miguel', 'Santos'),
  ('00104521', 'Rita', 'Nunes'),
  ('00104523', 'Bárbara', 'Moreira'),
  ('00104524', 'Eduardo', 'Cardoso'),
  ('00104525', 'Sara', 'Martins'),
  ('00104526', 'Cláudia', 'Ribeiro'),
  ('00104527', 'Diogo', 'Ferreira'),
  ('00104510', 'Nuno', 'Dias'),
  ('00104511', 'Hélder', 'Rocha'),
  ('00104512', 'Hugo', 'Matos'),
  ('00104528', 'Luís', 'Teixeira'),
  ('00104529', 'Sandra', 'Fonseca'),
  ('00104530', 'Ana', 'Pires'),
  ('00104531', 'Bruno', 'Alves'),
  ('00104532', 'Carla', 'Sousa'),
  ('00104533', 'Daniel', 'Matos'),
  ('00104534', 'Elsa', 'Carvalho'),
  ('00104540', 'Bruno', 'Matos'),
  ('00104541', 'Carla', 'Nunes'),
  ('00104542', 'Diogo', 'Sousa'),
  ('00104543', 'Eva', 'Lopes'),
  ('00104544', 'Filipe', 'Reis');

INSERT INTO pa0001_org_assignment (pernr, bukrs, kostl, job_classification, begda) VALUES
  ('00104567', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104506', 'PT01', 'PT4010', 'Senior consultant', '2020-01-01'),
  ('00104507', 'PT01', 'PT4010', 'Senior consultant', '2020-01-01'),
  ('00104508', 'PT01', 'PT4010', 'Senior consultant', '2020-01-01'),
  ('00104509', 'PT02', 'PT4020', 'Senior technician', '2020-01-01'),
  ('00104522', 'PT02', 'PT4020', 'Senior technician', '2020-01-01'),
  ('00104501', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104504', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104513', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104514', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104515', 'PT01', 'PT4010', 'Junior consultant', '2020-01-01'),
  ('00104502', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104503', 'PT01', 'PT4010', 'Junior consultant', '2020-01-01'),
  ('00104516', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104517', 'PT01', 'PT4010', 'Senior consultant', '2020-01-01'),
  ('00104518', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104505', 'PT01', 'PT4010', 'Architect', '2020-01-01'),
  ('00104519', 'PT01', 'PT4010', 'Architect', '2020-01-01'),
  ('00104520', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104521', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104523', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104524', 'PT01', 'PT4010', 'Junior consultant', '2020-01-01'),
  ('00104525', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104526', 'PT01', 'PT4010', 'Architect', '2020-01-01'),
  ('00104527', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104510', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104511', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104512', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104528', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104529', 'PT02', 'PT4020', 'Senior technician', '2020-01-01'),
  ('00104530', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104531', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104532', 'PT02', 'PT4020', 'Senior technician', '2020-01-01'),
  ('00104533', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104534', 'PT02', 'PT4020', 'Technician', '2020-01-01'),
  ('00104540', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104541', 'PT01', 'PT4010', 'Consultant', '2020-01-01'),
  ('00104542', 'PT01', 'PT4010', 'Junior consultant', '2020-01-01'),
  ('00104543', 'PT01', 'PT4010', 'Architect', '2020-01-01'),
  ('00104544', 'PT01', 'PT4010', 'Consultant', '2020-01-01');

INSERT INTO pa0007_planned_hours (pernr, daily_hours, begda) VALUES
  ('00104567', 8, '2020-01-01'),
  ('00104506', 8, '2020-01-01'),
  ('00104507', 8, '2020-01-01'),
  ('00104508', 8, '2020-01-01'),
  ('00104509', 8, '2020-01-01'),
  ('00104522', 8, '2020-01-01'),
  ('00104501', 8, '2020-01-01'),
  ('00104504', 8, '2020-01-01'),
  ('00104513', 6, '2020-01-01'),
  ('00104514', 8, '2020-01-01'),
  ('00104515', 8, '2020-01-01'),
  ('00104502', 8, '2020-01-01'),
  ('00104503', 8, '2020-01-01'),
  ('00104516', 8, '2020-01-01'),
  ('00104517', 8, '2020-01-01'),
  ('00104518', 8, '2020-01-01'),
  ('00104505', 8, '2020-01-01'),
  ('00104519', 8, '2020-01-01'),
  ('00104520', 8, '2020-01-01'),
  ('00104521', 8, '2020-01-01'),
  ('00104523', 8, '2020-01-01'),
  ('00104524', 8, '2020-01-01'),
  ('00104525', 8, '2020-01-01'),
  ('00104526', 8, '2020-01-01'),
  ('00104527', 8, '2020-01-01'),
  ('00104510', 8, '2020-01-01'),
  ('00104511', 6, '2020-01-01'),
  ('00104512', 8, '2020-01-01'),
  ('00104528', 8, '2020-01-01'),
  ('00104529', 8, '2020-01-01'),
  ('00104530', 8, '2020-01-01'),
  ('00104531', 8, '2020-01-01'),
  ('00104532', 8, '2020-01-01'),
  ('00104533', 6, '2020-01-01'),
  ('00104534', 8, '2020-01-01'),
  ('00104540', 8, '2020-01-01'),
  ('00104541', 8, '2020-01-01'),
  ('00104542', 8, '2020-01-01'),
  ('00104543', 8, '2020-01-01'),
  ('00104544', 8, '2020-01-01');

-- Projects (PROJ), from PROJECTS
INSERT INTO proj_project_definition (pspid, post1, bukrs, is_billable, budget_hours, responsible_pernr) VALUES
  ('BNK-2026', 'Banking, Payroll and ECP', 'PT01', TRUE, 480, '00104508'),
  ('RTL-TT', 'Retail, Time Tracking', 'PT01', TRUE, 360, '00104506'),
  ('AER-WFM', 'Airports, WFM rollout', 'PT01', TRUE, 600, '00104507'),
  ('AXI-INT', 'Internal, pre-sales and training', NULL, FALSE, NULL, '00104506'),
  ('HSP-FAC', 'Hospital campus, facilities maintenance', 'PT02', TRUE, 300, '00104509'),
  ('AER-FAC', 'Airport terminal, facilities maintenance', 'PT02', TRUE, 260, '00104522');

-- WBS elements (PRPS). AXI-INT has none at all — it books straight to a
-- cost center on each catsdb row (rkostl), never through a PSPNR.
INSERT INTO prps_wbs_element (posid, pspid, post1, lstar, skostl) VALUES
  ('BNK-2026.1.3', 'BNK-2026', 'Functional consulting', 'CONS01', 'PT4010'),
  ('RTL-TT.2.1', 'RTL-TT', 'Functional consulting', 'CONS01', 'PT4010'),
  ('AER-WFM.4.2', 'AER-WFM', 'Project management', 'PMGT01', 'PT4010'),
  ('HSP-FAC.1.1', 'HSP-FAC', 'Field service', 'MAINT1', 'PT4020'),
  ('AER-FAC.2.1', 'AER-FAC', 'Field service', 'MAINT1', 'PT4020');

-- CATS data entry profiles (ZTIME_PROFILE), from PROFILES
INSERT INTO ztime_profile (profile_code, is_clock_entry, fields_shown) VALUES
  ('Z_CONS', FALSE, 'Date, project, duration'),
  ('Z_BSRV', TRUE, 'Date, project, start, end, computed duration');

-- Company -> profile mapping (ZTIME_COMPANY_CFG), from ZTIME_COMPANY_CFG
INSERT INTO ztime_company_cfg (bukrs, profile_code, begda) VALUES
  ('PT01', 'Z_CONS', '2020-01-01'),
  ('PT02', 'Z_BSRV', '2020-01-01');

-- Mass-entry leader roster (ZTIME_LEADER/ZTIME_LEADER_PROJECT), from LEADERS
INSERT INTO ztime_leader (leader_id, pernr, label, bukrs) VALUES
  ('RN', '00104506', 'RTL-TT + AXI-INT', 'PT01'),
  ('PA', '00104507', 'AER-WFM', 'PT01'),
  ('AF', '00104508', 'BNK-2026', 'PT01'),
  ('CP', '00104509', 'HSP-FAC', 'PT02'),
  ('MS', '00104522', 'AER-FAC', 'PT02');

INSERT INTO ztime_leader_project (leader_id, pspid) VALUES
  ('RN', 'RTL-TT'),
  ('RN', 'AXI-INT'),
  ('PA', 'AER-WFM'),
  ('AF', 'BNK-2026'),
  ('CP', 'HSP-FAC'),
  ('MS', 'AER-FAC');

-- Team membership for mass entry (ZTIME_TEAM_MEMBER), from TEAM[].projs
-- (project index -> owning leader). Rui Tavares has two rows: he works on
-- both Ana Ferreira's and Pedro Alves's projects, the mock's one deliberate
-- multi-project example.
INSERT INTO ztime_team_member (leader_id, pernr) VALUES
  ('AF', '00104501'),
  ('AF', '00104504'),
  ('PA', '00104504'),
  ('AF', '00104513'),
  ('AF', '00104514'),
  ('AF', '00104515'),
  ('RN', '00104502'),
  ('RN', '00104503'),
  ('RN', '00104516'),
  ('RN', '00104517'),
  ('RN', '00104518'),
  ('PA', '00104505'),
  ('PA', '00104519'),
  ('PA', '00104520'),
  ('PA', '00104521'),
  ('RN', '00104523'),
  ('RN', '00104524'),
  ('RN', '00104525'),
  ('RN', '00104526'),
  ('RN', '00104527'),
  ('CP', '00104510'),
  ('CP', '00104511'),
  ('CP', '00104512'),
  ('CP', '00104528'),
  ('CP', '00104529'),
  ('MS', '00104530'),
  ('MS', '00104531'),
  ('MS', '00104532'),
  ('MS', '00104533'),
  ('MS', '00104534');

-- CATSDB hours rows — PT01 weeks (My Timesheet, Consulting), from WEEKS_PT01
-- CATSDB hours rows — PT02 weeks (Building Solutions), from WEEKS_PT02
INSERT INTO catsdb (pernr, workdate, posid, rkostl, lstar, catshours, long_text, status, origin, created_by, on_behalf_of) VALUES
  ('00104567', '2026-08-03', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-04', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-05', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-06', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-03', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-04', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-05', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-06', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-10', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-11', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-12', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-13', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-14', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll requirements review', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-10', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff prep', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-11', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff prep', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-12', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff prep', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-13', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff prep', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-14', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff prep', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-24', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover planning', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-25', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover planning', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-26', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover planning', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-27', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover planning', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-28', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover planning', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-24', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout scoping', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-25', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout scoping', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-26', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout scoping', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-27', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout scoping', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-28', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout scoping', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-31', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover testing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-01', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover testing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-02', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover testing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-03', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover testing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-04', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll cutover testing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-31', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-01', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-02', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-03', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-04', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Time tracking rollout support', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-07', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll parallel run', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-08', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll parallel run', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-09', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll parallel run', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-10', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll parallel run', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-07', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff', 'APPROVED', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-08', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff', 'APPROVED', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-09', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff', 'APPROVED', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-10', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout kickoff', 'APPROVED', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'BNK-2026.1.3', NULL, 'CONS01', 3, 'Requirements workshop, payroll', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-15', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Requirements workshop, payroll', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-17', 'BNK-2026.1.3', NULL, 'CONS01', 2, 'Requirements workshop, payroll', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'RTL-TT.2.1', NULL, 'CONS01', 2, 'Time recording solution design', 'DRAFT', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-16', 'RTL-TT.2.1', NULL, 'CONS01', 2, 'Time recording solution design', 'DRAFT', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-14', NULL, 'PT4010', 'ADMIN1', 1, NULL, 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-17', NULL, 'PT4010', 'ADMIN1', 1.5, NULL, 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-21', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll steering follow-up', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-22', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll steering follow-up', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-23', 'BNK-2026.1.3', NULL, 'CONS01', 2, 'Payroll steering follow-up', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-28', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-29', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-01', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-30', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout stabilization', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-05', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Retail rollout wave 2 kickoff', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-06', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Retail rollout wave 2 kickoff', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-12', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-13', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-14', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-15', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-12', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout stabilization', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-13', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout stabilization', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-15', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout stabilization', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-16', 'AER-WFM.4.2', NULL, 'PMGT01', 4, 'WFM rollout stabilization', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-19', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Retail rollout wave 2 support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-20', 'RTL-TT.2.1', NULL, 'CONS01', 4, 'Retail rollout wave 2 support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-26', 'BNK-2026.1.3', NULL, 'CONS01', 4, 'Payroll go-live support', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-31', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-01', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-02', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-03', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-04', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-08-31', NULL, 'PT4020', 'ADMIN1', 1, 'Site safety briefing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-02', NULL, 'PT4020', 'ADMIN1', 1, 'Site safety briefing', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-07', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'HVAC filter replacement round', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-08', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'HVAC filter replacement round', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-09', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'HVAC filter replacement round', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-11', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'HVAC filter replacement round', 'APPROVED', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-10', 'HSP-FAC.1.1', NULL, 'MAINT1', 3, 'Fire safety systems check', 'APPROVED', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'HSP-FAC.1.1', NULL, 'MAINT1', 3, 'Boiler room inspection', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-15', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Boiler room inspection', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-17', 'HSP-FAC.1.1', NULL, 'MAINT1', 2, 'Boiler room inspection', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'HSP-FAC.1.1', NULL, 'MAINT1', 2, 'Elevator call-out repair', 'DRAFT', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-16', 'HSP-FAC.1.1', NULL, 'MAINT1', 3, 'Elevator call-out repair', 'DRAFT', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-09-14', NULL, 'PT4020', 'ADMIN1', 1, NULL, 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-17', NULL, 'PT4020', 'ADMIN1', 1.5, NULL, 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-28', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-29', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-01', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-02', 'HSP-FAC.1.1', NULL, 'MAINT1', 4, 'Elevator preventive maintenance', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-28', 'AER-FAC.2.1', NULL, 'MAINT1', 4, 'Terminal HVAC inspection round', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-29', 'AER-FAC.2.1', NULL, 'MAINT1', 4, 'Terminal HVAC inspection round', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-30', 'AER-FAC.2.1', NULL, 'MAINT1', 4, 'Terminal HVAC inspection round', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-01', 'AER-FAC.2.1', NULL, 'MAINT1', 4, 'Terminal HVAC inspection round', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-05', 'HSP-FAC.1.1', NULL, 'MAINT1', 3, 'Boiler room inspection', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-07', 'HSP-FAC.1.1', NULL, 'MAINT1', 3, 'Boiler room inspection', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-10-06', 'AER-FAC.2.1', NULL, 'MAINT1', 4, 'Baggage handling systems check', 'DRAFT', 'Suggested', '00104567', '00104567'),
  ('00104567', '2026-10-07', 'AER-FAC.2.1', NULL, 'MAINT1', 4, 'Baggage handling systems check', 'DRAFT', 'Suggested', '00104567', '00104567');

-- CATSDB allowance/bonus rows, from WEEKS_PT01[].allow / WEEKS_PT02[].allow
INSERT INTO catsdb (pernr, workdate, posid, rkostl, lgart, anzhl, catsamount, long_text, status, origin, created_by, on_behalf_of) VALUES
  ('00104567', '2026-09-14', 'BNK-2026.1.3', NULL, '1200', 1, NULL, NULL, 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'BNK-2026.1.3', NULL, '1300', 86, NULL, 'Lisbon to Porto and back', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-15', 'AER-WFM.4.2', NULL, '1210', 1, NULL, 'Spain', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'HSP-FAC.1.1', NULL, '1500', 1, NULL, NULL, 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-14', 'HSP-FAC.1.1', NULL, '1300', 42, NULL, 'Depot to hospital campus and back', 'DRAFT', 'Manual', '00104567', '00104567'),
  ('00104567', '2026-09-28', 'AER-FAC.2.1', NULL, '1500', 1, NULL, NULL, 'DRAFT', 'Manual', '00104567', '00104567');

-- Absences (PA2001), self-service user, all weeks both companies. Weeks 38
-- and 39 reuse the exact same sample request numbers in both companies'
-- mock data (same person, same calendar) — deduplicated by request_number
-- so each real leave request produces exactly one row.
INSERT INTO pa2001_absences (pernr, awart, begda, endda, hours, status, request_number) VALUES
  ('00104567', '0100', '2026-08-07', '2026-08-07', 8, 'approved', '4500301'),
  ('00104567', '0100', '2026-08-17', '2026-08-17', 8, 'approved', '4500312'),
  ('00104567', '0100', '2026-09-11', '2026-09-11', 8, 'approved', '4500198'),
  ('00104567', '0210', '2026-09-16', '2026-09-16', 4, 'approved', '4500219'),
  ('00104567', '0100', '2026-09-18', '2026-09-18', 8, 'approved', '4500221'),
  ('00104567', '0100', '2026-09-17', '2026-09-17', 8, 'pending', '4500230'),
  ('00104567', '0100', '2026-09-21', '2026-09-21', 8, 'pending', '4500255'),
  ('00104567', '0210', '2026-09-29', '2026-09-29', 2, 'approved', '4500270'),
  ('00104567', '0210', '2026-09-10', '2026-09-10', 2, 'approved', '4500205'),
  ('00104567', '0100', '2026-09-30', '2026-09-30', 8, 'approved', '4500281');

-- Approval queue sample (ZTIME_APPROVAL), week 2026-W38, from
-- APPROVALS_PT01/APPROVALS_PT02. PT01 names not already in TEAM/LEADERS
-- (Bruno Matos, Carla Nunes, Diogo Sousa, Eva Lopes, Filipe Reis) got new,
-- invented pernrs above (00104540-00104544) purely to satisfy the FK.
INSERT INTO ztime_approval (bukrs, period_type, period_key, pernr, pspid, total_hours, in_project_hours, deviation_hours, has_exception, exception_note) VALUES
  ('PT01', 'WEEK', '2026-W38', '00104508', 'BNK-2026', 40, 36, 0, FALSE, NULL),
  ('PT01', 'WEEK', '2026-W38', '00104540', 'RTL-TT', 38.5, 34, -1.5, FALSE, NULL),
  ('PT01', 'WEEK', '2026-W38', '00104541', 'AER-WFM', 40, 40, 0, FALSE, NULL),
  ('PT01', 'WEEK', '2026-W38', '00104542', 'BNK-2026', 37, 30, -3, FALSE, NULL),
  ('PT01', 'WEEK', '2026-W38', '00104543', 'RTL-TT', 40, 40, 0, TRUE, 'Pending leave request overlaps recorded hours'),
  ('PT01', 'WEEK', '2026-W38', '00104544', 'AER-WFM', 24, 18, -16, TRUE, 'Two empty working days'),
  ('PT02', 'WEEK', '2026-W38', '00104510', 'HSP-FAC', 40, 40, 0, FALSE, NULL),
  ('PT02', 'WEEK', '2026-W38', '00104511', 'HSP-FAC', 18, 18, -12, FALSE, NULL),
  ('PT02', 'WEEK', '2026-W38', '00104528', 'HSP-FAC', 24, 24, -8, FALSE, NULL),
  ('PT02', 'WEEK', '2026-W38', '00104530', 'AER-FAC', 16, 16, -16, FALSE, NULL),
  ('PT02', 'WEEK', '2026-W38', '00104512', 'HSP-FAC', 24, 24, -8, TRUE, 'Pending leave request overlaps recorded hours'),
  ('PT02', 'WEEK', '2026-W38', '00104532', 'AER-FAC', 16, 16, -16, TRUE, 'Two empty working days');

