import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/core/utils/mapping_extensions.dart';
import 'package:vikunja_app/data/data_sources/user_project_data_source.dart';
import 'package:vikunja_app/data/models/user_project_dto.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/domain/entities/user_project.dart';
import 'package:vikunja_app/domain/repositories/user_project_repository.dart';

class UserProjectRepositoryImpl extends UserProjectRepository {
  final UserProjectDataSource _dataSource;

  UserProjectRepositoryImpl(this._dataSource);

  @override
  Future<Response<List<User>>> getAll(int projectId) async {
    return (await _dataSource.getAll(projectId)).toDomain();
  }

  @override
  Future<Response<void>> create(UserProject share) {
    return _dataSource.create(UserProjectDto.fromDomain(share));
  }

  @override
  Future<Response<UserProject>> update(UserProject share) async {
    return (await _dataSource.update(UserProjectDto.fromDomain(share)))
        .toDomain();
  }

  @override
  Future<Response<void>> delete(int projectId, String username) {
    return _dataSource.delete(projectId, username);
  }
}