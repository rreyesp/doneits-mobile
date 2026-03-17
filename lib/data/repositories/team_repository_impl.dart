import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/core/utils/mapping_extensions.dart';
import 'package:vikunja_app/data/data_sources/team_data_source.dart';
import 'package:vikunja_app/data/models/team_dto.dart';
import 'package:vikunja_app/domain/entities/team.dart';
import 'package:vikunja_app/domain/repositories/team_repository.dart';

class TeamRepositoryImpl extends TeamRepository {
  final TeamDataSource _dataSource;

  TeamRepositoryImpl(this._dataSource);

  @override
  Future<Response<Team>> create(Team team) async {
    return (await _dataSource.create(TeamDto.fromDomain(team))).toDomain();
  }

  @override
  Future<Response<Team>> get(int id) async {
    return (await _dataSource.get(id)).toDomain();
  }

  @override
  Future<Response<List<Team>>> getAll() async {
    return (await _dataSource.getAll()).toDomain();
  }

  @override
  Future<Response<Team>> update(Team team) async {
    return (await _dataSource.update(TeamDto.fromDomain(team))).toDomain();
  }

  @override
  Future<Response<void>> delete(int id) {
    return _dataSource.delete(id);
  }
}
