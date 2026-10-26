# Atalhos de desenvolvimento — Meu Tempo
.PHONY: pb pb-superuser pb-test pb-check gen watch test run run-ios run-ios-debug run-ios-release run-android run-android-debug run-android-release analyze build ship

# PocketBase local descartável em 127.0.0.1:8095
pb:
	tool/pb.sh serve

# Cria/atualiza o superusuário local: make pb-superuser EMAIL=voce@exemplo.com
pb-superuser:
	@test -n "$(EMAIL)" || { echo "Uso: make pb-superuser EMAIL=voce@exemplo.com"; exit 1; }
	tool/pb.sh superuser $(EMAIL)

# Testes de permissão de dono (precisa do `make pb` rodando)
pb-test:
	uv run tool/pb_permissions_test.py

# Valida migrations e API Rules (skill pocketbase-db)
pb-check:
	uv run ~/.claude/skills/pocketbase-db/scripts/pb_check.py

# Gera código (json_serializable + injectable)
gen:
	dart run build_runner build --delete-conflicting-outputs

# Regenera automaticamente ao salvar
watch:
	dart run build_runner watch --delete-conflicting-outputs

# Testes com cobertura
test:
	flutter test --coverage

# Keeps the login session between dev runs. Both conditions are required:
#   1. Fixed Chrome profile -> browser storage (where the session lives) is kept.
#   2. Fixed port           -> storage is isolated per origin (host:port);
#                              a random port each run = new origin = login lost.
# Profile directory ignored by git.
CHROME_PROFILE := $(CURDIR)/.dev-chrome
WEB_PORT       := 5555

# Per-environment build config. A missing file compiles without config (the app
# shows the "not configured" screen), so `make build` works before prod.json exists.
DEV_CONFIG  := config/dev.json
PROD_CONFIG := config/prod.json
config_flag = $(if $(wildcard $(1)),--dart-define-from-file=$(1),)

# Roda o app no Chrome (PWA) com perfil e porta fixos
run:
	flutter run -d chrome \
		--web-port=$(WEB_PORT) \
		--web-browser-flag="--user-data-dir=$(CHROME_PROFILE)" \
		$(call config_flag,$(DEV_CONFIG))

# Configuração local por máquina (fora do git). Modelo em .env.example.
-include .env

# Roda o app nativo no iPhone de dev (via fvm). UDID vem de IOS_DEVICE no .env.
# `run-ios` é atalho para o modo debug.
run-ios: run-ios-debug

run-ios-debug:
	@test -n "$(IOS_DEVICE)" || { echo "Defina IOS_DEVICE no .env (veja .env.example)"; exit 1; }
	fvm flutter run --debug -d $(IOS_DEVICE) $(call config_flag,$(PROD_CONFIG))

# Release no iPhone: necessário para testar com o app fechado (botões da tela
# bloqueada). Em debug, o iOS não deixa o Dart rodar sem o Xcode/flutter
# conectado, então o app reaberto em segundo plano não executa nada.
run-ios-release:
	@test -n "$(IOS_DEVICE)" || { echo "Defina IOS_DEVICE no .env (veja .env.example)"; exit 1; }
	fvm flutter run --release -d $(IOS_DEVICE) $(call config_flag,$(PROD_CONFIG))

# Roda o app nativo no Android de dev (via fvm). ID vem de ANDROID_DEVICE no .env.
# `run-android` é atalho para o modo debug.
run-android: run-android-debug

run-android-debug:
	@test -n "$(ANDROID_DEVICE)" || { echo "Defina ANDROID_DEVICE no .env (veja .env.example)"; exit 1; }
	fvm flutter run --debug -d $(ANDROID_DEVICE) $(call config_flag,$(PROD_CONFIG))

# Release no Android: comportamento real com o app fechado/em segundo plano.
run-android-release:
	@test -n "$(ANDROID_DEVICE)" || { echo "Defina ANDROID_DEVICE no .env (veja .env.example)"; exit 1; }
	fvm flutter run --release -d $(ANDROID_DEVICE) $(call config_flag,$(PROD_CONFIG))

# Análise estática (manter zero issues)
analyze:
	flutter analyze

# Build de produção do PWA — sem cache (sempre online)
build:
	flutter build web --release --pwa-strategy=none $(call config_flag,$(PROD_CONFIG))

# Full local pipeline: static analysis, then tests.
# Make stops at the first failing step. Publishing is done by the PWA workflow.
ship: analyze test
