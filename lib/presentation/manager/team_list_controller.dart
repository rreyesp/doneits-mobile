import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/team.dart';

part 'team_list_controller.g.dart';

@riverpod
class TeamListController extends _$TeamListController {
  @override
  Future<List<Team>> build() async {
    final response = await ref.read(teamRepositoryProvider).getAll();

    switch (response) {
      case SuccessResponse<List<Team>>():
        return response.body;
      case ErrorResponse<List<Team>>():
        throw Exception(response.error.toString());
      case ExceptionResponse<List<Team>>():
        throw Exception(response.message);
    }
  }

  Future<void> reload() async {
    final response = await ref.read(teamRepositoryProvider).getAll();

    switch (response) {
      case SuccessResponse<List<Team>>():
        state = AsyncData(response.body);
      case ErrorResponse<List<Team>>():
        state = AsyncError(response.error, StackTrace.current);
      case ExceptionResponse<List<Team>>():
        state = AsyncError(response.message, StackTrace.current);
    }
  }

  Future<bool> addTeam(Team team) async {
    final response = await ref.read(teamRepositoryProvider).create(team);
    if (response.isSuccessful) {
      await reload();
      return true;
    }
    return false;
  }
}
