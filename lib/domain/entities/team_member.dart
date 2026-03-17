import 'package:vikunja_app/domain/entities/user.dart';

class TeamMember extends User {
  bool admin;
  int teamId;

  TeamMember({
    this.admin = false,
    this.teamId = 0,
    super.id = 0,
    super.name = '',
    required super.username,
    super.created,
    super.updated,
    super.settings,
  });
}
