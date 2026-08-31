.PHONY: bootstrap up down api admin mobile test lint health

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
	cd apps/mobile && flutter run

test:
	pnpm --filter @freeva/api test
	@if [ -d apps/mobile ]; then cd apps/mobile && flutter test; fi

lint:
	pnpm --filter @freeva/web-admin lint
	pnpm --filter @freeva/api build
	@if [ -d apps/mobile ]; then cd apps/mobile && flutter analyze; fi

health:
	curl -sf http://localhost:4000/api/health | python3 -m json.tool
