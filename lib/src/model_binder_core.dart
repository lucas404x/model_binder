/// Defines a function that will be invoked when the property changed.
typedef PropertyCallBack = void Function(Object? value);

class _PropertyBind {
  const _PropertyBind({
    required this.targetProperty,
    required this.onPropertyChanged,
  });

  final String targetProperty;
  final PropertyCallBack onPropertyChanged;

  @override
  int get hashCode => Object.hashAll([targetProperty, onPropertyChanged]);

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PropertyBind &&
        targetProperty == other.targetProperty &&
        onPropertyChanged == other.onPropertyChanged;
  }

  @override
  String toString() => 'PropertyBind(targetProperty: $targetProperty, onPropertyChanged: $onPropertyChanged)';
}

class _PropertyPendingChanges {
  const _PropertyPendingChanges({
    required this.targetProperty,
    required this.updatedValue,
  });

  final String targetProperty;
  final Object? updatedValue;

  @override
  int get hashCode => Object.hashAll([targetProperty, updatedValue]);

  @override
  operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is _PropertyPendingChanges &&
        targetProperty == other.targetProperty &&
        updatedValue == other.updatedValue;
  }
}

enum _Transaction {
  noTransaction,
  inTransaction,
  startCommit;

  bool get isRunning => this != _Transaction.noTransaction;
}

/// A mixin that adds the function for models to notify listeners after a property has changed in a model.
mixin ModelBinder {
  final _binds = <_PropertyBind>[];

  var _transacion = _Transaction.noTransaction;
  final _pendingPropertyChanges = <_PropertyPendingChanges>{};

  /// Attach the callback [onPropertyChanged] to a given [property] of the model.
  void bind(String property, PropertyCallBack onPropertyChanged) {
    _binds.add(_PropertyBind(targetProperty: property, onPropertyChanged: onPropertyChanged));
  }

  /// Notifies listeners that have attached to the [property] that it has changed.
  /// This function is usually called by the model itself.
  void notify(String property, Object? newValue) {
    if (_transacion == _Transaction.inTransaction) {
      _pendingPropertyChanges.add(_PropertyPendingChanges(targetProperty: property, updatedValue: newValue));
      return;
    }

    final $binds = _binds.where((bind) => bind.targetProperty == property).toList();
    for (var bind in $binds) {
      bind.onPropertyChanged(newValue);
    }
  }

  /// Starts a transaction that disables notification of property changes until [commit] is called.
  /// Multiple property changes can be made within a transaction, but listeners will not be notified until it is committed.
  ///
  /// Note: This does not prevent the properties from being updated, only the listeners will not be notified.
  void startTransaction() {
    if (!_transacion.isRunning) {
      _transacion = _Transaction.inTransaction;
    }
  }

  /// Notify all listeners about the last properties changes and enable the notifier functionaly again.
  void commit() {
    try {
      _transacion = _Transaction.startCommit;
      for (var pendingChanges in _pendingPropertyChanges) {
        notify(pendingChanges.targetProperty, pendingChanges.updatedValue);
      }
    } catch (_) {
      rethrow;
    } finally {
      _pendingPropertyChanges.clear();
      _transacion = _Transaction.noTransaction;
    }
  }

  /// Remove the bind attached to the [property] and the [onPropertyChanged].
  ///
  /// If multiple [onPropertyChanged] functions are attached to the same [property],
  /// it is important to pass the exact function that was used to add the binding to avoid deleting the wrong one.
  void removeBind(String property, PropertyCallBack onPropertyChanged) {
    final bindToRemove = _PropertyBind(targetProperty: property, onPropertyChanged: onPropertyChanged);
    _binds.removeWhere((b) => b == bindToRemove);
  }

  /// Remove all binds attached to this model.
  void removeAllBinds() {
    _binds.clear();
  }
}
