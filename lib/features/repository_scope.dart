/// Makes the [GardenRepository] available to the widget tree and rebuilds
/// dependents when it notifies. A tiny hand-rolled provider — no state-mgmt
/// dependency for the prototype.
library;

import 'package:flutter/widgets.dart';

import '../purchases/purchase_service.dart';
import '../sync/auth_service.dart';
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

/// Auth + sync, optional: tests and the pure-offline path run without it.
class AuthScope extends InheritedNotifier<AuthService> {
  const AuthScope({super.key, required AuthService? auth, required super.child}) : super(notifier: auth);

  static AuthService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.notifier;
}

class PurchaseScope extends InheritedNotifier<PurchaseService> {
  const PurchaseScope({super.key, required PurchaseService? purchases, required super.child}) : super(notifier: purchases);

  static PurchaseService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PurchaseScope>()?.notifier;
}
