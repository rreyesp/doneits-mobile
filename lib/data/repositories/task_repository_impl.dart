import 'package:background_downloader/background_downloader.dart'
    show TaskStatusUpdate;
import 'package:flutter/foundation.dart';
import 'package:vikunja_app/core/network/response.dart';
import 'package:vikunja_app/core/utils/mapping_extensions.dart';
import 'package:vikunja_app/data/data_sources/task_data_source.dart';
import 'package:vikunja_app/data/models/task_attachment_dto.dart';
import 'package:vikunja_app/data/models/task_dto.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/task_attachment.dart';
import 'package:vikunja_app/domain/repositories/task_repository.dart';

class TaskRepositoryImpl extends TaskRepository {
  final TaskDataSource _dataSource;

  TaskRepositoryImpl(this._dataSource);

  @override
  Future<Response<Task>> add(int projectId, Task task) async {
    final dto = TaskDto.fromDomain(task);

    debugPrint('====== TASK DTO BEFORE ADD ======');
    debugPrint(dto.toJSON().toString());
    debugPrint('=================================');

    final createResponse = await _dataSource.add(projectId, dto);

    if (!createResponse.isSuccessful) {
      return createResponse.toDomain();
    }

    final createdTask = createResponse.toSuccess().body;

    if (task.assignees.isNotEmpty) {
      for (final assignee in task.assignees) {
        final assignResponse = await _dataSource.addAssignee(
          createdTask.id,
          assignee.id,
        );

        if (assignResponse.isSuccessful) {
          debugPrint(
            'ASSIGNEE OK -> taskId: ${createdTask.id}, userId: ${assignee.id}, username: ${assignee.username}',
          );
        } else if (assignResponse.isError) {
          debugPrint(
            'ASSIGNEE ERROR -> taskId: ${createdTask.id}, userId: ${assignee.id}, username: ${assignee.username}',
          );
          debugPrint(assignResponse.toError().error.toString());

          await _dataSource.delete(createdTask.id);

          return ErrorResponse<Task>(
            assignResponse.toError().statusCode,
            assignResponse.toError().headers,
            assignResponse.toError().error,
          );
        } else if (assignResponse.isException) {
          debugPrint(
            'ASSIGNEE EXCEPTION -> taskId: ${createdTask.id}, userId: ${assignee.id}, username: ${assignee.username}',
          );
          debugPrint(assignResponse.toException().message);

          await _dataSource.delete(createdTask.id);

          return ExceptionResponse<Task>(
            assignResponse.toException().exception,
            assignResponse.toException().stackTrace,
          );
        }
      }

      final refreshedTaskResponse = await _dataSource.getTask(createdTask.id);
      if (refreshedTaskResponse.isSuccessful) {
        return refreshedTaskResponse.toDomain();
      }

      return refreshedTaskResponse.toDomain();
    }

    return createResponse.toDomain();
  }

  @override
  Future<Response<Object>> delete(int taskId) async {
    return _dataSource.delete(taskId);
  }

  @override
  Future<Response<Task>> update(Task task) async {
    final updateResponse = await _dataSource.update(TaskDto.fromDomain(task));
    return updateResponse.toDomain();
  }

  @override
  Future<Response<void>> addAssignee(int taskId, int userId) async {
    return _dataSource.addAssignee(taskId, userId);
  }

  @override
  Future<Response<void>> removeAssignee(int taskId, int userId) async {
    return _dataSource.deleteAssignee(taskId, userId);
  }

  @override
  Future<Response<Task>> getTask(int id) async {
    return (await _dataSource.getTask(id)).toDomain();
  }

  @override
  Future<Response<List<Task>>> getAllByProject(
    int projectId, [
    Map<String, List<String>>? queryParameters,
  ]) async {
    var response = await _dataSource.getAllByProject(
      projectId,
      queryParameters,
    );

    return response.toDomain();
  }

  @override
  Future<Response<List<Task>>> getAllByProjectView(
    int projectId,
    int view, [
    Map<String, List<String>>? queryParameters,
  ]) async {
    var response = await _dataSource.getAllByProjectView(
      projectId,
      view,
      queryParameters,
    );

    return response.toDomain();
  }

  @override
  Future<Response<List<Task>>> getByFilterString(
    String filterString, [
    Map<String, List<String>>? queryParameters,
  ]) async {
    return (await _dataSource.getByFilterString(
      filterString,
      queryParameters,
    )).toDomain();
  }

  @override
  Future<TaskStatusUpdate> downloadAttachment(
    int taskId,
    TaskAttachment attachment,
  ) async {
    return _dataSource.downloadAttachment(
      taskId,
      TaskAttachmentDto.fromDomain(attachment),
    );
  }
}