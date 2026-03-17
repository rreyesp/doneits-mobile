import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/team.dart';
import 'package:vikunja_app/domain/entities/team_project.dart';

abstract class TeamProjectRepository {
  Future<Response<List<Team>>> getAll(int projectId);

  Future<Response<void>> create(TeamProject share);

  Future<Response<TeamProject>> update(TeamProject share);

  Future<Response<void>> delete(int projectId, int teamId);
}