# Flutter

Ánh xạ Flutter Starter Kit.

```
lib/
  core/           # di, theme, l10n, router, logging, network
  features/{name}/
    data/         # datasource, model, mapper, repository impl
    domain/       # entity, repository abstract, usecase
    presentation/ # pages, widgets, viewmodel
```

- View không gọi repository. ViewModel không `dart:ui` / `material.dart`.
- `get_it` + `injectable`; consume abstract.
- `Either<Failure, T>` từ domain/data.
- Không `print`. Không hardcode string/color.
- Widget > 100 dòng → file `widgets/`.
- Test: usecase + viewmodel.
