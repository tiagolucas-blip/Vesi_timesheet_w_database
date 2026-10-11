# API — vesi-timesheet-erp

Camada de API (funções serverless Vercel, Node.js/ESM, em `api/`) que lê e
escreve nas tabelas de `db/schema.sql`, em vez dos arrays mock de `app.js`.
Ainda não ligada ao frontend (task #61) — o `app.js` atual continua a usar
os arrays mock.

## Configuração local

```
cp .env.example .env   # ajustar DATABASE_URL se necessário
psql $DATABASE_URL -f db/schema.sql
psql $DATABASE_URL -f db/seed.sql
```

Em produção, `DATABASE_URL` é a connection string do Neon/Vercel Postgres,
definida nas environment variables do projeto Vercel — nunca commitada.

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| GET | `/api/reference` | Sociedades, tipos de remuneração, tipos de ausência, tipos de atividade, perfil CATS por sociedade |
| GET | `/api/employee?pernr=` | Identidade + atribuição organizacional + horas planeadas de uma pessoa |
| GET | `/api/projects?bukrs=` | Projetos de uma sociedade (mais os partilhados), com WBS/recetor e gestor |
| GET | `/api/leaders?bukrs=` | Lista "Acting as": quem gere pelo menos um projeto da sociedade, derivado de `responsible_pernr` |
| GET | `/api/absences?pernr=` | Ausências de uma pessoa (PA2001, read-only) |
| GET | `/api/timesheet?pernr=&start=` | Semana (segunda a domingo) de uma pessoa: horas, allowances/bónus, ausências, estado submetido derivado |
| POST | `/api/timesheet` | Grava (Save) as linhas de horas/allowances da semana; recusa se a semana já estiver `SUBMITTED`/`APPROVED`/`TRANSFERRED` |
| POST | `/api/timesheet-submit` | Submete (Submit) a semana: `SAVED` → `SUBMITTED` em todas as linhas; recusa se faltar gravar algo |
| GET | `/api/team?pspid=&weekStart=` | Equipa de um projeto para lançamento em massa, com horas já registadas por pessoa nessa semana |
| POST | `/api/team-entry` | Lançamento em massa (horas ou allowances) para uma ou mais pessoas da equipa |
| GET | `/api/approvals?bukrs=&period=` | Fila de aprovação de uma sociedade/período |
| POST | `/api/approvals` | Aprova uma ou mais entradas da fila |

Todas as rotas usam SQL parametrizado (nunca concatenação de strings) e
devolvem `{error, detail?}` com o código HTTP apropriado em caso de falha.
Sem autenticação nesta fase — mesma postura do resto do protótipo (a troca
de sociedade/perfil continua a ser um seletor na interface).

## Estados do catsdb.status na API

`POST /api/timesheet` grava sempre como `SAVED`. `POST /api/timesheet-submit`
exige que todas as linhas da semana estejam `SAVED` e passa-as a `SUBMITTED`.
`APPROVED`/`REJECTED`/`TRANSFERRED` não têm endpoint próprio ainda — ficam
para quando a Approval screen for ligada à API (aprovar aí só marca
`ztime_approval.approved`, não propaga ainda ao `catsdb.status`; ver nota em
`api/approvals.js`).

## Testado

Todos os endpoints foram exercitados diretamente (sem `vercel dev`) contra
Postgres 16 local com o schema+seed carregados: leituras, grava-e-relê uma
semana nova, submissão, bloqueio de reescrita pós-submissão, lançamento em
massa e aprovação. Ver histórico de commits para detalhe.
