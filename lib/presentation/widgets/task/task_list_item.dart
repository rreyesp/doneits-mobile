import 'package:flutter/material.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/presentation/widgets/project/kanban/priority_batch.dart';

class TaskListItem extends StatefulWidget {
  final Task task;
  final Function onTap;
  final Function onEdit;
  final Function(bool value) onCheckedChanged;
  final Function()? onLongPress;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onEdit,
    required this.onCheckedChanged,
    this.onLongPress,
  });

  @override
  TaskListItemState createState() => TaskListItemState();
}

class TaskListItemState extends State<TaskListItem> {
  TaskListItemState();

  Color get _taskColor =>
      widget.task.color ?? Theme.of(context).colorScheme.primary;

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final hasSubtitleContent =
        task.hasDueDate ||
        (task.priority != null && task.priority != 0) ||
        task.project != null ||
        task.assignees.isNotEmpty;

    final tileHeight = hasSubtitleContent ? 88.0 : 64.0;

    return Stack(
      fit: StackFit.loose,
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 4.0,
          ),
          onTap: () {
            widget.onTap();
          },
          leading: _buildCircularCheck(),
          title: Text(
            task.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              height: 1.2,
              decoration: task.done ? TextDecoration.lineThrough : null,
              color: task.done ? Colors.grey.shade600 : null,
            ),
          ),
          onLongPress: widget.onLongPress,
          subtitle: _buildTaskSubtitle(task, context),
        ),
        Container(
          width: 4.0,
          height: tileHeight,
          color: widget.task.color,
        ),
      ],
    );
  }

  Widget _buildCircularCheck() {
    return Checkbox(
      value: widget.task.done,
      shape: const CircleBorder(),
      side: BorderSide(
        color: _taskColor,
        width: 2,
      ),
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _taskColor;
        }
        return Colors.transparent;
      }),
      checkColor: Colors.white,
      onChanged: (bool? newValue) {
        if (newValue != null) {
          widget.onCheckedChanged(newValue);
        }
      },
    );
  }

  Widget? _buildTaskSubtitle(Task task, BuildContext context) {
    final hasDueDate = task.hasDueDate;
    final hasPriority = task.priority != null && task.priority != 0;
    final hasAssignee = task.assignees.isNotEmpty;
    final project = task.project;

    if (!hasDueDate && !hasPriority && project == null && !hasAssignee) {
      return null;
    }

    if (!hasDueDate && !hasPriority && project != null && !hasAssignee) {
      return Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Row(
          children: [
            const Spacer(),
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6.0),
      child: Row(
        children: [
          Expanded(
            flex: 8,
            child: Row(
              children: [
                if (hasAssignee) ...[
                  _buildAssigneeAvatar(task),
                  const SizedBox(width: 8),
                ],
                if (hasPriority) ...[
                  PriorityBatch(task.priority!),
                  const SizedBox(width: 4),
                ],
                if (hasDueDate) ...[
                  Expanded(
                    child: Text(
                      _formatDueDate(task.dueDate!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getDueDateColor(task, context),
                        fontWeight: FontWeight.w600,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (project != null) ...[
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  project.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    decoration: task.done ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAssigneeAvatar(Task task) {
    final assignee = task.assignees.first;
    final displayName = _getAssigneeDisplayName(task);
    final initial = _getAssigneeInitial(task);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (details) {
        _showAssigneePopup(context, details.globalPosition, displayName);
      },
      child: CircleAvatar(
        radius: 10,
        backgroundColor: Colors.blueGrey.shade100,
        child: Text(
          initial,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey.shade800,
          ),
        ),
      ),
    );
  }

  void _showAssigneePopup(
    BuildContext context,
    Offset position,
    String name,
  ) async {
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    await showMenu(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 1, 1),
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _getAssigneeDisplayName(Task task) {
    final assignee = task.assignees.first;

    if (assignee.name.trim().isNotEmpty) {
      return assignee.name.trim();
    }

    if (assignee.username.trim().isNotEmpty) {
      return assignee.username.trim();
    }

    return '?';
  }

  String _getAssigneeInitial(Task task) {
    final name = _getAssigneeDisplayName(task);

    if (name.isEmpty) {
      return '?';
    }

    return name.characters.first.toUpperCase();
  }

  Color _getDueDateColor(Task task, BuildContext context) {
    if (!task.hasDueDate || task.done) {
      return Colors.black87;
    }

    final now = DateTime.now();
    final dueDate = task.dueDate!.toLocal();

    if (dueDate.isBefore(now)) {
      return Colors.red.shade400;
    }

    return Colors.black87;
  }

  String _formatDueDate(DateTime dueDate) {
    final date = dueDate.toLocal();

    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];

    final day = date.day;
    final month = months[date.month - 1];
    final hasTime = date.hour != 0 || date.minute != 0;

    if (!hasTime) {
      return '$day $month';
    }

    final hour12 = date.hour == 0
        ? 12
        : (date.hour > 12 ? date.hour - 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'pm' : 'am';

    return '$day $month $hour12:$minute $period';
  }
}