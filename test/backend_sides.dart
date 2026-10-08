/// The backend fixtures carry nl/en; the app's engine ports also write the
/// other languages. Parity is on the sides both write, so drop the rest.
Object? backendSides(Object? j) => switch (j) {
      Map() => {
          for (final e in j.entries)
            if (!const {'de', 'fr', 'sv', 'pt'}.contains(e.key)) e.key: backendSides(e.value),
        },
      List() => [for (final x in j) backendSides(x)],
      _ => j,
    };
