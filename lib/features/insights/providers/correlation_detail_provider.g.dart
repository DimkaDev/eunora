// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'correlation_detail_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$correlationDetailHash() => r'389b4ac6cc8cf8c612884c45bc1cb1f06e3ce93e';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [correlationDetail].
@ProviderFor(correlationDetail)
const correlationDetailProvider = CorrelationDetailFamily();

/// See also [correlationDetail].
class CorrelationDetailFamily extends Family<AsyncValue<CorrelationDetail>> {
  /// See also [correlationDetail].
  const CorrelationDetailFamily();

  /// See also [correlationDetail].
  CorrelationDetailProvider call(
    String correlationId,
  ) {
    return CorrelationDetailProvider(
      correlationId,
    );
  }

  @override
  CorrelationDetailProvider getProviderOverride(
    covariant CorrelationDetailProvider provider,
  ) {
    return call(
      provider.correlationId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'correlationDetailProvider';
}

/// See also [correlationDetail].
class CorrelationDetailProvider
    extends AutoDisposeFutureProvider<CorrelationDetail> {
  /// See also [correlationDetail].
  CorrelationDetailProvider(
    String correlationId,
  ) : this._internal(
          (ref) => correlationDetail(
            ref as CorrelationDetailRef,
            correlationId,
          ),
          from: correlationDetailProvider,
          name: r'correlationDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$correlationDetailHash,
          dependencies: CorrelationDetailFamily._dependencies,
          allTransitiveDependencies:
              CorrelationDetailFamily._allTransitiveDependencies,
          correlationId: correlationId,
        );

  CorrelationDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.correlationId,
  }) : super.internal();

  final String correlationId;

  @override
  Override overrideWith(
    FutureOr<CorrelationDetail> Function(CorrelationDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CorrelationDetailProvider._internal(
        (ref) => create(ref as CorrelationDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        correlationId: correlationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<CorrelationDetail> createElement() {
    return _CorrelationDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CorrelationDetailProvider &&
        other.correlationId == correlationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, correlationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CorrelationDetailRef on AutoDisposeFutureProviderRef<CorrelationDetail> {
  /// The parameter `correlationId` of this provider.
  String get correlationId;
}

class _CorrelationDetailProviderElement
    extends AutoDisposeFutureProviderElement<CorrelationDetail>
    with CorrelationDetailRef {
  _CorrelationDetailProviderElement(super.provider);

  @override
  String get correlationId =>
      (origin as CorrelationDetailProvider).correlationId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
