import 'package:vikunja_app/core/network/remote_data_source.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/data/models/user_dto.dart';
import 'package:vikunja_app/data/models/user_project_dto.dart';

class UserProjectDataSource extends RemoteDataSource {
  UserProjectDataSource(super.client);

  Future<Response<List<UserDto>>> getAll(int projectId) {
    return client.get(
      url: '/projects/$projectId/users',
      mapper: (body) {
        return convertList(body, (result) => UserDto.fromJson(result));
      },
    );
  }

  Future<Response<void>> create(UserProjectDto share) {
    return client.put(
      url: '/projects/${share.projectId}/users',
      body: share.toJSON(),
    );
  }

  Future<Response<UserProjectDto>> update(UserProjectDto share) {
    return client.post(
      url: '/projects/${share.projectId}/users/${share.username}',
      body: share.toJSON(),
      mapper: (body) => UserProjectDto.fromJson(body),
    );
  }

  Future<Response<void>> delete(int projectId, String username) {
    return client.delete(
      url: '/projects/$projectId/users/$username',
    );
  }
}