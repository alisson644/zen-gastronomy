# Deploy

Há dois caminhos suportados:
- **[Fly.io](#flyio)**: `fly.toml`, banco único via `DATABASE_URL`;
- **[Kamal numa VPS](#kamal--vps)**: `config/deploy.yml`, Postgres no próprio servidor.

A seção [Segurança](#segurança) vale para os dois. No Fly, o backup do Postgres é feito pela própria plataforma (`fly postgres` tem snapshots diários do volume).

## Fly.io

Configuração em `fly.toml`: app `zen-gastronomy`, região `gru` (São Paulo), 1 GB de RAM.

### Primeiro deploy

```bash
fly postgres create            # ou Managed Postgres; anote a connection string
fly postgres attach <nome-do-postgres> --app zen-gastronomy   # define DATABASE_URL
fly volumes create storage --region gru --size 1             # fotos de perfil
fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
fly secrets set SMTP_ADDRESS=smtp.seuprovedor.com SMTP_USERNAME=... SMTP_PASSWORD=... \
  MAILER_FROM="Zen Gastronomy <nao-responda@seudominio.com.br>"
fly deploy
```

O usuário do Postgres no Fly normalmente só acessa um banco. Por isso, com `DATABASE_URL` definido, o app entra em **modo banco único**:
- Solid Cache, Solid Queue e Solid Cable usam o banco principal;
- as tabelas deles são criadas por `bin/rails db:load_solid_schemas`, que o `bin/docker-entrypoint` roda junto com o `db:prepare` a cada boot.

### Domínio próprio

1. `fly certs add zen.seudominio.com.br`
2. Troque `APP_HOST` em `fly.toml`.
3. Para continuar aceitando o domínio `.fly.dev`, defina `APP_EXTRA_HOSTS = 'zen-gastronomy.fly.dev'` em `[env]`.

### Comandos úteis

- `fly logs`;
- `fly ssh console -C "/rails/bin/rails console"`;
- `fly ssh console -C "/rails/bin/rails users:make_admin EMAIL=voce@seudominio.com.br"`.

Com `min_machines_running = 0`, a máquina desliga quando fica ociosa e o primeiro acesso depois disso é mais lento. Mude para `1` se quiser o app sempre ligado.

## Kamal + VPS

O app roda em containers Docker numa VPS, com [Kamal](https://kamal-deploy.org):
- o **kamal-proxy** cuida do HTTPS (Let's Encrypt) e de deploys sem downtime;
- o **Postgres 17** roda como *accessory* no mesmo servidor;
- os jobs (Solid Queue) rodam dentro do Puma (`SOLID_QUEUE_IN_PUMA`).

### Pré-requisitos

- VPS com Ubuntu/Debian, acesso SSH como `root` (ou ajuste `ssh.user` em `config/deploy.yml`) e portas 80 e 443 liberadas.
- Domínio com registro **A** apontando para o IP do servidor (`APP_HOST`).
- Conta num registry de imagens (Docker Hub, GHCR...) e um token de acesso.
- Docker rodando na sua máquina (o Kamal faz o build localmente).
- `config/master.key` (não está no git; guarde num gerenciador de senhas).
- Um provedor SMTP (Resend, Brevo, SES, Mailgun...) para a recuperação de senha.

### Configuração

```bash
cp .env.example .env   # .env não vai para o git
```

Preencha o `.env`. Para a senha do banco: `openssl rand -hex 32`.

| Variável | Para quê |
| --- | --- |
| `KAMAL_SERVER_IP` | IP da VPS |
| `APP_HOST` | Domínio do app (HTTPS, links de e-mail, proteção do cabeçalho Host) |
| `KAMAL_IMAGE`, `KAMAL_REGISTRY_SERVER`, `KAMAL_REGISTRY_USERNAME`, `KAMAL_REGISTRY_PASSWORD` | Registry das imagens |
| `DATABASE_PASSWORD` | Senha do Postgres (usada pelo container do banco e pelo app) |
| `SMTP_ADDRESS`, `SMTP_PORT`, `SMTP_USERNAME`, `SMTP_PASSWORD`, `MAILER_FROM` | Envio de e-mail |
| `CORS_ORIGINS` | Origens externas liberadas (deixe vazio: o app não tem API) |

Confira a configuração renderizada:

```bash
bin/kamal config
```

### Primeiro deploy

```bash
bin/kamal setup
```

Esse comando:
1. instala o Docker no servidor;
2. sobe o Postgres;
3. faz o build e o push da imagem;
4. sobe o app.

O `bin/docker-entrypoint` roda `db:prepare`, que cria e migra os bancos principal, `_cache`, `_queue` e `_cable`.

Depois, crie sua conta pelo site e promova-a a administrador do sistema:

```bash
bin/kamal app exec "bin/rails users:make_admin EMAIL=voce@seudominio.com.br"
```

### Deploys seguintes

```bash
bin/kamal deploy
```

As migrations rodam sozinhas na subida do container.

Comandos úteis:
- `bin/kamal logs`: acompanha os logs;
- `bin/kamal console`: console Rails em produção;
- `bin/kamal dbc`: `psql` no banco;
- `bin/kamal rollback <versão>`: volta para uma versão anterior (`bin/kamal app containers` lista as versões).

## Backup (Kamal)

**Faça backups fora do servidor**: se a VPS for perdida, os dados vão junto.

```bash
bin/kamal db-backup > backup-$(date +%F).sql
```

Arquivos enviados (fotos de perfil) ficam no volume `zen_gastronomy_storage`, que também precisa de backup.

Para restaurar:

```bash
cat backup.sql | ssh root@SERVIDOR "docker exec -i zen_gastronomy-db psql -U zen_gastronomy postgres"
```

## Segurança

| Recurso | Configuração |
| --- | --- |
| HTTPS obrigatório, cookies seguros, HSTS | `force_ssl` |
| Cabeçalho `Host` restrito ao `APP_HOST` | `config.hosts`; `/up` liberado para o health check |
| Limite de tentativas: login, recuperação de senha, cadastro e tráfego geral | Rack::Attack (`config/initializers/rack_attack.rb`); quem procura `/wp-admin`, `.php`, `/.env` etc. é banido por 1h |
| CSP com nonce e Permissions-Policy | `config/initializers/content_security_policy.rb`, `config/application.rb` |
| Senhas com no mínimo 8 caracteres; a recuperação não revela se o e-mail existe | Devise (`paranoid`) |
| CNPJ criptografado no banco | Active Record Encryption, chaves em `credentials.active_record_encryption` |
| Análise do código, das gems e testes a cada PR | CI: brakeman, bundler-audit, rubocop e RSpec |

**Rotação de segredos:**
- A `master.key` só pode ser trocada junto com o `credentials.yml.enc` (`bin/rails credentials:edit`).
- Perder a `master.key` torna o CNPJ criptografado ilegível.
- Para trocar a senha do banco, altere `DATABASE_PASSWORD`, rode `ALTER USER` no Postgres e depois `bin/kamal app boot` (os segredos são reenviados a cada boot/deploy).
