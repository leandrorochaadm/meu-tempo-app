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

# Roda o app no Chrome (PWA)
run:
	flutter run -d chrome

# Análise estática (manter zero issues)
analyze:
	flutter analyze

# Build de produção do PWA — sem cache (sempre online)
build:
	flutter build web --release --pwa-strategy=none
