/// Makes the [GardenRepository] available to the widget tree and rebuilds
/// dependents when it notifies. A tiny hand-rolled provider — no state-mgmt
/// dependency for the prototype.
library;

import 'package:flutter/widgets.dart';

import 'garden/garden_repository.dart';

class RepositoryScope extends InheritedNotifier<GardenRepository> {
  const RepositoryScope({
    super.key,
    required GardenRepository repository,
    required super.child,
  }) : super(notifier: repository);

  static GardenRepository of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<RepositoryScope>();
    assert(scope?.notifier != null, 'No RepositoryScope in the widget tree');
    return scope!.notifier!;
  }
}
