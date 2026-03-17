import 'package:vikunja_app/core/network/remote_data_source.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/data/models/team_dto.dart';
import 'package:vikunja_app/data/models/team_project_dto.dart';

class TeamProjectDataSource extends RemoteDataSource {
  TeamProjectDataSource(super.client);

  Future<Response<List<TeamDto>>> getAll(int projectId) {
    return client.get(
      url: '/projects/$projectId/teams',
      mapper: (body) {
        return convertList(body, (result) => TeamDto.fromJson(result));
      },
    );
  }

  Future<Response<void>> create(TeamProjectDto share) {
    return client.put(
      url: '/projects/${share.projectId}/teams',
      body: share.toJSON(),
    );
  }

  Future<Response<TeamProjectDto>> update(TeamProjectDto share) {
    return client.post(
      url: '/projects/${share.projectId}/teams/${share.teamId}',
      body: share.toJSON(),
      mapper: (body) => TeamProjectDto.fromJson(body),
    );
  }

  Future<Response<void>> delete(int projectId, int teamId) {
    return client.delete(
      url: '/projects/$projectId/teams/$teamId',
    );
  }
}