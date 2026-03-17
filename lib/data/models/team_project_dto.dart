import 'package:vikunja_app/data/models/dto.dart';
import 'package:vikunja_app/domain/entities/team_project.dart';

class TeamProjectDto extends Dto<TeamProject> {
  final int projectId;
  final int teamId;
  final int permission;

  TeamProjectDto({
    this.projectId = 0,
    this.teamId = 0,
    this.permission = 0,
  });

  TeamProjectDto.fromJson(Map<String, dynamic> json)
    : projectId = json['project_id'] ?? 0,
      teamId = json['team_id'] ?? 0,
      permission = json['permission'] ?? 0;

  Map<String, dynamic> toJSON() => {
    'project_id': projectId,
    'team_id': teamId,
    'permission': permission,
  };

  @override
  TeamProject toDomain() => TeamProject(
    projectId: projectId,
    teamId: teamId,
    permission: permission,
  );

  static TeamProjectDto fromDomain(TeamProject share) => TeamProjectDto(
    projectId: share.projectId,
    teamId: share.teamId,
    permission: share.permission,
  );
}