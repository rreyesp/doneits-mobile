import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:vikunja_app/core/utils/date_extensions.dart';
import 'package:vikunja_app/domain/entities/label.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/pages/task/task_edit_page.dart';
import 'package:vikunja_app/presentation/widgets/label_widget.dart';

class TaskBottomSheet extends StatefulWidget {
  final Task task;
  final bool showInfo;
  final bool loading;
  final Function onEdit;

  const TaskBottomSheet({
    super.key,
    required this.task,
    required this.onEdit,
    this.loading = false,
    this.showInfo = false,
  });

  @override
  TaskBottomSheetState createState() => TaskBottomSheetState();
}

class TaskBottomSheetState extends State<TaskBottomSheet> {
  TaskBottomSheetState();

  String priorityToStringLocalized(BuildContext context, int? priority) {
    if (priority == null) return AppLocalizations.of(context).priorityUnset;
    switch (priority) {
      case 0:
        return AppLocalizations.of(context).priorityUnset;
      case 1:
        return AppLocalizations.of(context).priorityLow;
      case 2:
        return AppLocalizations.of(context).priorityMedium;
      case 3:
        return AppLocalizations.of(context).priorityHigh;
      case 4:
        return AppLocalizations.of(context).priorityUrgent;
      case 5:
        return AppLocalizations.of(context).priorityDoNow;
      default:
        return '';
    }
  }

  void _openEditSection(TaskEditSection section) {
    Navigator.of(context).pop();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskEditPage(
          task: widget.task,
          initialSection: section,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.88,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context),
                    const SizedBox(height: 16),
                    if (widget.task.labels.isNotEmpty) ...[
                      _buildSectionCard(
                        context,
                        title: 'Etiquetas',
                        icon: Icons.label_outline,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _openEditSection(TaskEditSection.labels),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: widget.task.labels.map((Label label) {
                                return LabelWidget(label: label);
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _buildSectionCard(
                      context,
                      title: l10n.description,
                      icon: Icons.description_outlined,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () =>
                            _openEditSection(TaskEditSection.description),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: widget.task.description.isNotEmpty
                              ? HtmlWidget(widget.task.description)
                              : Text(
                                  l10n.noDescription,
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      context,
                      title: 'Asignados',
                      icon: Icons.person_outline,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _openEditSection(TaskEditSection.assignees),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: widget.task.assignees.isEmpty
                              ? Text(
                                  'No hay usuarios asignados',
                                  style: TextStyle(
                                    color: theme.hintColor,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Wrap(
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: widget.task.assignees.map((user) {
                                    final displayName = user.name.isNotEmpty
                                        ? user.name
                                        : user.username;

                                    return Chip(
                                      avatar: CircleAvatar(
                                        child: Text(
                                          displayName.isNotEmpty
                                              ? displayName[0].toUpperCase()
                                              : '?',
                                        ),
                                      ),
                                      label: Text(displayName),
                                    );
                                  }).toList(),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      context,
                      title: 'Detalles',
                      icon: Icons.tune,
                      child: Column(
                        children: [
                          _buildPropertyTile(
                            context,
                            icon: Icons.access_time,
                            label: l10n.dueDateLabel,
                            value: widget.task.hasDueDate
                                ? widget.task.dueDate!.toLocal().formatShort()
                                : l10n.noDueDate,
                            onTap: () =>
                                _openEditSection(TaskEditSection.dueDate),
                          ),
                          const SizedBox(height: 10),
                          _buildPropertyTile(
                            context,
                            icon: Icons.play_arrow_rounded,
                            label: l10n.startDateLabel,
                            value: widget.task.hasStartDate
                                ? widget.task.startDate!.toLocal().formatShort()
                                : l10n.noStartDate,
                            onTap: () =>
                                _openEditSection(TaskEditSection.startDate),
                          ),
                          const SizedBox(height: 10),
                          _buildPropertyTile(
                            context,
                            icon: Icons.stop_rounded,
                            label: l10n.endDateLabel,
                            value: widget.task.hasEndDate
                                ? widget.task.endDate!.toLocal().formatShort()
                                : l10n.noEndDate,
                            onTap: () =>
                                _openEditSection(TaskEditSection.endDate),
                          ),
                          const SizedBox(height: 10),
                          _buildPropertyTile(
                            context,
                            icon: Icons.priority_high,
                            label: l10n.priority,
                            value: widget.task.priority != null
                                ? priorityToStringLocalized(
                                    context,
                                    widget.task.priority,
                                  )
                                : l10n.noPriority,
                            onTap: () =>
                                _openEditSection(TaskEditSection.priority),
                          ),
                          const SizedBox(height: 10),
                          _buildPropertyTile(
                            context,
                            icon: Icons.percent,
                            label: 'Progreso',
                            value: widget.task.percentDone != null
                                ? "${(widget.task.percentDone! * 100).toInt()}%"
                                : l10n.percentUnset,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.task_alt,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _openEditSection(TaskEditSection.title),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.task.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildInfoChip(
                          context,
                          icon: Icons.check_circle_outline,
                          label: widget.task.done ? 'Done' : 'Tarea',
                        ),
                        if (widget.task.hasDueDate)
                          _buildInfoChip(
                            context,
                            icon: Icons.event,
                            label: widget.task.dueDate!.toLocal().formatShort(),
                          ),
                        _buildInfoChip(
                          context,
                          icon: Icons.flag_outlined,
                          label: widget.task.priority != null
                              ? priorityToStringLocalized(
                                  context,
                                  widget.task.priority,
                                )
                              : AppLocalizations.of(context).priorityUnset,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onEdit();
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: .35),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: .35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: .75),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 6),
          Text(label),
        ],
      ),
    );
  }
}