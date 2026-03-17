import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/domain/entities/user_project.dart';

abstract class UserProjectRepository {
  Future<Response<List<User>>> getAll(int projectId);

  Future<Response<void>> create(UserProject share);

  Future<Response<UserProject>> update(UserProject share);

  Future<Response<void>> delete(int projectId, String username);
}