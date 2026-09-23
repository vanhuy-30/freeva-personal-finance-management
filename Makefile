.PHONY: bootstrap up down api admin mobile test lint health

FLUTTER ?= fvm flutter
MOBILE_ENV ?= staging

COMPOSE := docker compose -f infra/compose/docker-compose.yml --env-file .env.example

bootstrap:
	pnpm install
	pnpm --filter @freeva/api exec prisma generate
	cd apps/mobile && flutter pub get

up:
	$(COMPOSE) up -d

down:
	$(COMPOSE) down

api:
	pnpm --filter @freeva/api start:dev

admin:
	pnpm --filter @freeva/web-admin dev

mobile:
	cd apps/mobile && $(FLUTTER) run --dart-define-from-file=config/$(MOBILE_ENV).json

test:
	pnpm --filter @freeva/api test
	@if [ -d apps/mobile ]; then cd apps/mobile && flutter test; fi

lint:
	pnpm --filter @freeva/web-admin lint
	pnpm --filter @freeva/api build
	@if [ -d apps/mobile ]; then cd apps/mobile && flutter analyze; fi

health:
	curl -sf http://localhost:4000/api/health | python3 -m json.tool

.PHONY: dev-https-setup dev-https
dev-https-setup:
	bash infra/dev/setup-https.sh

dev-https:
	node infra/dev/https-proxy.cjs

.PHONY: dev-https-lan mobile-dev mobile-dev-android mobile-dev-device mobile-staging
# Expose only the HTTPS proxy to devices on a trusted LAN.
dev-https-lan:
	DEV_HTTPS_BIND=0.0.0.0 node infra/dev/https-proxy.cjs

mobile-dev:
	$(MAKE) mobile MOBILE_ENV=dev

mobile-dev-android:
	$(MAKE) mobile MOBILE_ENV=dev-android

mobile-dev-device:
	$(MAKE) mobile MOBILE_ENV=dev-device

mobile-staging:
	$(MAKE) mobile MOBILE_ENV=staging

.PHONY: dev-up api-dev
dev-up:
	$(COMPOSE) up -d postgres mailhog

# Override mail transport for local development; preserve Resend secrets in .env.
api-dev:
	NODE_ENV=development MAIL_PROVIDER=smtp MAIL_FROM='Freeva <noreply@example.test>' SMTP_HOST=127.0.0.1 SMTP_PORT=1025 SMTP_SECURE=false SMTP_USER= SMTP_PASSWORD= pnpm --filter @freeva/api start:dev
