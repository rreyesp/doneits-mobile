import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/team.dart';

abstract class TeamRepository {
  Future<Response<Team>> create(Team team);

  Future<Response<Team>> get(int id);

  Future<Response<List<Team>>> getAll();

  Future<Response<Team>> update(Team team);

  Future<Response<void>> delete(int id);
}
