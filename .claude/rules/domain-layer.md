---
paths:
  - "lib/features/*/domain/**"
  - "lib/core/**"
---

# Domain Layer Rules

Camada de **Dart puro**. Só pode importar `equatable` e `fpdart` (tipos de apoio).
NUNCA importa Firebase, json, nem nada de `data/`/`presentation/`.

## Entities

- **MUST** extend `Equatable` e implementar `props`.
- **MUST NOT** ter `copyWith()` — imutabilidade pela estrutura.
- **MUST NOT** ter `Map<String, dynamic>` como propriedade.
- **MUST** usar `List.unmodifiable` / `Map.unmodifiable` / `Set.unmodifiable` em coleções.
- NUNCA contém `fromJson`/`toJson`/`fromMap`/`toMap` nem anotação de serialização.
- Contém regras de negócio **intrínsecas ao objeto** (validações, cálculos, estados derivados).

Pergunta-chave: _"O objeto SABE isso sobre si mesmo, sem depender de nada externo?"_ → Entity.

```dart
import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final int importance;          // 1..4 (1 = máxima)
  final DateTime? dueDate;
  final int estimatedMinutes;
  final List<TaskEntity> children;

  TaskEntity({
    required this.id,
    required this.title,
    required this.importance,
    required this.estimatedMinutes,
    this.dueDate,
    List<TaskEntity> children = const [],
  }) : children = List.unmodifiable(children);

  // Regras intrínsecas ao objeto
  bool get isLeaf => children.isEmpty;                 // folha = tem cronômetro
  int get totalEstimatedMinutes => isLeaf
      ? estimatedMinutes
      : children.fold(0, (sum, c) => sum + c.totalEstimatedMinutes);

  @override
  List<Object?> get props => [id, title, importance, dueDate, estimatedMinutes, children];
}
```

> Cálculo que **cruza dados fora do objeto** (data atual para urgência, outra tarefa)
> vai no **UseCase**, não na Entity. Ex.: a `prioridade` depende da data de hoje →
> `CalculatePriorityUseCase`.

## UseCases

- **MUST** implementar `UseCase<T, Params>` de `lib/core/usecase/usecase.dart`.
- **MUST** implementar `call(Params params)` (NÃO `execute()`).
- Usar `NoParams` quando não há parâmetros.
- Retornar `Either<Failure, T>` (**fpdart**).
- Classe `Params` **MUST** extend `Equatable`.
- Nome = **verbo** + sufixo `UseCase`.

Pergunta-chave: _"Precisa de algo FORA do objeto para executar essa regra?"_ → UseCase.

## Repository Interfaces (contratos)

- **MUST** usar apenas tipos Entity (nunca Model, nunca Map).
- Retornar `Either<Failure, T>` onde T é Entity, `List<Entity>`, `void`, `bool`, `String` ou `int`.
- Contratos puros de negócio — sem detalhe de implementação (Firestore não aparece aqui).

## Failures

- Carregam **dados**, NUNCA mensagens de texto — mensagem é responsabilidade da
  Presentation (`_mapFailure` no Bloc).
- `Failure` é `abstract class` em `lib/core/error/failures.dart`.
- Failures de infra ficam em `lib/core/error/failures.dart`.
- Failures de feature ficam em `features/{feature}/domain/failures/{feature}_failures.dart`.

```dart
import '../../../../core/error/failures.dart';

class TaskNotFoundFailure extends Failure {
  const TaskNotFoundFailure();
}

// Com dados específicos — sobrescreve props
class DayOverbookedFailure extends Failure {
  final int availableMinutes;
  final int plannedMinutes;

  const DayOverbookedFailure({
    required this.availableMinutes,
    required this.plannedMinutes,
  });

  @override
  List<Object?> get props => [availableMinutes, plannedMinutes];
}
```

## Imutabilidade — por que importa

`final` protege a **referência**, não o **conteúdo**: uma `List` mutável dentro da Entity
pode ser alterada de fora (`entity.children.add(...)`), gerando bug silencioso. Além disso,
o BLoC/Equatable só detecta mudança quando o objeto é **novo**. Receita sem Freezed:

```
1. final em todos os campos
2. List.unmodifiable / Map.unmodifiable / Set.unmodifiable em coleções
3. Equatable para comparação por valor
4. Para "copiar com modificação": construir novo objeto explicitamente no UseCase/Bloc
```

`EquatableConfig.stringify = true;` no `main()` facilita debug (toString mostra campos).

## Type Rules
- **ONLY** Entity no domínio; **NEVER** Model; **NEVER** `Map<String, dynamic>`.

## Templates
- Entity: `@.claude/rules/templates/entity_template.md`
- UseCase: `@.claude/rules/templates/usecase_template.md`
