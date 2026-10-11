# Schema — vesi-timesheet-erp

Modelo relacional (PostgreSQL) que substitui os arrays mock em `app.js` por
tabelas representativas do SAP ERP real por trás de uma app de timesheet
(CATS). Ficheiro de desenho (DDL completo em `db/schema.sql`).

Convenção usada em todas as tabelas:
- **Standard SAP** — nome e campos reais de SAP ECC/S4 (reduzidos aos campos
  que esta app usa; um sistema real tem muitos mais campos e histórico de
  validade, que aqui foi simplificado).
- **Z-custom (`ZTIME_*`)** — tabelas de cliente, não standard. SAP não tem
  uma tabela única para "fila de aprovação" ou "perfil CATS por empresa";
  isso é customizing/workflow num sistema real. Modelado aqui como tabelas Z
  simples para os dados mock terem onde viver.

Fora de âmbito, deliberadamente: o estado do assistente (`chat.*`, sugestões
de IA) é uma funcionalidade de aplicação, não dado SAP, e não tem tabela —
é calculado a partir de CATSDB + PA2001.

## Tabelas standard SAP

| Tabela | Descrição real SAP | Substitui em `app.js` |
|---|---|---|
| `pa0002_personal_data` | Infotype 0002, Dados Pessoais — nome | `TEAM[].name`, `EMPLOYEE_NAME` |
| `t001_company_code` | Sociedades (Company Codes) | `COMPANIES[]` |
| `csks_cost_center` | Centros de custo (Controlling) | `COST_CENTERS[]` / campo `kostl` dos colaboradores |
| `csla_activity_type` | Tipos de atividade (Controlling) | `lstar` usado em `PROJECTS[]`/WBS |
| `pa0001_org_assignment` | Infotype 0001, Atribuição Organizacional — sociedade, centro de custo, Job Classification | `TEAM[].company/costCenter/role` |
| `pa0007_planned_hours` | Infotype 0007, Horário de Trabalho Previsto — horas diárias | `TEAM[].dailyHours` / capacidade |
| `t554t_absence_type` | Textos de tipos de ausência | `ABSENCE_TYPES[]` |
| `t512w_wage_type` | Características de tipos de remuneração + textos (T512T fundido) | `WAGETYPES[]` |
| `proj_project_definition` | Definição de Projeto (PS) — inclui `responsible_pernr`, o gestor do projeto, registado no próprio dado mestre, como no SAP PS real | `PROJECTS[].pspid/name`, `LEADERS[].name` |
| `prps_wbs_element` | Elemento WBS — objeto recetor real do lançamento | `PROJECTS[].wbs`, `receiverObjectLabel()` |
| `catsdb` | **CATSDB** — tabela central de registo de tempos; linhas de horas, ausências e allowances/bónus convivem aqui tal como no SAP real | `WEEKS_PT01`, `WEEKS_PT02`, lançamentos diários, allowances |
| `pa2001_absences` | Infotype 2001, Ausências (pedido de férias/ausência, lido como read-only) | `ABSENCES[]` |

## Tabelas Z-custom (`ZTIME_*`)

| Tabela | Porquê não é standard | Substitui em `app.js` |
|---|---|---|
| `ztime_profile` | Perfil de entrada CATS (duração vs. picagem); no SAP real isto é customizing (`V_T555A` e afins), não uma tabela única | lógica `Z_CONS`/`Z_BSRV` do ecrã "CATS mapping" |
| `ztime_company_cfg` | Liga sociedade → perfil CATS, com validade | mapeamento sociedade→perfil usado em `goToScreen`/render |
| `ztime_approval` | Fila de aprovação por pessoa/período; no SAP real é derivado de `CATSDB.STATUS` + workflow, não uma master table | `state.approvals` |
| `ztime_team_member` | Pertença de equipa para lançamento em massa, ligada diretamente ao projeto | `LEADERS[].teamPernrs` / ecrã Team |

## Notas de desenho

- **Gestores de projeto (líderes)**: não têm tabela Z própria. O gestor de
  um projeto fica registado no próprio dado mestre do projeto —
  `proj_project_definition.responsible_pernr` — tal como no SAP PS real,
  onde o responsável vive em PROJ, não numa tabela de cliente ao lado.
  "Que projetos gere esta pessoa?" é uma simples consulta (`SELECT pspid
  FROM proj_project_definition WHERE responsible_pernr = :pernr`), nunca
  uma tabela de associação separada. A lista "Acting as" da UI é a mesma
  consulta, distinta por `pernr`, ligada a `pa0002` para o nome e a
  `pa0001` para filtrar por sociedade.
- **`catsdb`** é deliberadamente a tabela mais carregada: no SAP real,
  CATSDB mistura linhas de horas (`CATSHOURS`/`BEGUZ`/`ENDUZ`), linhas de
  allowance/bónus (`LGART`+`ANZHL`/`CATSAMOUNT`) e marcadores de ausência
  (`AWART`) na mesma tabela — por isso o `CHECK` garante que cada linha é
  exatamente um destes três tipos, nunca uma mistura.
- **Estados (`catsdb.status`)**: `DRAFT` (a editar, ainda não guardado) →
  `SAVED` (Save) → `SUBMITTED` (Submit, liberta para aprovação) →
  `APPROVED`/`REJECTED` (decisão do gestor) → `TRANSFERRED` (exportado para
  o alvo). `SUBMITTED` é distinto de `APPROVED`: o próprio colaborador
  submete, só o gestor aprova — a app já impõe esta regra de negócio
  (Save obrigatório antes do Submit).
- **Correções**: uma linha `TRANSFERRED`/`APPROVED` nunca é editada in-place;
  uma correção cria uma nova linha com `refcounter` a apontar para a
  original e volta a passar por aprovação — replica o comportamento real do
  CATS descrito no próprio ecrã "CATS mapping" da app.
- **AXI-INT** (trabalho interno) não tem nenhuma linha em `prps_wbs_element`
  — não existe WBS para ele. Cada linha de horas em `catsdb` lança a um
  recetor que é **ou** um elemento WBS (`posid`) **ou** um centro de custo
  direto (`rkostl`), nunca os dois — tal como no CATS real. AXI-INT usa
  sempre `rkostl`; os restantes projetos (faturáveis, com WBS) usam sempre
  `posid`. O `CHECK` em `catsdb` garante esta exclusividade.
- Sem histórico de validade (`begda`/`endda`) completo em todas as tabelas
  que o SAP real versiona (ex.: `pa0002`); mantém-se apenas onde a app usa a
  validade (ex.: `pa0001`, `pa0007`, `ztime_company_cfg`).

## Próximos passos (tasks #59-63)

1. Script de seed que carrega os dados mock atuais (`PROJECTS`, `TEAM`,
   `WEEKS_PT01`/`WEEKS_PT02`, `ABSENCES`, `state.approvals`, `WAGETYPES`,
   `LEADERS`, `COMPANIES`) para estas tabelas.
2. Camada de API (rotas em `api/`) que lê/escreve em Postgres em vez dos
   arrays em `app.js`.
3. Ligar o frontend à API.
4. Testar localmente com Postgres real (já disponível neste sandbox).
5. Preparar deploy em produção (Neon / Vercel Postgres).
