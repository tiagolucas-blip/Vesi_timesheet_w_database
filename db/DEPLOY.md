# Deploy em produção — vesi-timesheet-erp

Passo a passo para pôr esta app, já ligada à base de dados real
(`db/schema.sql` + `db/seed.sql`, consumida pela API em `api/*.js`), a
correr no Vercel com Postgres a sério (Neon ou Vercel Postgres).

## 0. Bloqueio conhecido nesta sessão

Tentei criar o projeto Vercel diretamente a partir desta sessão (ligado ao
repositório GitHub) e a chamada foi recusada com `403 forbidden` — a
integração Vercel desta sessão não tem permissão de escrita neste team
(`TLEAL4`). Os passos abaixo são os que tens de fazer tu, no dashboard; a
partir do momento em que o projeto exista e a `DATABASE_URL` esteja
definida, posso retomar (verificar variáveis, acompanhar o deploy, etc.).

## 1. Criar o projeto Vercel

1. [vercel.com/new](https://vercel.com/new) → **Import Git Repository** →
   escolhe `tiagolucas-blip/Vesi_timesheet_w_database`.
   - Se o repositório não aparecer na lista, a app GitHub do Vercel ainda
     não tem acesso a ele: GitHub → Settings → Applications → Vercel →
     Configure → adiciona o repositório à lista, depois volta a
     `vercel.com/new`.
2. Framework preset: **Other** (sem framework). Build command e output
   directory ficam vazios/omitidos — `vercel.json` já traz essa
   configuração (`framework: null`, `outputDirectory: "."`).
3. Não é preciso tocar em mais nada nesta tela. Cria o projeto (o primeiro
   deploy pode falhar ou ficar incompleto por faltar `DATABASE_URL` —
   corrige-se no passo 3 e refaz-se o deploy no passo 4).

## 2. Provisionar o Postgres (Neon)

Caminho mais simples, dentro do próprio Vercel:

1. No projeto → separador **Storage** → **Create Database** → **Neon
   (Postgres)** → segue o fluxo (escolhe a região mais próxima dos
   utilizadores).
2. O Vercel liga a base de dados ao projeto automaticamente e já define
   `DATABASE_URL` (e outras variáveis Neon) nas environment variables de
   Production e Preview. Confirma em **Settings → Environment Variables**
   que `DATABASE_URL` está lá.

Alternativa — Neon diretamente: cria o projeto em
[neon.tech](https://neon.tech), copia a connection string (formato
`postgres://user:pass@host/db?sslmode=require`) e define-a manualmente em
**Settings → Environment Variables** do projeto Vercel, nos ambientes
Production e Preview, com a chave `DATABASE_URL`.

## 3. Carregar o schema e os dados de exemplo

Com a connection string da produção (`$DATABASE_URL` tal como aparece no
Vercel ou no Neon):

```bash
psql "$DATABASE_URL" -f db/schema.sql
psql "$DATABASE_URL" -f db/seed.sql
```

`db/seed.sql` carrega os dados fictícios de demonstração (ver
Confidencialidade no README principal — nenhum dado real). Se a produção
for para arrancar vazia (sem o exemplo), corre só o `schema.sql`.

## 4. Fazer o deploy

Qualquer push a `main` dispara um deploy automático, uma vez o projeto
ligado ao repositório (passo 1). Para forçar um primeiro deploy depois de
definir a `DATABASE_URL`:

- Vercel → o projeto → separador **Deployments** → nos "..." do deploy
  mais recente → **Redeploy**.

## 5. Verificar

1. Abre o URL do deploy (`https://<projeto>.vercel.app`).
2. Confirma que a tela de carregamento (`Loading timesheet…`) desaparece e
   a aplicação mostra dados reais (projetos, equipa, aprovações).
3. Testa Save numa semana e recarrega a página — a alteração deve
   persistir (prova de que está mesmo a ler/escrever da base de dados, não
   de um cache do browser).
4. Se aparecer o erro "Could not load the timesheet from the database.",
   confirma `DATABASE_URL` nas environment variables e que o
   `db/schema.sql` + `db/seed.sql` foram mesmo carregados nessa base de
   dados (passo 3).

## 6. (Opcional) Assistente com Claude

Independente da base de dados: define `ANTHROPIC_API_KEY` nas environment
variables para ligar o assistente a Claude (ver README principal, secção
"Connecting Claude to the assistant"). Sem a chave, o assistente continua
a funcionar com o interpretador local (regex), sem tocar na base de dados.

## Notas para produção a sério (além desta demo)

- **Pool de ligações**: `api/_db.js` usa `pg.Pool` com `max: 5` por
  instância de função serverless — razoável para demonstração; em
  produção com tráfego real, considerar o Neon em modo *pooled*
  (connection string com `-pooler` no host) para não esgotar ligações
  entre invocações concorrentes.
- **Sem autenticação** (ver CLAUDE.md/README) — esta API aceita qualquer
  `pernr` no pedido, sem verificar quem está autenticado. Aceitável para
  demonstração; não expor assim num ambiente com dados reais.
- **Seed de demonstração**: `db/seed.sql` é dados fictícios (ver
  Confidencialidade no README principal). Não correr contra uma base de
  dados com dados reais de clientes.
