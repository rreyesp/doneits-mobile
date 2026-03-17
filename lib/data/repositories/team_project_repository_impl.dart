import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/core/utils/mapping_extensions.dart';
import 'package:vikunja_app/data/data_sources/team_project_data_source.dart';
import 'package:vikunja_app/data/models/team_project_dto.dart';
import 'package:vikunja_app/domain/entities/team.dart';
import 'package:vikunja_app/domain/entities/team_project.dart';
import 'package:vikunja_app/domain/repositories/team_project_repository.dart';

class TeamProjectRepositoryImpl extends TeamProjectRepository {
  final TeamProjectDataSource _dataSource;

  TeamProjectRepositoryImpl(this._dataSource);

  @override
  Future<Response<List<Team>>> getAll(int projectId) async {
    return (await _dataSource.getAll(projectId)).toDomain();
  }

  @override
  Future<Response<void>> create(TeamProject share) {
    return _dataSource.create(TeamProjectDto.fromDomain(share));
  }

  @override
  Future<Response<TeamProject>> update(TeamProject share) async {
    return (await _dataSource.update(TeamProjectDto.fromDomain(share)))
        .toDomain();
  }

  @override
  Future<Response<void>> delete(int projectId, int teamId) {
    return _dataSource.delete(projectId, teamId);
  }
}