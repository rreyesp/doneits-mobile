import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/notification_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/task_page_model.dart';
import 'package:vikunja_app/presentation/manager/widget_controller.dart';

part 'task_page_controller.g.dart';

@riverpod
class TaskPageController extends _$TaskPageController {
  bool _showCompletedTasks = false;

  bool get showCompletedTasks => _showCompletedTasks;

  @override
  Future<TaskPageModel> build() async {
    final tasksResponse = await _getAllFiltered(
      showCompletedTasks: _showCompletedTasks,
    );

    switch (tasksResponse) {
      case SuccessResponse<List<Task>>():
        return await _createPageModel(tasksResponse.body);
      case ErrorResponse<List<Task>>():
        throw AsyncError(tasksResponse.error, StackTrace.current);
      case ExceptionResponse<List<Task>>():
        throw AsyncError(tasksResponse.message, StackTrace.current);
    }
  }

  void reload() async {
    final tasksResponse = await _getAllFiltered(
      showCompletedTasks: _showCompletedTasks,
    );

    switch (tasksResponse) {
      case SuccessResponse<List<Task>>():
        final pageModel = await _createPageModel(tasksResponse.body);
        state = AsyncData(pageModel);
      case ErrorResponse<List<Task>>():
        state = AsyncError(tasksResponse.error, StackTrace.current);
      case ExceptionResponse<List<Task>>():
        state = AsyncError(tasksResponse.message, StackTrace.current);
    }
  }

  void setShowCompletedTasks(bool newValue) {
    _showCompletedTasks = newValue;
    reload();
  }

  Future<TaskPageModel> _createPageModel(List<Task> tasks) async {
    final defaultProjectId =
        ref.read(currentUserProvider)?.settings?.defaultProjectId ?? 0;

    final projectsResponse = await ref.read(projectRepositoryProvider).getAll();

    _setProjectOfTask(projectsResponse, tasks);

    updateWidget();
    ref
        .read(notificationProvider)
        ?.scheduleDueNotifications(ref.read(taskRepositoryProvider));

    final showOnlyDueDateTasks = await ref
        .read(settingsRepositoryProvider)
        .getLandingPageOnlyDueDateTasks();

    return TaskPageModel(tasks, showOnlyDueDateTasks, defaultProjectId);
  }

  void _setProjectOfTask(
    Response<List<Project>> projectsResponse,
    List<Task> tasks,
  ) {
    if (projectsResponse.isSuccessful) {
      final projectsMap = {
        for (final v in projectsResponse.toSuccess().body) v.id: v,
      };

      for (final task in tasks) {
        task.project = projectsMap[task.projectId];
      }
    }
  }

  Future<Response<List<Task>>> _getAllFiltered({
    required bool showCompletedTasks,
  }) async {
    final showOnlyDueDateTasks = await ref
        .read(settingsRepositoryProvider)
        .getLandingPageOnlyDueDateTasks();

    final user = ref.read(currentUserProvider);
    if (user != null) {
      final Map<String, dynamic>? frontendSettings =
          user.settings?.frontendSettings;
      final int? filterId = frontendSettings?["filter_id_used_on_overview"];

      if (filterId != null && filterId != 0) {
        return await ref.read(taskRepositoryProvider).getAllByProject(filterId, {
          "sort_by": ["done", "due_date", "id"],
          "order_by": ["asc", "asc", "desc"],
        });
      }
    }

    final List<String> filterStrings = [];

    if (!showCompletedTasks) {
      filterStrings.add("done = false");
    }

    if (showOnlyDueDateTasks) {
      filterStrings.add("due_date > 0001-01-01 00:00");
    }

    final filter = filterStrings.isEmpty ? "" : filterStrings.join(" && ");

    return await ref.read(taskRepositoryProvider).getByFilterString(filter, {
      "sort_by": ["done", "due_date", "id"],
      "order_by": ["asc", "asc", "desc"],
      "filter_include_nulls": ["false"],
    });
  }

  Future<void> setLandingPageOnlyDueDateTasks(bool newValue) async {
    await ref
        .read(settingsRepositoryProvider)
        .setLandingPageOnlyDueDateTasks(newValue);

    reload();
  }

  Future<(bool, String?)> addTaskWithMessage(int projectId, Task task) async {
  final response = await ref.read(taskRepositoryProvider).add(projectId, task);

  if (response.isSuccessful) {
    reload();
    return (true, null);
  }

  if (response.isError) {
    final error = response.toError().error;
    final code = error['code'];

    if (code == 7003) {
      return (
        false,
        'Ese usuario no tiene permiso para el proyecto seleccionado. Elige otro proyecto.',
      );
    }

    return (false, error['message']?.toString() ?? 'Error al agregar la tarea');
  }

  if (response.isException) {
    return (false, response.toException().message);
  }

  return (false, 'No se pudo agregar la tarea');
}

  Future<bool> deleteTask(int id) async {
    final response = await ref.read(taskRepositoryProvider).delete(id);
    if (response.isSuccessful) {
      final value = state.value;
      if (value != null) {
        final tasks = List<Task>.from(value.tasks);
        tasks.removeWhere((element) => element.id == id);
        state = AsyncData(value.copyWith(tasks: tasks));
      }

      return true;
    }

    return false;
  }

  Future<bool> updateTask(Task task) async {
    final response = await ref.read(taskRepositoryProvider).update(task);
    if (response.isSuccessful) {
      reload();
      return true;
    }

    return false;
  }

  Future<bool> toggleDone(Task task, bool done) async {
    task.done = done;

    final response = await ref.read(taskRepositoryProvider).update(task);
    if (response.isSuccessful) {
      if (_showCompletedTasks) {
        reload();
      } else {
        final value = state.value;
        if (value != null) {
          final tasks = List<Task>.from(value.tasks);

          if (done) {
            tasks.removeWhere((element) => element.id == task.id);
          }

          state = AsyncData(value.copyWith(tasks: tasks));
        }
      }

      return true;
    }

    return false;
  }
}