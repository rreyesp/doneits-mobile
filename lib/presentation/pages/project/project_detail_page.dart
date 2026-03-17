import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/notification_provider.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/view_kind.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/notifications.dart';
import 'package:vikunja_app/presentation/manager/project_controller.dart';
import 'package:vikunja_app/presentation/pages/error_widget.dart';
import 'package:vikunja_app/presentation/pages/loading_widget.dart';
import 'package:vikunja_app/presentation/pages/project/project_edit.dart';
import 'package:vikunja_app/presentation/pages/project/project_share_page.dart';
import 'package:vikunja_app/presentation/widgets/project/kanban/kanban_widget.dart';
import 'package:vikunja_app/presentation/widgets/project/project_task_list.dart';
import 'package:vikunja_app/presentation/widgets/task/add_task_dialog.dart';

class ProjectDetailPage extends ConsumerStatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  ProjectPageState createState() => ProjectPageState();
}

class ProjectPageState extends ConsumerState<ProjectDetailPage> {
  int _viewIndex = 0;
  NotificationHandler? _notificationHandler;

  @override
  void initState() {
    _notificationHandler = ref.read(notificationProvider);
    _notificationHandler?.addListener(onNotificationDone);
    super.initState();
  }

  @override
  void dispose() {
    _notificationHandler?.removeListener(onNotificationDone);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var projectController = ref.watch(
      projectControllerProvider(widget.project),
    );

    return projectController.when(
      data: (data) {
        return Scaffold(
          appBar: _buildAppBar(context, data.project, data.displayDoneTask),
          body: RefreshIndicator(
            onRefresh: () {
              return ref
                  .read(projectControllerProvider(widget.project).notifier)
                  .loadForView(data.project, _viewIndex);
            },
            child: getBody(data.project),
          ),
          floatingActionButton: _buildFab(data.project),
          bottomNavigationBar: _buildBottomNavigation(data.project),
        );
      },
      error: (err, _) => VikunjaErrorWidget(error: err),
      loading: () => const LoadingWidget(),
    );
  }

  Widget getBody(Project project) {
    if (project.views.isEmpty) {
      return Text(AppLocalizations.of(context).noViews);
    }

    switch (project.views[_viewIndex].viewKind) {
      case ViewKind.list:
        return ProjectTaskList(project);
      case ViewKind.kanban:
        return KanbanWidget(project: project);
      default:
        return Text(AppLocalizations.of(context).notImplemented);
    }
  }

  AppBar _buildAppBar(
    BuildContext context,
    Project project,
    bool displayDoneTask,
  ) {
    return AppBar(
      title: Text(project.title),
      actions: <Widget>[
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectEditPage(
                    project: project,
                    displayDoneTask: displayDoneTask,
                  ),
                ),
              );
            } else if (value == 'share') {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectSharePage(project: project),
                ),
              );
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem<String>(
              value: 'edit',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.edit_outlined),
                title: Text('Edit'),
              ),
            ),
            PopupMenuItem<String>(
              value: 'share',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.share_outlined),
                title: Text('Share'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Builder? _buildFab(Project project) {
    if (project.views.isEmpty ||
        project.views[_viewIndex].viewKind == ViewKind.kanban ||
        project.id < 0) {
      return null;
    }

    return Builder(
      builder: (context) => FloatingActionButton(
        onPressed: () => _addITaskDialog(context, project),
        child: const Icon(Icons.add),
      ),
    );
  }

  BottomNavigationBar? _buildBottomNavigation(Project project) {
    if (project.views.length >= 2) {
      return BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: project.views
            .map(
              (view) => BottomNavigationBarItem(
                icon: view.icon,
                label: view.title,
                tooltip: view.title,
              ),
            )
            .toList(),
        currentIndex: _viewIndex,
        onTap: _onViewTapped,
      );
    }

    return null;
  }

  Future<void> _addITaskDialog(BuildContext context, Project project) {
    return showDialog(
      context: context,
      builder: (_) => AddTaskDialog(
        projectId: project.id,
        onAddTask: (taskDraft) => _addItem(context, project, taskDraft),
      ),
    );
  }

  Future<(bool, String?)> _addItem(
  BuildContext context,
  Project project,
  Task taskDraft,
) async {
  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) {
    return (false, 'No current user');
  }

  final task = Task(
    title: taskDraft.title,
    dueDate: taskDraft.dueDate,
    priority: taskDraft.priority,
    color: taskDraft.color,
    labels: taskDraft.labels,
    assignees: taskDraft.assignees,
    createdBy: currentUser,
    done: false,
    projectId: project.id,
  );

  final success = await ref
      .read(projectControllerProvider(widget.project).notifier)
      .addTask(project, task);

  if (success) {
    return (true, null);
  }

  return (false, 'No se pudo agregar la tarea');
}

  void _onViewTapped(int index) {
    setState(() {
      _viewIndex = index;

      ref
          .read(projectControllerProvider(widget.project).notifier)
          .loadForView(widget.project, _viewIndex);
    });
  }

  void onNotificationDone() {
    ref.read(projectControllerProvider(widget.project).notifier).reload();
  }
}