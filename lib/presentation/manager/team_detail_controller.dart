import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/team.dart';
import 'package:vikunja_app/domain/entities/team_member.dart';

part 'team_detail_controller.g.dart';

@riverpod
class TeamDetailController extends _$TeamDetailController {
  late int _teamId;

  @override
  Future<Team> build(int teamId) async {
    _teamId = teamId;

    final teamResponse = await ref.read(teamRepositoryProvider).get(teamId);

    switch (teamResponse) {
      case SuccessResponse<Team>():
        final membersResponse = await ref
            .read(teamMemberRepositoryProvider)
            .getAll(teamId);

        switch (membersResponse) {
          case SuccessResponse<List<TeamMember>>():
            return teamResponse.body.copyWith(members: membersResponse.body);
          case ErrorResponse<List<TeamMember>>():
            return teamResponse.body;
          case ExceptionResponse<List<TeamMember>>():
            return teamResponse.body;
        }
      case ErrorResponse<Team>():
        throw Exception(teamResponse.error.toString());
      case ExceptionResponse<Team>():
        throw Exception(teamResponse.message);
    }
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => build(_teamId));
  }

  Future<bool> updateTeam(Team team) async {
    final response = await ref.read(teamRepositoryProvider).update(team);
    if (response.isSuccessful) {
      await reload();
      return true;
    }
    return false;
  }

  Future<(bool, String?)> addMember({
  required int teamId,
  required int userId,
  required String username,
  String name = '',
  bool admin = false,
}) async {
  final response = await ref
      .read(teamMemberRepositoryProvider)
      .create(
        TeamMember(
          id: userId,
          username: username,
          name: name,
          admin: admin,
          teamId: teamId,
        ),
      );

  if (response.isSuccessful) {
    await reload();
    return (true, null);
  }

  if (response.isError) {
    return (false, response.toError().error.toString());
  }

  if (response.isException) {
    return (false, response.toException().message);
  }

  return (false, 'Unknown error');
}


 Future<bool> toggleAdmin(TeamMember member) async {
  final updated = TeamMember(
    id: member.id,
    username: member.username,
    name: member.name,
    created: member.created,
    updated: member.updated,
    settings: member.settings,
    teamId: member.teamId,
    admin: !member.admin,
  );

  final response = await ref
      .read(teamMemberRepositoryProvider)
      .update(updated);

  if (response.isSuccessful) {
    await reload();
    return true;
  }
  return false;
}

  Future<bool> removeMember({
    required int teamId,
    required String username,
  }) async {
    final response = await ref
        .read(teamMemberRepositoryProvider)
        .delete(teamId, username);

    if (response.isSuccessful) {
      await reload();
      return true;
    }
    return false;
  }
}
