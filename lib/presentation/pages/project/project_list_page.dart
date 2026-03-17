import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/projects_controller.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/project/project_detail_page.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/project/add_project_dialog.dart';
import 'package:vikunja_app/presentation/widgets/task/task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

class ProjectListPage extends ConsumerStatefulWidget {
  const ProjectListPage({super.key});

  @override
  ConsumerState<ProjectListPage> createState() => _ProjectListPageState();
}

class _ProjectListPageState extends ConsumerState<ProjectListPage> {
  bool _showCompletedTasks = false;
  final Set<int> _expandedProjects = {};
  final Map<int, Future<List<Task>>> _projectTasksFutures = {};

  @override
  void initState() {
    super.initState();
    _showCompletedTasks =
        ref.read(taskPageControllerProvider.notifier).showCompletedTasks;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(projectsControllerProvider);

    return controller.when(
      data: (projects) {
        return Scaffold(
          appBar: AppBar(
            title: Text(AppLocalizations.of(context).projectsTitle),
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
                    const PopupMenuItem<String>(
                      value: 'add_project',
                       child: Text('Add project'),
                    ),
                  ];
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.read(projectsControllerProvider.notifier).reload();
              if (mounted) {
                setState(() {
                  _projectTasksFutures.clear();
                });
              }
            },
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: projects.map<Widget>((project) {
                return _ProjectNode(
                  project: project,
                  expanded: _expandedProjects.contains(project.id),
                  showCompletedTasks: _showCompletedTasks,
                   future: _getProjectTasksFuture(project),
                  getProjectTasksFuture: _getProjectTasksFuture,
                   isProjectExpanded: (projectId) =>
                    _expandedProjects.contains(projectId),
                   onToggleExpanded: () {
                    setState(() {
                      if (_expandedProjects.contains(project.id)) {
                        _expandedProjects.remove(project.id);
                      } else {
                        _expandedProjects.add(project.id);
                      }
                    });
                  },
                  onToggleProjectExpanded: (projectId) {
                    setState(() {
                      if (_expandedProjects.contains(projectId)) {
                        _expandedProjects.remove(projectId);
                      } else {
                        _expandedProjects.add(projectId);
                      }
                    });
                  },
                  onRefreshProjectData: (projectId) {
                    setState(() {
                      _projectTasksFutures[projectId] = _loadTasksByProjectId(
                        projectId,
                      );
                    });
                  },
                );
              }).toList(),
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _addProjectDialog(ref),
            child: const Icon(Icons.add),
          ),
        );
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }

  Future<List<Task>> _getProjectTasksFuture(Project project) {
    return _projectTasksFutures.putIfAbsent(
      project.id,
      () => _loadTasks(project),
    );
  }

  Future<List<Task>> _loadTasks(Project project) async {
    final tasks = await _loadTasksByProjectId(project.id);
    for (final task in tasks) {
      task.project = project;
      task.projectId = project.id;
    }
    return tasks;
  }

  Future<List<Task>> _loadTasksByProjectId(int projectId) async {
    final taskRepository = ref.read(taskRepositoryProvider);
    final response = await taskRepository.getAllByProject(projectId);

    switch (response) {
      case SuccessResponse<List<Task>>():
        final tasks = response.body.toList()
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

        return tasks;

      case ErrorResponse<List<Task>>():
        throw Exception(response.error.toString());

      case ExceptionResponse<List<Task>>():
        throw Exception(response.message);
    }
  }

  void _addProjectDialog(WidgetRef ref) {
    showDialog(
      context: ref.context,
      builder: (_) => AddProjectDialog(onAdd: (name) => _addProject(name, ref)),
    );
  }

  Future<void> _addProject(String name, WidgetRef ref) async {
    final currentUser = ref.read(currentUserProvider);

    ref
        .read(projectsControllerProvider.notifier)
        .create(Project(title: name, owner: currentUser));
  }
}

class _ProjectNode extends ConsumerWidget {
  final Project project;
  final bool expanded;
  final bool showCompletedTasks;
  final Future<List<Task>> future;
  final Future<List<Task>> Function(Project project) getProjectTasksFuture;
  final bool Function(int projectId) isProjectExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<int> onToggleProjectExpanded;
  final ValueChanged<int> onRefreshProjectData;

  const _ProjectNode({
  required this.project,
  required this.expanded,
  required this.showCompletedTasks,
  required this.future,
  required this.getProjectTasksFuture,
  required this.isProjectExpanded,
  required this.onToggleExpanded,
  required this.onToggleProjectExpanded,
  required this.onRefreshProjectData,
});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
            child: Row(
              children: [
                const Icon(Icons.list),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      _navigateToProject(context, project);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 6,
                        horizontal: 4,
                      ),
                      child: Text(
                        project.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
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
            FutureBuilder<List<Task>>(
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
                        Text('Loading tasks...'),
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
                            'Could not load tasks: ${snapshot.error}',
                          ),
                        ),
                        IconButton(
                          tooltip: 'Retry',
                          onPressed: () => onRefreshProjectData(project.id),
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                  );
                }

                final allTasks = snapshot.data ?? [];
                final tasks = showCompletedTasks
                    ? allTasks
                    : allTasks.where((task) => !task.done).toList();

                final subprojects = project.subprojects.toList();

                if (tasks.isEmpty && subprojects.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'No tasks in this project',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (tasks.isNotEmpty)
                        ...tasks.map(
                          (task) => Column(
                            children: [
                              TaskListItem(
                                key: Key('project_${project.id}_task_${task.id}'),
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
                                      () => onRefreshProjectData(project.id),
                                    );
                                  }
                                },
                                onEdit: () => _onEdit(context, task),
                                onCheckedChanged: (value) async {
                                  final success = await ref
                                      .read(taskPageControllerProvider.notifier)
                                      .toggleDone(task, value);

                                  if (success) {
                                    onRefreshProjectData(project.id);
                                    ref
                                        .read(taskPageControllerProvider.notifier)
                                        .reload();
                                  } else if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Could not update task'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              if (task != tasks.last || subprojects.isNotEmpty)
                                const Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                ),
                            ],
                          ),
                        ),
                      ...subprojects.map(
                        (subproject) => Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: _ProjectNode(
                          project: subproject,
                          expanded: isProjectExpanded(subproject.id),
                           showCompletedTasks: showCompletedTasks,
                         future: getProjectTasksFuture(subproject),
                         getProjectTasksFuture: getProjectTasksFuture,
                         isProjectExpanded: isProjectExpanded,
                         onToggleExpanded: () =>
                          onToggleProjectExpanded(subproject.id),
                         onToggleProjectExpanded: onToggleProjectExpanded,
                         onRefreshProjectData: onRefreshProjectData,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  
  void _navigateToProject(BuildContext context, Project project) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          return ProjectDetailPage(
            key: Key(project.id.toString()),
            project: project,
          );
        },
      ),
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
    VoidCallback onSuccess,
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
                    onSuccess();
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