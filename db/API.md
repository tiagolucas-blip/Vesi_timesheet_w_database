# API — vesi-timesheet-erp

Camada de API (funções serverless Vercel, Node.js/ESM, em `api/`) que lê e
escreve nas tabelas de `db/schema.sql`, em vez dos arrays mock de `app.js`.
Já ligada ao frontend: `app.js` carrega tudo de `GET /api/bootstrap` no
arranque (ver `applyBootstrapData()`) e grava através destes endpoints em
Save/Submit, no lançamento em massa e na aprovação — não restam arrays mock
de dados reais, só duas pequenas sobreposições estáticas documentadas em
`api/bootstrap.js` (sugestões do assistente e a ausência por dia de cada
membro da equipa, nenhuma das duas com tabela própria, de propósito).

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
| GET | `/api/bootstrap?pernr=` | Tudo o que o `app.js` precisa para arrancar numa só chamada, já na forma dos antigos literais mock (ver cabeçalho do ficheiro) |
| GET | `/api/timesheet?pernr=&start=&bukrs=` | Semana (segunda a domingo) de uma pessoa **numa sociedade**: horas, allowances/bónus, ausências, estado submetido derivado |
| POST | `/api/timesheet` | Grava (Save) as linhas de horas/allowances da semana **dessa sociedade** (`bukrs` no corpo); recusa se já estiver `SUBMITTED`/`APPROVED`/`TRANSFERRED` |
| POST | `/api/timesheet-submit` | Submete (Submit) a semana **dessa sociedade**: `SAVED` → `SUBMITTED` em todas as linhas; recusa se faltar gravar algo |
| GET | `/api/team?pspid=&weekStart=` | Equipa de um projeto para lançamento em massa, com horas já registadas por pessoa nessa semana |
| POST | `/api/team-entry` | Lançamento em massa (horas ou allowances) para uma ou mais pessoas da equipa |
| GET | `/api/approvals?bukrs=&period=` | Fila de aprovação de uma sociedade/período |
| POST | `/api/approvals` | Aprova uma ou mais entradas da fila |

Todas as rotas usam SQL parametrizado (nunca concatenação de strings) e
devolvem `{error, detail?}` com o código HTTP apropriado em caso de falha.
Sem autenticação nesta fase — mesma postura do resto do protótipo (a troca
de sociedade/perfil continua a ser um seletor na interface).

**`bukrs` é obrigatório em `/api/timesheet` e `/api/timesheet-submit`**:
uma semana PT01 e uma PT02 podem ter exatamente as mesmas datas de
calendário (a mesma pessoa, duas "vistas" de empresa do seu próprio
horário — ver SCHEMA.md). Sem filtrar por sociedade, gravar a semana de
uma apagaria os lançamentos da outra nessas mesmas datas; todas as
consultas aqui restringem-se às linhas cujo recetor (WBS de um projeto
dessa sociedade, ou o centro de custo direto dessa sociedade) pertence
mesmo a essa sociedade.

## Estados do catsdb.status na API

`POST /api/timesheet` grava sempre como `SAVED`. `POST /api/timesheet-submit`
exige que todas as linhas da semana estejam `SAVED` e passa-as a `SUBMITTED`.
`APPROVED`/`REJECTED`/`TRANSFERRED` não têm endpoint próprio ainda — ficam
para quando a Approval screen for ligada à API (aprovar aí só marca
`ztime_approval.approved`, não propaga ainda ao `catsdb.status`; ver nota em
`api/approvals.js`).

## Testado

Todos os endpoints foram exercitados diretamente (sem `vercel dev`) e,
depois, através da própria interface com um servidor de desenvolvimento
local (estáticos + `api/*.js`), contra Postgres 16 real com o schema+seed
carregados: arranque, My Timesheet semanal e mensal (PT01/PT02), Save,
Submit, bloqueio de reescrita pós-submissão, troca de sociedade de ida e
volta sem perda de dados, lançamento em massa na Team screen e aprovação —
tudo confirmado diretamente na base de dados. Ver histórico de commits
para detalhe, incluindo dois bugs reais encontrados e corrigidos nesta
fase: a junção que devolvia o nome do projeto trocado, e a falta de
isolamento por sociedade em `/api/timesheet`/`/api/timesheet-submit` (ver
nota sobre `bukrs` acima).
