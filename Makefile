# Atalhos de desenvolvimento — Meu Tempo
.PHONY: gen watch test run run-ios run-ios-debug run-ios-release run-android run-android-debug run-android-release analyze build deploy ship

# Gera código (json_serializable + injectable)
gen:
	dart run build_runner build --delete-conflicting-outputs

# Regenera automaticamente ao salvar
watch:
	dart run build_runner watch --delete-conflicting-outputs

# Testes com cobertura
test:
	flutter test --coverage

# Mantém a sessão do Firebase Auth entre execuções em dev. São DUAS condições
# necessárias (uma só não basta):
#   1. Perfil fixo do Chrome  → o IndexedDB (onde vive a sessão) não é descartado.
#   2. Porta fixa             → o IndexedDB é isolado por origem (host:porta);
#                               porta aleatória a cada run = outra origem = login perdido.
# Diretório de perfil ignorado pelo git.
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

# Build + deploy completo no Firebase num único comando.
# Depende de `build`: o Make roda o build antes e só então publica.
# Publica a página (Hosting), as regras e os índices do Firestore.
deploy: build
	firebase deploy --only hosting,firestore:rules,firestore:indexes

# Pipeline completa "tudo de uma vez": analisa, testa e faz build + deploy.
# Cada etapa é pré-requisito da próxima e o Make PARA na primeira que falhar —
# se o analyze acusar issue ou um teste quebrar, o deploy não acontece.
ship: analyze test deploy
