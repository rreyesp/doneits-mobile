import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/utils/calculate_item_position.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/project_controller.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/project/project_detail_page.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';
import 'package:vikunja_app/presentation/widgets/task/task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

class ProjectTaskList extends ConsumerWidget {
  final Project project;

  const ProjectTaskList(this.project, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectController = ref.watch(projectControllerProvider(project));

    return projectController.when(
      data: (pageModel) {
        List<Widget> children = [];

        if (project.subprojects.isNotEmpty) {
          if (pageModel.tasks.isNotEmpty) {
            children.add(
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  AppLocalizations.of(context).projectSection,
                ),
              ),
            );
            children.add(const SliverToBoxAdapter(child: Divider()));
          }

          children.addAll(_buildProjectList(context));
        }

        if (pageModel.tasks.isNotEmpty) {
          if (project.subprojects.isNotEmpty) {
            children.add(
              SliverToBoxAdapter(
                child: _buildSectionHeader(
                  AppLocalizations.of(context).tasksSection,
                ),
              ),
            );
            children.add(const SliverToBoxAdapter(child: Divider()));
          }

          children.add(_buildTaskList(ref, pageModel.tasks));
        }

        if (children.isNotEmpty) {
          return CustomScrollView(slivers: children);
        } else {
          return EmptyView(
            Icons.list,
            AppLocalizations.of(context).noTasksOrSubproject,
          );
        }
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }

  Widget _buildSectionHeader(String title) {
    return const Padding(
      padding: EdgeInsets.all(10),
      child: Text(
        '',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    ).copyWithText(title);
  }

  List<Widget> _buildProjectList(BuildContext context) {
    return [
      SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final subproject = project.subprojects.toList()[index];
          return ListTile(
            leading: const Icon(Icons.list),
            onTap: () => _navigateToDetail(context, subproject),
            title: Text(
              subproject.title,
              overflow: TextOverflow.ellipsis,
              softWrap: false,
            ),
          );
        }, childCount: project.subprojects.length),
      ),
    ];
  }

  Widget _buildTaskList(WidgetRef ref, List<Task> tasks) {
    return SliverReorderableList(
      itemBuilder: (context, index) {
        final task = tasks[index];

        return ReorderableDelayedDragStartListener(
          key: Key('task_${task.id}'),
          index: index,
          child: Material(
            color: Colors.transparent,
            child: Column(
              children: [
                _buildTile(ref, task),
                if (index < tasks.length - 1)
                  const Divider(height: 1, indent: 16, endIndent: 16),
              ],
            ),
          ),
        );
      },
      itemCount: tasks.length,
      onReorder: (oldIndex, newIndexRaw) {
        int newIndex = newIndexRaw;
        if (newIndex > oldIndex) {
          newIndex -= 1;
        }

        if (newIndex < -1) newIndex = -1;

        final taskList = List<Task>.from(tasks);
        final moved = taskList.removeAt(oldIndex);
        final insertIndex = newIndex == -1
            ? 0
            : newIndex.clamp(0, taskList.length);

        taskList.insert(insertIndex, moved);

        final before = insertIndex == 0
            ? null
            : taskList[insertIndex - 1].position;
        final after = insertIndex == taskList.length - 1
            ? null
            : taskList[insertIndex + 1].position;

        final newPos = calculateItemPosition(
          positionBefore: before,
          positionAfter: after,
        );

        ref
            .read(projectControllerProvider(project).notifier)
            .reorderTasks(
              project: project,
              newOrderedTasks: taskList,
              movedTaskId: moved.id,
              newPosition: newPos,
            )
            .then((success) {
              if (!success && ref.context.mounted) {
                ScaffoldMessenger.of(ref.context).showSnackBar(
                  const SnackBar(content: Text('Failed to reorder task')),
                );
              }
            });
      },
    );
  }

  Widget _buildTile(WidgetRef ref, Task task) {
    return TaskListItem(
      key: Key(task.id.toString()),
      task: task,
      onTap: () => _showTaskBottomSheet(ref, task),
      onLongPress: () {
        if (task.done) {
          _showCompletedTaskOptions(ref, task);
        }
      },
      onEdit: () => _onEdit(ref, task),
      onCheckedChanged: (value) async {
        final success = await ref
            .read(taskPageControllerProvider.notifier)
            .toggleDone(task, value);

        if (success) {
          ref.read(projectControllerProvider(project).notifier).reload();
          ref.read(taskPageControllerProvider.notifier).reload();
        } else if (ref.context.mounted) {
          ScaffoldMessenger.of(ref.context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(ref.context).failedToMarkDone),
            ),
          );
        }
      },
    );
  }

  void _showTaskBottomSheet(WidgetRef ref, Task task) {
    showModalBottomSheet<void>(
      context: ref.context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(10.0)),
      ),
      builder: (BuildContext context) {
        return TaskBottomSheet(
          task: task,
          onEdit: () => _onEdit(ref, task),
        );
      },
    );
  }

  void _showCompletedTaskOptions(WidgetRef ref, Task task) {
    showModalBottomSheet<void>(
      context: ref.context,
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
                    ref.read(projectControllerProvider(project).notifier).reload();
                    ref.read(taskPageControllerProvider.notifier).reload();
                  } else if (ref.context.mounted) {
                    ScaffoldMessenger.of(ref.context).showSnackBar(
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

  void _onEdit(WidgetRef ref, Task task) async {
    final editedTask = await Navigator.push<Task?>(
      ref.context,
      MaterialPageRoute(builder: (buildContext) => TaskEditPage(task: task)),
    );

    if (editedTask != null) {
      ref.read(projectControllerProvider(project).notifier).reload();
    }
  }

  void _navigateToDetail(BuildContext context, Project project) {
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
}

extension on Padding {
  Padding copyWithText(String text) {
    final childWidget = child;
    if (childWidget is Text) {
      return Padding(
        padding: padding,
        child: Text(
          text,
          style: childWidget.style,
        ),
      );
    }
    return this;
  }
}