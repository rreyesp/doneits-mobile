import 'package:vikunja_app/data/models/dto.dart';
import 'package:vikunja_app/domain/entities/user_project.dart';

class UserProjectDto extends Dto<UserProject> {
  final int projectId;
  final String username;
  final int permission;

  UserProjectDto({
    this.projectId = 0,
    this.username = '',
    this.permission = 0,
  });

  UserProjectDto.fromJson(Map<String, dynamic> json)
    : projectId = json['project_id'] ?? 0,
      username = json['username'] ?? '',
      permission = json['permission'] ?? 0;

  Map<String, dynamic> toJSON() => {
    'project_id': projectId,
    'username': username,
    'permission': permission,
  };

  @override
  UserProject toDomain() => UserProject(
    projectId: projectId,
    username: username,
    permission: permission,
  );

  static UserProjectDto fromDomain(UserProject share) => UserProjectDto(
    projectId: share.projectId,
    username: share.username,
    permission: share.permission,
  );
}