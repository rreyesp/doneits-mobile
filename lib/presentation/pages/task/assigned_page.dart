import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/task_page_model.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';
import 'package:vikunja_app/presentation/widgets/task/task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

class AssignedPage extends ConsumerStatefulWidget {
  const AssignedPage({super.key});

  @override
  ConsumerState<AssignedPage> createState() => _AssignedPageState();
}

class _AssignedPageState extends ConsumerState<AssignedPage> {
  bool _showCompletedTasks = false;
  final Set<String> _expandedUsers = {};
  final Map<String, Set<int>> _expandedProjects = {};

  @override
  void initState() {
    super.initState();
    _showCompletedTasks =
        ref.read(taskPageControllerProvider.notifier).showCompletedTasks;
  }

  @override
  Widget build(BuildContext context) {
    final pageModel = ref.watch(taskPageControllerProvider);

    return pageModel.when(
      data: (model) {
        final currentUser = ref.read(currentUserProvider);
        final grouped = _buildAssignedGroups(
          model,
          currentUser,
          showCompletedTasks: _showCompletedTasks,
        );

        return Scaffold(
          appBar: AppBar(
            title: const Text('Assigned'),
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
          body: RefreshIndicator(
            onRefresh: () async {
              ref.read(taskPageControllerProvider.notifier).reload();
            },
            child: grouped.isEmpty
                ? const EmptyView(Icons.assignment_ind, 'No assigned tasks')
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24),
                    itemCount: grouped.length,
                    itemBuilder: (context, index) {
                      final group = grouped[index];
                      final isExpanded = _expandedUsers.contains(group.key);

                      return _AssignedUserSection(
                        group: group,
                        expanded: isExpanded,
                        isProjectExpanded: (projectId) =>
                            _expandedProjects[group.key]?.contains(projectId) ??
                            false,
                        onToggleExpanded: () {
                          setState(() {
                            if (_expandedUsers.contains(group.key)) {
                              _expandedUsers.remove(group.key);
                            } else {
                              _expandedUsers.add(group.key);
                            }
                          });
                        },
                        onToggleProjectExpanded: (projectId) {
                          setState(() {
                            final set = _expandedProjects.putIfAbsent(
                              group.key,
                              () => <int>{},
                            );

                            if (set.contains(projectId)) {
                              set.remove(projectId);
                            } else {
                              set.add(projectId);
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        );
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }

  List<_AssignedUserGroup> _buildAssignedGroups(
    TaskPageModel model,
    User? currentUser, {
    required bool showCompletedTasks,
  }) {
    final Map<String, _AssignedUserGroupBuilder> grouped = {};

    for (final task in model.tasks) {
      if (task.assignees.isEmpty) {
        continue;
      }

      if (!showCompletedTasks && task.done) {
        continue;
      }

      for (final assignee in task.assignees) {
        final isMe = _isCurrentUser(assignee, currentUser);
        final key = assignee.id != 0
            ? 'id_${assignee.id}'
            : 'username_${assignee.username}';
        final displayName = isMe ? 'Me' : _displayUserName(assignee);

        grouped.putIfAbsent(
          key,
          () => _AssignedUserGroupBuilder(
            key: key,
            displayName: displayName,
            isMe: isMe,
          ),
        );

        final projectKey = task.projectId ?? 0;
        grouped[key]!.tasksByProject.putIfAbsent(projectKey, () => []);
        grouped[key]!.tasksByProject[projectKey]!.add(task);
      }
    }

    final result = grouped.values.map((builder) {
      final sortedProjectEntries = builder.tasksByProject.entries.toList()
        ..sort((a, b) {
          final projectA = a.value.isNotEmpty
              ? (a.value.first.project?.title ?? '')
              : '';
          final projectB = b.value.isNotEmpty
              ? (b.value.first.project?.title ?? '')
              : '';
          return projectA.toLowerCase().compareTo(projectB.toLowerCase());
        });

      final sortedTasksByProject = <int, List<Task>>{};
      for (final entry in sortedProjectEntries) {
        final tasks = List<Task>.from(entry.value)
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

        sortedTasksByProject[entry.key] = tasks;
      }

      return _AssignedUserGroup(
        key: builder.key,
        displayName: builder.displayName,
        isMe: builder.isMe,
        tasksByProject: sortedTasksByProject,
      );
    }).toList();

    result.sort((a, b) {
      if (a.isMe && !b.isMe) return -1;
      if (!a.isMe && b.isMe) return 1;
      return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
    });

    return result;
  }

  bool _isCurrentUser(User assignee, User? currentUser) {
    if (currentUser == null) return false;

    if (assignee.id != 0 && assignee.id == currentUser.id) {
      return true;
    }

    return assignee.username.trim().toLowerCase() ==
        currentUser.username.trim().toLowerCase();
  }

  String _displayUserName(User user) {
    if (user.name.trim().isNotEmpty) {
      return user.name.trim();
    }

    if (user.username.trim().isNotEmpty) {
      return user.username.trim();
    }

    return 'Unknown user';
  }
}

class _AssignedUserSection extends ConsumerWidget {
  final _AssignedUserGroup group;
  final bool expanded;
  final bool Function(int projectId) isProjectExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onToggleProjectExpanded;

  const _AssignedUserSection({
    required this.group,
    required this.expanded,
    required this.isProjectExpanded,
    required this.onToggleExpanded,
    required this.onToggleProjectExpanded,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectEntries = group.tasksByProject.entries.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 8, 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      child: Text(
                        group.displayName.isNotEmpty
                            ? group.displayName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        group.displayName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
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
              if (expanded)
                ...projectEntries.map((entry) {
                  final projectId = entry.key;
                  final tasks = entry.value;
                  final projectTitle = _projectTitle(tasks);
                  final projectExpanded = isProjectExpanded(projectId);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 8, 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                projectTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: projectExpanded
                                  ? 'Collapse project'
                                  : 'Expand project',
                              onPressed: () =>
                                  onToggleProjectExpanded(projectId),
                              icon: Icon(
                                projectExpanded
                                    ? Icons.expand_less
                                    : Icons.expand_more,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (projectExpanded)
                        ...tasks.map(
                          (task) => Column(
                            children: [
                              TaskListItem(
                                key: Key(
                                  'assigned_${group.key}_${projectId}_${task.id}',
                                ),
                                task: task,
                                onTap: () {
                                  _showTaskBottomSheet(context, task);
                                },
                                onLongPress: () {
                                  if (task.done) {
                                    _showCompletedTaskOptions(
                                      context,
                                      ref,
                                      task,
                                    );
                                  }
                                },
                                onEdit: () => _onEdit(context, task),
                                onCheckedChanged: (value) async {
                                  await ref
                                      .read(taskPageControllerProvider.notifier)
                                      .toggleDone(task, value);
                                },
                              ),
                              if (task != tasks.last)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          ),
                        ),
                    ],
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  String _projectTitle(List<Task> tasks) {
    if (tasks.isEmpty) {
      return 'Unknown project';
    }

    final title = tasks.first.project?.title ?? '';
    if (title.trim().isEmpty) {
      return 'Unknown project';
    }

    return title;
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

                  if (!success && context.mounted) {
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
        builder: (context) => TaskEditPage(
          task: task,
        ),
      ),
    );
  }
}

class _AssignedUserGroup {
  final String key;
  final String displayName;
  final bool isMe;
  final Map<int, List<Task>> tasksByProject;

  const _AssignedUserGroup({
    required this.key,
    required this.displayName,
    required this.isMe,
    required this.tasksByProject,
  });
}

class _AssignedUserGroupBuilder {
  final String key;
  final String displayName;
  final bool isMe;
  final Map<int, List<Task>> tasksByProject = {};

  _AssignedUserGroupBuilder({
    required this.key,
    required this.displayName,
    required this.isMe,
  });
}