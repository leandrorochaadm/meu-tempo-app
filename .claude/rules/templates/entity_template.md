---
paths:
  - "lib/features/*/domain/entities/**"
---

# Entity Template

```dart
import 'package:equatable/equatable.dart';

class {Feature}Entity extends Equatable {
  final String id;
  final String name;

  {Feature}Entity({
    required this.id,
    required this.name,
  });

  // Regra intrínseca ao objeto (opcional)
  bool get isValid => id.isNotEmpty && name.isNotEmpty;

  @override
  List<Object?> get props => [id, name];
}
```

## Com coleções (unmodifiable obrigatório)

```dart
class {Feature}Entity extends Equatable {
  final String id;
  final List<{Item}Entity> items;

  {Feature}Entity({
    required this.id,
    required List<{Item}Entity> items,
  }) : items = List.unmodifiable(items);

  @override
  List<Object?> get props => [id, items];
}
```

## Rules
- extends `Equatable` + implementa `props`.
- SEM `copyWith()`, SEM `fromJson/toJson/fromMap/toMap`, SEM `Map<String,dynamic>`.
- Coleções com `List/Map/Set.unmodifiable`.
- Só importa `equatable` (e, se necessário, tipos de domínio).
- Regras que dependem de dados externos (data atual, outra entity) → UseCase, não Entity.
