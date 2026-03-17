class UserProject {
  int projectId;
  String username;
  int permission;

  UserProject({
    this.projectId = 0,
    this.username = '',
    this.permission = 0,
  });

  UserProject copyWith({
    int? projectId,
    String? username,
    int? permission,
  }) {
    return UserProject(
      projectId: projectId ?? this.projectId,
      username: username ?? this.username,
      permission: permission ?? this.permission,
    );
  }
}