import 'package:vikunja_app/core/network/remote_data_source.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/data/models/team_dto.dart';

class TeamDataSource extends RemoteDataSource {
  TeamDataSource(super.client);

  Future<Response<TeamDto>> create(TeamDto team) {
    return client.put(
      url: '/teams',
      body: team.toJSON(),
      mapper: (body) => TeamDto.fromJson(body),
    );
  }

  Future<Response<TeamDto>> get(int id) {
    return client.get(
      url: '/teams/$id',
      mapper: (body) => TeamDto.fromJson(body),
    );
  }

  Future<Response<List<TeamDto>>> getAll() {
    return client.get(
      url: '/teams',
      mapper: (body) {
        return convertList(body, (result) => TeamDto.fromJson(result));
      },
    );
  }

  Future<Response<TeamDto>> update(TeamDto team) {
    return client.post(
      url: '/teams/${team.id}',
      body: team.toJSON(),
      mapper: (body) => TeamDto.fromJson(body),
    );
  }

  Future<Response<void>> delete(int id) {
    return client.delete(url: '/teams/$id');
  }
}
