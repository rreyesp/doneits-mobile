import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/core/utils/mapping_extensions.dart';
import 'package:vikunja_app/data/data_sources/team_member_data_source.dart';
import 'package:vikunja_app/data/models/team_member_dto.dart';
import 'package:vikunja_app/domain/entities/team_member.dart';
import 'package:vikunja_app/domain/repositories/team_member_repository.dart';

class TeamMemberRepositoryImpl extends TeamMemberRepository {
  final TeamMemberDataSource _dataSource;

  TeamMemberRepositoryImpl(this._dataSource);

  @override
  Future<Response<List<TeamMember>>> getAll(int teamId) async {
    return (await _dataSource.getAll(teamId)).toDomain();
  }

  @override
  Future<Response<void>> create(TeamMember member) {
    return _dataSource.create(TeamMemberDto.fromDomain(member));
  }

  @override
  Future<Response<void>> update(TeamMember member) {
    return _dataSource.update(TeamMemberDto.fromDomain(member));
  }

  @override
  Future<Response<void>> delete(int teamId, String username) {
    return _dataSource.delete(teamId, username);
  }
}
