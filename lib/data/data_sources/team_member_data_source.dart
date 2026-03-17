import 'package:vikunja_app/core/network/remote_data_source.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/data/models/team_member_dto.dart';

class TeamMemberDataSource extends RemoteDataSource {
  TeamMemberDataSource(super.client);

  Future<Response<List<TeamMemberDto>>> getAll(int teamId) {
    return client.get(
      url: '/teams/$teamId/members',
      mapper: (body) {
        return convertList(body, (result) => TeamMemberDto.fromJson(result));
      },
    );
  }

  Future<Response<void>> create(TeamMemberDto member) {
    return client.put(
      url: '/teams/${member.teamId}/members',
      body: member.toJSON(),
    );
  }

  Future<Response<void>> update(TeamMemberDto member) {
    return client.post(
      url: '/teams/${member.teamId}/members/${member.username}/admin',
      body: member.toUpdateJSON(),
    );
  }

  Future<Response<void>> delete(int teamId, String username) {
    return client.delete(
      url: '/teams/$teamId/members/$username',
    );
  }
}
