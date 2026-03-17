import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/team.dart';
import 'package:vikunja_app/domain/entities/team_member.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/manager/team_detail_controller.dart';
import 'package:vikunja_app/presentation/manager/team_list_controller.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/task/task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

class TeamListPage extends ConsumerStatefulWidget {
  const TeamListPage({super.key});

  @override
  ConsumerState<TeamListPage> createState() => _TeamListPageState();
}

class _TeamListPageState extends ConsumerState<TeamListPage> {
  bool _showCompletedTasks = false;
  final Set<int> _expandedTeams = {};
  final Map<int, Set<int>> _expandedProjects = {};
  final Map<int, Future<_TeamProjectsTasksData>> _teamDataFutures = {};

  @override
  void initState() {
    super.initState();
    _showCompletedTasks =
        ref.read(taskPageControllerProvider.notifier).showCompletedTasks;
  }

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(teamListControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Teams'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'toggle_completed') {
                final newValue = !_showCompletedTasks;
                setState(() {
                  _showCompletedTasks = newValue;
                });

                ref
                    .read(taskPageControllerProvider.notifier)
                    .setShowCompletedTasks(newValue);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                CheckedPopupMenuItem<String>(
                  value: 'toggle_completed',
                  checked: _showCompletedTasks,
                  child: const SizedBox(
                    width: 220,
                    child: Text(
                      'Show completed tasks',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: teamsAsync.when(
        data: (teams) {
          if (teams.isEmpty) {
            return const Center(
              child: Text(
                'No teams yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(teamListControllerProvider.notifier).reload();
              if (mounted) {
                setState(() {
                  _teamDataFutures.clear();
                });
              }
            },
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 88),
              itemCount: teams.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final team = teams[index];

                return _TeamProjectsCard(
                  team: team,
                  expanded: _expandedTeams.contains(team.id),
                  showCompletedTasks: _showCompletedTasks,
                  future: _getTeamDataFuture(team.id),
                  isProjectExpanded: (projectId) =>
                      _expandedProjects[team.id]?.contains(projectId) ?? false,
                  onToggleExpanded: () {
                    setState(() {
                      if (_expandedTeams.contains(team.id)) {
                        _expandedTeams.remove(team.id);
                      } else {
                        _expandedTeams.add(team.id);
                      }
                    });
                  },
                  onToggleProjectExpanded: (projectId) {
                    setState(() {
                      final set = _expandedProjects.putIfAbsent(
                        team.id,
                        () => <int>{},
                      );

                      if (set.contains(projectId)) {
                        set.remove(projectId);
                      } else {
                        set.add(projectId);
                      }
                    });
                  },
                  onRefreshTeamData: () {
                    setState(() {
                      _teamDataFutures[team.id] = _loadTeamProjectsTasks(team.id);
                    });
                  },
                );
              },
            ),
          );
        },
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading teams:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTeamDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<_TeamProjectsTasksData> _getTeamDataFuture(int teamId) {
    return _teamDataFutures.putIfAbsent(
      teamId,
      () => _loadTeamProjectsTasks(teamId),
    );
  }

  Future<_TeamProjectsTasksData> _loadTeamProjectsTasks(int teamId) async {
    final projectRepository = ref.read(projectRepositoryProvider);
    final teamProjectRepository = ref.read(teamProjectRepositoryProvider);
    final taskRepository = ref.read(taskRepositoryProvider);

    final projectsResponse = await projectRepository.getAll();

    switch (projectsResponse) {
      case ErrorResponse<List<Project>>():
        throw Exception(projectsResponse.error.toString());
      case ExceptionResponse<List<Project>>():
        throw Exception(projectsResponse.message);
      case SuccessResponse<List<Project>>():
        final allProjects = projectsResponse.body;
        final matchedProjects = <Project>[];

        for (final project in allProjects) {
          final sharedTeamsResponse = await teamProjectRepository.getAll(
            project.id,
          );

          switch (sharedTeamsResponse) {
            case SuccessResponse<List<Team>>():
              final sharedTeams = sharedTeamsResponse.body;
              final belongsToTeam = sharedTeams.any((team) => team.id == teamId);

              if (belongsToTeam) {
                matchedProjects.add(project);
              }
            case ErrorResponse<List<Team>>():
            case ExceptionResponse<List<Team>>():
              continue;
          }
        }

        final projectWithTasks = <_ProjectWithTasks>[];

        for (final project in matchedProjects) {
          final tasksResponse = await taskRepository.getAllByProject(project.id);

          switch (tasksResponse) {
            case SuccessResponse<List<Task>>():
              final tasks = tasksResponse.body.map((task) {
                task.project = project;
                task.projectId = project.id;
                return task;
              }).toList()
                ..sort((a, b) {
                  if (a.done != b.done) {
                    return a.done ? 1 : -1;
                  }

                  final aHasDue = a.hasDueDate;
                  final bHasDue = b.hasDueDate;

                  if (aHasDue && bHasDue) {
                    return a.dueDate!.compareTo(b.dueDate!);
                  }

                  if (aHasDue) return -1;
                  if (bHasDue) return 1;

                  return b.id.compareTo(a.id);
                });

              projectWithTasks.add(
                _ProjectWithTasks(project: project, tasks: tasks),
              );

            case ErrorResponse<List<Task>>():
              projectWithTasks.add(
                _ProjectWithTasks(project: project, tasks: const []),
              );

            case ExceptionResponse<List<Task>>():
              projectWithTasks.add(
                _ProjectWithTasks(project: project, tasks: const []),
              );
          }
        }

        projectWithTasks.sort(
          (a, b) => a.project.title.toLowerCase().compareTo(
                b.project.title.toLowerCase(),
              ),
        );

        return _TeamProjectsTasksData(projects: projectWithTasks);
    }
  }

  void _showCreateTeamDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create team'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Team name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final description = descriptionController.text.trim();

                if (name.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Team name is required')),
                  );
                  return;
                }

                final success = await ref
                    .read(teamListControllerProvider.notifier)
                    .addTeam(Team(name: name, description: description));

                if (context.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success
                            ? 'Team created successfully'
                            : 'Could not create team',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }
}

class _TeamProjectsCard extends ConsumerWidget {
  final Team team;
  final bool expanded;
  final bool showCompletedTasks;
  final Future<_TeamProjectsTasksData> future;
  final bool Function(int projectId) isProjectExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onToggleProjectExpanded;
  final VoidCallback onRefreshTeamData;

  const _TeamProjectsCard({
    required this.team,
    required this.expanded,
    required this.showCompletedTasks,
    required this.future,
    required this.isProjectExpanded,
    required this.onToggleExpanded,
    required this.onToggleProjectExpanded,
    required this.onRefreshTeamData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
            child: Row(
              children: [
                CircleAvatar(
                  child: Text(
                    team.name.isNotEmpty ? team.name[0].toUpperCase() : 'T',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TeamDetailPage(teamId: team.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            team.description.isNotEmpty
                                ? team.description
                                : 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: expanded ? 'Collapse' : 'Expand',
                  onPressed: onToggleExpanded,
                  icon: Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                  ),
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const Divider(height: 1),
            FutureBuilder<_TeamProjectsTasksData>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 12),
                        Text('Loading projects and tasks...'),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Could not load team projects: ${snapshot.error}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retry',
                          onPressed: onRefreshTeamData,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  );
                }

                final data = snapshot.data;
                if (data == null || data.projects.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No projects shared with this team',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: data.projects.map((projectData) {
                      return _TeamProjectSection(
                        teamId: team.id,
                        projectData: projectData,
                        expanded: isProjectExpanded(projectData.project.id),
                        showCompletedTasks: showCompletedTasks,
                        onToggleExpanded: () =>
                            onToggleProjectExpanded(projectData.project.id),
                        onRefreshTeamData: onRefreshTeamData,
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _TeamProjectSection extends ConsumerWidget {
  final int teamId;
  final _ProjectWithTasks projectData;
  final bool expanded;
  final bool showCompletedTasks;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRefreshTeamData;

  const _TeamProjectSection({
    required this.teamId,
    required this.projectData,
    required this.expanded,
    required this.showCompletedTasks,
    required this.onToggleExpanded,
    required this.onRefreshTeamData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = showCompletedTasks
        ? projectData.tasks
        : projectData.tasks.where((task) => !task.done).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  projectData.project.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              IconButton(
                tooltip: expanded ? 'Collapse project' : 'Expand project',
                onPressed: onToggleExpanded,
                icon: Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                ),
              ),
            ],
          ),
        ),
        if (expanded) ...[
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text(
                'No tasks in this project',
                style: TextStyle(fontSize: 13),
              ),
            )
          else
            ...tasks.map(
              (task) => Column(
                children: [
                  TaskListItem(
                    key: Key(
                      'team_${teamId}_project_${projectData.project.id}_task_${task.id}',
                    ),
                    task: task,
                    onTap: () {
                      _showTaskBottomSheet(context, task);
                    },
                    onLongPress: () {
                      if (task.done) {
                        _showCompletedTaskOptions(context, ref, task);
                      }
                    },
                    onEdit: () => _onEdit(context, task),
                    onCheckedChanged: (value) async {
                      final success = await ref
                          .read(taskPageControllerProvider.notifier)
                          .toggleDone(task, value);

                      if (success) {
                        onRefreshTeamData();
                        ref.read(taskPageControllerProvider.notifier).reload();
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Could not update task'),
                          ),
                        );
                      }
                    },
                  ),
                  if (task != tasks.last)
                    const Divider(height: 1, indent: 16, endIndent: 16),
                ],
              ),
            ),
        ],
      ],
    );
  }

  void _showTaskBottomSheet(BuildContext context, Task task) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder: (BuildContext context) {
        return TaskBottomSheet(
          task: task,
          onEdit: () => _onEdit(context, task),
        );
      },
    );
  }

  void _showCompletedTaskOptions(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.undo),
                title: const Text('Undone'),
                onTap: () async {
                  Navigator.pop(bottomSheetContext);

                  final success = await ref
                      .read(taskPageControllerProvider.notifier)
                      .toggleDone(task, false);

                  if (success) {
                    onRefreshTeamData();
                    ref.read(taskPageControllerProvider.notifier).reload();
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Could not update task'),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onEdit(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskEditPage(task: task),
      ),
    );
  }
}

class TeamDetailPage extends ConsumerWidget {
  final int teamId;

  const TeamDetailPage({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teamAsync = ref.watch(teamDetailControllerProvider(teamId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Team details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(teamDetailControllerProvider(teamId).notifier).reload();
            },
          ),
        ],
      ),
      body: teamAsync.when(
        data: (team) => _TeamDetailBody(team: team),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Error loading team:\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddMemberDialog(context, ref, teamId),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add member'),
      ),
    );
  }

  void _showAddMemberDialog(BuildContext context, WidgetRef ref, int teamId) {
    final searchController = TextEditingController();
    bool isAdmin = false;
    bool isSearching = false;
    List<User> foundUsers = [];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            Future<void> doSearch(String value) async {
              final query = value.trim();

              if (query.isEmpty) {
                setLocalState(() {
                  foundUsers = [];
                  isSearching = false;
                });
                return;
              }

              setLocalState(() {
                isSearching = true;
              });

              final response = await ref
                  .read(userRepositoryProvider)
                  .searchUsers(query);

              if (response.isSuccessful) {
                setLocalState(() {
                  foundUsers = response.toSuccess().body;
                  isSearching = false;
                });
              } else {
                setLocalState(() {
                  foundUsers = [];
                  isSearching = false;
                });
              }
            }

            return AlertDialog(
              title: const Text('Add member'),
              content: SizedBox(
                width: 420,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: searchController,
                        decoration: const InputDecoration(
                          labelText: 'Search by username',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: doSearch,
                      ),
                      const SizedBox(height: 12),
                      if (isSearching)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: CircularProgressIndicator(),
                        ),
                      if (!isSearching && foundUsers.isNotEmpty)
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: foundUsers.length,
                            itemBuilder: (context, index) {
                              final user = foundUsers[index];
                              final displayName = user.name.isNotEmpty
                                  ? user.name
                                  : user.username;

                              return ListTile(
                                dense: true,
                                leading: const CircleAvatar(
                                  child: Icon(Icons.person_outline),
                                ),
                                title: Text(displayName),
                                subtitle: Text(
                                  '${user.username} | id: ${user.id}',
                                ),
                                onTap: () async {
                                  final result = await ref
                                      .read(
                                        teamDetailControllerProvider(teamId)
                                            .notifier,
                                      )
                                      .addMember(
                                        teamId: teamId,
                                        userId: user.id,
                                        username: user.username,
                                        name: user.name,
                                        admin: isAdmin,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(dialogContext);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result.$1
                                              ? 'Member added successfully'
                                              : 'Could not add member: ${result.$2 ?? "Unknown error"}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      if (!isSearching &&
                          searchController.text.trim().isNotEmpty &&
                          foundUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text('No users found'),
                        ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: isAdmin,
                        onChanged: (value) {
                          setLocalState(() {
                            isAdmin = value;
                          });
                        },
                        title: const Text('Admin'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TeamDetailBody extends ConsumerWidget {
  final Team team;

  const _TeamDetailBody({required this.team});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          team.name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          team.description.isNotEmpty ? team.description : 'No description',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Text(
          'Members',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        if (team.members.isEmpty)
          const Text('No members')
        else
          ...team.members.map(
            (member) => _MemberTile(team: team, member: member),
          ),
      ],
    );
  }
}

class _MemberTile extends ConsumerWidget {
  final Team team;
  final TeamMember member;

  const _MemberTile({
    required this.team,
    required this.member,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.person_outline),
        ),
        title: Text(member.name.isNotEmpty ? member.name : member.username),
        subtitle: Text(member.username),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'toggle_admin') {
              final success = await ref
                  .read(teamDetailControllerProvider(team.id).notifier)
                  .toggleAdmin(member);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? (member.admin
                              ? 'Changed to member'
                              : 'Changed to admin')
                          : 'Could not update member role',
                    ),
                  ),
                );
              }
            } else if (value == 'remove') {
              final success = await ref
                  .read(teamDetailControllerProvider(team.id).notifier)
                  .removeMember(
                    teamId: team.id,
                    username: member.username,
                  );

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success ? 'Member removed' : 'Could not remove member',
                    ),
                  ),
                );
              }
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'toggle_admin',
              child: Text(member.admin ? 'Make member' : 'Make admin'),
            ),
            const PopupMenuItem(
              value: 'remove',
              child: Text('Remove'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TeamProjectsTasksData {
  final List<_ProjectWithTasks> projects;

  const _TeamProjectsTasksData({
    required this.projects,
  });
}

class _ProjectWithTasks {
  final Project project;
  final List<Task> tasks;

  const _ProjectWithTasks({
    required this.project,
    required this.tasks,
  });
}