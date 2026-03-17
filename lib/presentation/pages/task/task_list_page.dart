import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/task_page_model.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/empty_view.dart';
import 'package:vikunja_app/presentation/widgets/task/add_task_dialog.dart';
import 'package:vikunja_app/presentation/widgets/task/task_list_item.dart';
import 'package:vikunja_app/presentation/widgets/task_bottom_sheet.dart';

class TaskListPage extends ConsumerWidget {
  const TaskListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pageModel = ref.watch(taskPageControllerProvider);
    final showCompletedTasks =
        ref.read(taskPageControllerProvider.notifier).showCompletedTasks;

    return pageModel.when(
      data: (model) {
        return Scaffold(
          appBar: _buildAppBar(
            ref,
            context,
            model.onlyDueDate,
            showCompletedTasks,
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              ref.read(taskPageControllerProvider.notifier).reload();
            },
            child: _buildList(ref, context, model),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              if (model.defaultProjectId == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.selectDefaultProject)),
                );
              } else {
                _addItemDialog(ref, context, model.defaultProjectId);
              }
            },
            child: const Icon(Icons.add),
          ),
        );
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }

  Widget _buildList(WidgetRef ref, BuildContext context, TaskPageModel model) {
    if (model.tasks.isEmpty) {
      return EmptyView(Icons.list, AppLocalizations.of(context).noTasks);
    }

    return ListView(
      children: ListTile.divideTiles(
        context: context,
        tiles: _listTasks(ref, context, model.tasks),
      ).toList(),
    );
  }

  AppBar _buildAppBar(
    WidgetRef ref,
    BuildContext context,
    bool onlyDueDate,
    bool showCompletedTasks,
  ) {
    return AppBar(
      title: Text(AppLocalizations.of(context)!.appName),
      actions: [
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'toggle_due_date') {
              Future.microtask(() {
                _onlyDueDateChanged(ref, !onlyDueDate);
              });
            } else if (value == 'toggle_completed') {
              Future.microtask(() {
                ref
                    .read(taskPageControllerProvider.notifier)
                    .setShowCompletedTasks(!showCompletedTasks);
              });
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              CheckedPopupMenuItem<String>(
                value: 'toggle_due_date',
                checked: onlyDueDate,
                child: SizedBox(
                  width: 220,
                  child: Text(
                    AppLocalizations.of(context).onlyShowTasksWithDueDate,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              CheckedPopupMenuItem<String>(
                value: 'toggle_completed',
                checked: showCompletedTasks,
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
    );
  }

  void _onlyDueDateChanged(WidgetRef ref, bool newValue) {
    ref
        .read(taskPageControllerProvider.notifier)
        .setLandingPageOnlyDueDateTasks(newValue);
  }

  void _addItemDialog(
    WidgetRef ref,
    BuildContext context,
    int defaultProjectId,
  ) {
    showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        projectId: defaultProjectId,
        onAddTask: (taskDraft) => _addTask(ref, taskDraft, defaultProjectId),
      ),
    );
  }

  Future<(bool, String?)> _addTask(
  WidgetRef ref,
  Task taskDraft,
  int defaultProjectId,
) async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) {
    return (false, 'No current user');
  }

  final effectiveProjectId = taskDraft.projectId ?? defaultProjectId;

  final task = Task(
    title: taskDraft.title,
    dueDate: taskDraft.dueDate,
    priority: taskDraft.priority,
    color: taskDraft.color,
    labels: taskDraft.labels,
    assignees: taskDraft.assignees,
    createdBy: currentUser,
    projectId: effectiveProjectId,
  );

  return await ref
      .read(taskPageControllerProvider.notifier)
      .addTaskWithMessage(effectiveProjectId, task);
}

    

  List<Widget> _listTasks(
    WidgetRef ref,
    BuildContext context,
    List<Task> tasks,
  ) {
    return tasks
        .map(
          (task) => TaskListItem(
            key: Key(task.id.toString()),
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

              if (!success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      AppLocalizations.of(context).taskMarkDoneError,
                    ),
                  ),
                );
              }
            },
          ),
        )
        .toList();
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
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).taskMarkDoneError,
                        ),
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
    Navigator.push<Task?>(
      context,
      MaterialPageRoute(builder: (buildContext) => TaskEditPage(task: task)),
    );
  }
}