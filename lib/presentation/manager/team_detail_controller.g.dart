// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team_detail_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$teamDetailControllerHash() =>
    r'8d402a696a065cebb348bf129c809eaa7787dd8d';

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

abstract class _$TeamDetailController
    extends BuildlessAutoDisposeAsyncNotifier<Team> {
  late final int teamId;

  FutureOr<Team> build(int teamId);
}

/// See also [TeamDetailController].
@ProviderFor(TeamDetailController)
const teamDetailControllerProvider = TeamDetailControllerFamily();

/// See also [TeamDetailController].
class TeamDetailControllerFamily extends Family<AsyncValue<Team>> {
  /// See also [TeamDetailController].
  const TeamDetailControllerFamily();

  /// See also [TeamDetailController].
  TeamDetailControllerProvider call(int teamId) {
    return TeamDetailControllerProvider(teamId);
  }

  @override
  TeamDetailControllerProvider getProviderOverride(
    covariant TeamDetailControllerProvider provider,
  ) {
    return call(provider.teamId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'teamDetailControllerProvider';
}

/// See also [TeamDetailController].
class TeamDetailControllerProvider
    extends AutoDisposeAsyncNotifierProviderImpl<TeamDetailController, Team> {
  /// See also [TeamDetailController].
  TeamDetailControllerProvider(int teamId)
    : this._internal(
        () => TeamDetailController()..teamId = teamId,
        from: teamDetailControllerProvider,
        name: r'teamDetailControllerProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$teamDetailControllerHash,
        dependencies: TeamDetailControllerFamily._dependencies,
        allTransitiveDependencies:
            TeamDetailControllerFamily._allTransitiveDependencies,
        teamId: teamId,
      );

  TeamDetailControllerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.teamId,
  }) : super.internal();

  final int teamId;

  @override
  FutureOr<Team> runNotifierBuild(covariant TeamDetailController notifier) {
    return notifier.build(teamId);
  }

  @override
  Override overrideWith(TeamDetailController Function() create) {
    return ProviderOverride(
      origin: this,
      override: TeamDetailControllerProvider._internal(
        () => create()..teamId = teamId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        teamId: teamId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<TeamDetailController, Team>
  createElement() {
    return _TeamDetailControllerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TeamDetailControllerProvider && other.teamId == teamId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, teamId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin TeamDetailControllerRef on AutoDisposeAsyncNotifierProviderRef<Team> {
  /// The parameter `teamId` of this provider.
  int get teamId;
}

class _TeamDetailControllerProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<TeamDetailController, Team>
    with TeamDetailControllerRef {
  _TeamDetailControllerProviderElement(super.provider);

  @override
  int get teamId => (origin as TeamDetailControllerProvider).teamId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
