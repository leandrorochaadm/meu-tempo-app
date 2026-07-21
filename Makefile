# Atalhos de desenvolvimento — Meu Tempo
.PHONY: gen watch test run analyze build

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

# Roda o app no Chrome (PWA) com perfil e porta fixos
run:
	flutter run -d chrome \
		--web-port=$(WEB_PORT) \
		--web-browser-flag="--user-data-dir=$(CHROME_PROFILE)"

# Análise estática (manter zero issues)
analyze:
	flutter analyze

# Build de produção do PWA — sem cache (sempre online)
build:
	flutter build web --release --pwa-strategy=none
