.PHONY: help init start lint lint-fix typecheck \
        vercel-login vercel-link vercel-pull vercel-deploy vercel-deploy-prod vercel-open \
        sb-login sb-link sb-start sb-stop sb-status sb-reset sb-migrate \
        env-check \
        clear clear-db

## Show this help
help:
	@awk ' \
	  /^# ===/ { \
	    printf "\n\033[1;36m%s\033[0m\n", substr($$0, 7); next \
	  } \
	  /^## / { desc = substr($$0, 4); next } \
	  /^[a-zA-Z_-]+:/ && desc != "" { \
	    split($$0, a, ":"); \
	    printf "  \033[32m%-22s\033[0m %s\n", a[1], desc; \
	    desc = "" \
	  } \
	  { desc = "" } \
	' $(MAKEFILE_LIST)

# === Local development

## Install dependencies and set up git hooks
init:
	pnpm install
	node node_modules/.pnpm/supabase@*/node_modules/supabase/scripts/postinstall.js 2>/dev/null || true
	pnpm lefthook install

## Start the local dev server
start:
	pnpm dev

## Run linter
lint:
	pnpm lint

## Run linter with auto-fix
lint-fix:
	pnpm lint:fix

## Run TypeScript type check
typecheck:
	pnpm typecheck

# === Vercel

## Log in to Vercel CLI
vercel-login:
	pnpm vercel login

## Link this directory to a Vercel project
vercel-link:
	pnpm vercel link

## Pull env vars and project settings from Vercel into .env.local
vercel-pull:
	pnpm vercel env pull .env.local

## Deploy a preview build
vercel-deploy:
	pnpm vercel deploy

## Deploy to production
vercel-deploy-prod:
	pnpm vercel deploy --prod

## Open the Vercel project dashboard in the browser
vercel-open:
	pnpm vercel open

# === Supabase

## Log in to Supabase CLI
sb-login:
	pnpm supabase login

## Link to a remote Supabase project
sb-link:
	pnpm supabase link

## Start local Supabase stack (Docker required)
sb-start:
	pnpm supabase start

## Stop local Supabase stack
sb-stop:
	pnpm supabase stop

## Show status and connection info of local Supabase stack
sb-status:
	pnpm supabase status

## Apply pending migrations to the local DB
sb-migrate:
	pnpm supabase db push --local

## Reset local DB (drop all data and re-run migrations + seed)
sb-reset:
	pnpm supabase db reset

# === Environment variables

## Print which required env vars are set / missing
env-check:
	@echo "=== Supabase ==="
	@for v in NEXT_PUBLIC_SUPABASE_URL SUPABASE_URL \
	           NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY SUPABASE_PUBLISHABLE_KEY \
	           SUPABASE_SERVICE_ROLE_KEY SUPABASE_JWT_SECRET \
	           POSTGRES_URL POSTGRES_URL_NON_POOLING \
	           POSTGRES_USER POSTGRES_HOST POSTGRES_PASSWORD POSTGRES_DATABASE; do \
	  if [ -n "$$(printenv $$v)" ]; then \
	    echo "  [OK]    $$v"; \
	  else \
	    echo "  [MISS]  $$v"; \
	  fi; \
	done
	@echo ""
	@echo "=== Sentry ==="
	@for v in SENTRY_AUTH_TOKEN; do \
	  if [ -n "$$(printenv $$v)" ]; then \
	    echo "  [OK]    $$v"; \
	  else \
	    echo "  [MISS]  $$v"; \
	  fi; \
	done

# === Cleanup

## Remove build artefacts and node_modules
clear:
	rm -rf node_modules .next

## Drop the local Supabase DB volumes (purge all data)
clear-db:
	pnpm supabase stop --no-backup
