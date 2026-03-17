import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/team_member.dart';

abstract class TeamMemberRepository {
  Future<Response<List<TeamMember>>> getAll(int teamId);

  Future<Response<void>> create(TeamMember member);

  Future<Response<void>> update(TeamMember member);

  Future<Response<void>> delete(int teamId, String username);
}
