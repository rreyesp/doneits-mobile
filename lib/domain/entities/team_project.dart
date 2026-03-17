class TeamProject {
  int projectId;
  int teamId;
  int permission;

  TeamProject({
    this.projectId = 0,
    this.teamId = 0,
    this.permission = 0,
  });

  TeamProject copyWith({
    int? projectId,
    int? teamId,
    int? permission,
  }) {
    return TeamProject(
      projectId: projectId ?? this.projectId,
      teamId: teamId ?? this.teamId,
      permission: permission ?? this.permission,
    );
  }
}