import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/utils/date_extensions.dart';
import 'package:vikunja_app/core/utils/priority.dart';
import 'package:vikunja_app/domain/entities/label.dart';
import 'package:vikunja_app/domain/entities/new_task_due.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/widgets/date_time_field.dart';
import 'package:vikunja_app/presentation/widgets/label_widget.dart';
import 'package:vikunja_app/presentation/widgets/task/color_picker_dialog.dart';

class AddTaskDialog extends ConsumerStatefulWidget {
  final Future<(bool, String?)> Function(Task taskDraft) onAddTask;
  final String? title;
  final int? projectId;

  const AddTaskDialog({
    super.key,
    required this.onAddTask,
    this.projectId,
    this.title,
  });

  @override
  ConsumerState<AddTaskDialog> createState() => AddTaskDialogState();
}

class AddTaskDialogState extends ConsumerState<AddTaskDialog> {
  final textController = TextEditingController();
  final _labelTypeAheadController = TextEditingController();
  final _assigneeSearchController = TextEditingController();

  NewTaskDue newTaskDue = NewTaskDue.none;
  DateTime? dueDate;
  int? _priority;
  Color? _color;
  List<Label> _labels = [];
  List<User> _assignees = [];

  bool _showDueDateSection = false;
  bool _showAdvancedOptions = false;
  bool _showLabelsSection = false;
  bool _showPrioritySection = false;
  bool _showColorSection = false;
  bool _showAssigneesSection = false;
  bool _showProjectSection = false;

  bool _isSearchingUsers = false;
  bool _isAddingUser = false;
  bool _isLoadingProjects = false;

  List<Label>? _suggestedLabels;
  List<User> _foundUsers = [];
  User? _selectedUser;

  List<Project> _availableProjects = [];
  int? _selectedProjectId;

  Timer? _debounce;
  Timer? _userSearchDebounce;
  Completer<Iterable<String>>? _lastCompleter;
  String? _submitError;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    var title = widget.title;
    if (title != null) {
      textController.text = title;
    }

    _selectedProjectId = widget.projectId;
  }

  @override
  void dispose() {
    textController.dispose();
    _labelTypeAheadController.dispose();
    _assigneeSearchController.dispose();
    _debounce?.cancel();
    _userSearchDebounce?.cancel();
    super.dispose();
  }

  String _colorToHex(Color color) {
    final value = color.toARGB32();
    final rgb = value & 0xFFFFFF;
    return rgb.toRadixString(16).padLeft(6, '0').toUpperCase();
  }

  Future<void> _loadProjects() async {
    if (_availableProjects.isNotEmpty) return;

    setState(() {
      _isLoadingProjects = true;
    });

    final response = await ref.read(projectRepositoryProvider).getAll();

    if (!mounted) return;

    if (response.isSuccessful) {
      final projects = response.toSuccess().body;
      setState(() {
        _availableProjects = _flattenProjects(projects);
        _selectedProjectId ??= widget.projectId ?? _availableProjects.firstOrNull?.id;
        _isLoadingProjects = false;
      });
    } else {
      setState(() {
        _availableProjects = [];
        _isLoadingProjects = false;
      });
    }
  }

  List<Project> _flattenProjects(List<Project> projects) {
    final result = <Project>[];

    void addProject(Project project) {
      result.add(project);
      for (final subproject in project.subprojects) {
        addProject(subproject);
      }
    }

    for (final project in projects) {
      addProject(project);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateTime = DateTime.now();

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(context),
              const SizedBox(height: 20),
              _buildTitleField(context),
              const SizedBox(height: 16),
              _buildCollapsedActionTile(
                context,
                icon: Icons.event_outlined,
                title: l10n.dueDate,
                subtitle: _dueDateSummary(context),
                onTap: () {
                  setState(() {
                    _showDueDateSection = !_showDueDateSection;
                  });
                },
              ),
              if (_showDueDateSection) ...[
                const SizedBox(height: 12),
                _buildDueDateSection(context, l10n, dateTime),
              ],
              const SizedBox(height: 12),
              _buildCollapsedActionTile(
                context,
                icon: Icons.tune,
                title: 'Más opciones',
                subtitle: _advancedSummary(context),
                onTap: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
              ),
              if (_showAdvancedOptions) ...[
                const SizedBox(height: 12),
                _buildAdvancedSection(context),
              ],
              const SizedBox(height: 24),
              _buildActions(context, l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: .75),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.add_task,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context).newTaskName,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).newTaskExample,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: .75),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleField(BuildContext context) {
    return TextField(
      keyboardType: TextInputType.multiline,
      maxLines: null,
      autofocus: true,
      controller: textController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context).newTaskName,
        hintText: AppLocalizations.of(context).newTaskExample,
        prefixIcon: const Icon(Icons.title),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildCollapsedActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.keyboard_arrow_down),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDateSection(
    BuildContext context,
    AppLocalizations l10n,
    DateTime dateTime,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.dueDate,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              taskDueChip(l10n.dueOptionNone, NewTaskDue.none),
              if (dateTime.hour < 21)
                taskDueChip(l10n.dueOptionToday, NewTaskDue.today),
              taskDueChip(l10n.dueOptionTomorrow, NewTaskDue.tomorrow),
              taskDueChip(l10n.dueOptionNextMonday, NewTaskDue.nextMonday),
              if (dateTime.weekday != DateTime.sunday || dateTime.hour < 21)
                taskDueChip(l10n.dueOptionThisWeekend, NewTaskDue.weekend),
              taskDueChip(l10n.dueOptionLaterThisWeek, NewTaskDue.laterThisWeek),
              taskDueChip(l10n.dueInOneWeek, NewTaskDue.nextWeek),
              taskDueChip(l10n.dueOptionCustom, NewTaskDue.custom),
            ],
          ),
          if (newTaskDue == NewTaskDue.custom) ...[
            const SizedBox(height: 16),
            VikunjaDateTimeField(
              label: l10n.enterExactTime,
              onChanged: (value) {
                setState(() {
                  newTaskDue = NewTaskDue.custom;
                  dueDate = value;
                });
              },
            ),
          ],
          if (newTaskDue != NewTaskDue.custom && dueDate != null) ...[
            const SizedBox(height: 16),
            _buildSelectedDatePreview(context),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectedDatePreview(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range_outlined,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              dueDate!.formatShort(),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedSection(BuildContext context) {
    return Column(
      children: [
        _buildCollapsedActionTile(
          context,
          icon: Icons.flag_outlined,
          title: AppLocalizations.of(context).priority,
          subtitle: _priority == null
              ? AppLocalizations.of(context).priorityUnset
              : priorityToString(AppLocalizations.of(context), _priority),
          onTap: () {
            setState(() {
              _showPrioritySection = !_showPrioritySection;
            });
          },
        ),
        if (_showPrioritySection) ...[
          const SizedBox(height: 10),
          _buildPrioritySelector(context),
          const SizedBox(height: 12),
        ],
        _buildCollapsedActionTile(
          context,
          icon: Icons.person_outline,
          title: 'Asignados',
          subtitle: _assignees.isEmpty
              ? 'No hay usuarios asignados'
              : '${_assignees.length} usuario(s) asignado(s)',
          onTap: () {
            setState(() {
              _showAssigneesSection = !_showAssigneesSection;
            });
          },
        ),
        if (_showAssigneesSection) ...[
          const SizedBox(height: 10),
          _buildAssigneesSelector(context),
          const SizedBox(height: 12),
        ],
        if (_assignees.isNotEmpty) ...[
          _buildCollapsedActionTile(
            context,
            icon: Icons.folder_outlined,
            title: 'Proyecto',
            subtitle: _projectSummary(),
            onTap: () async {
              if (_availableProjects.isEmpty) {
                await _loadProjects();
              }
              if (!mounted) return;
              setState(() {
                _showProjectSection = !_showProjectSection;
              });
            },
          ),
          if (_showProjectSection) ...[
            const SizedBox(height: 10),
            _buildProjectSelector(context),
            const SizedBox(height: 12),
          ],
        ],
        _buildCollapsedActionTile(
          context,
          icon: Icons.label_outline,
          title: 'Etiquetas',
          subtitle: _labels.isEmpty
              ? 'No hay etiquetas'
              : '${_labels.length} seleccionada(s)',
          onTap: () {
            setState(() {
              _showLabelsSection = !_showLabelsSection;
            });
          },
        ),
        if (_showLabelsSection) ...[
          const SizedBox(height: 10),
          _buildLabelsSelector(context),
          const SizedBox(height: 12),
        ],
        _buildCollapsedActionTile(
          context,
          icon: Icons.palette_outlined,
          title: AppLocalizations.of(context).setColor,
          subtitle: _color == null || _color == Colors.black
              ? AppLocalizations.of(context).none
              : "#${_colorToHex(_color!)}",
          onTap: () {
            setState(() {
              _showColorSection = !_showColorSection;
            });
          },
        ),
        if (_showColorSection) ...[
          const SizedBox(height: 10),
          _buildColorSelector(context),
        ],
      ],
    );
  }

  Widget _buildPrioritySelector(BuildContext context) {
    return DropdownButtonFormField<int?>(
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.flag_outlined),
        labelText: AppLocalizations.of(context).priority,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      initialValue: _priority,
      isExpanded: true,
      onChanged: (int? newValue) {
        setState(() {
          _priority = newValue;
        });
      },
      items: [
        DropdownMenuItem<int?>(
          value: null,
          child: Text(AppLocalizations.of(context).priorityUnset),
        ),
        DropdownMenuItem<int?>(
          value: 1,
          child: Text(AppLocalizations.of(context).priorityLow),
        ),
        DropdownMenuItem<int?>(
          value: 2,
          child: Text(AppLocalizations.of(context).priorityMedium),
        ),
        DropdownMenuItem<int?>(
          value: 3,
          child: Text(AppLocalizations.of(context).priorityHigh),
        ),
        DropdownMenuItem<int?>(
          value: 4,
          child: Text(AppLocalizations.of(context).priorityUrgent),
        ),
        DropdownMenuItem<int?>(
          value: 5,
          child: Text(AppLocalizations.of(context).priorityDoNow),
        ),
      ],
    );
  }

  Widget _buildAssigneesSelector(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _assigneeSearchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por username',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onChanged: (value) {
                    _userSearchDebounce?.cancel();
                    _userSearchDebounce = Timer(
                      const Duration(milliseconds: 400),
                      () {
                        _searchUsers(value);
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                onPressed: _selectedUser == null || _isAddingUser
                    ? null
                    : _addSelectedUser,
                icon: _isAddingUser
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_add_alt_1),
              ),
            ],
          ),
          if (_isSearchingUsers) ...[
            const SizedBox(height: 12),
            const LinearProgressIndicator(),
          ],
          if (_foundUsers.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._foundUsers.map(
              (user) => RadioListTile<int>(
                value: user.id,
                groupValue: _selectedUser?.id,
                contentPadding: EdgeInsets.zero,
                title: Text(user.name.isNotEmpty ? user.name : user.username),
                subtitle: Text(user.username),
                onChanged: (_) {
                  setState(() {
                    _selectedUser = user;
                  });
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          if (_assignees.isEmpty)
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'No hay usuarios asignados.',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _assignees.map((user) {
                final displayName =
                    user.name.isNotEmpty ? user.name : user.username;

                return Chip(
                  avatar: CircleAvatar(
                    child: Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                    ),
                  ),
                  label: Text(displayName),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => _removeAssignee(user),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildProjectSelector(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: _isLoadingProjects
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(),
            )
          : DropdownButtonFormField<int>(
              value: _selectedProjectId,
              isExpanded: true,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.folder_outlined),
                labelText: 'Proyecto',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              items: _availableProjects
                  .map(
                    (project) => DropdownMenuItem<int>(
                      value: project.id,
                      child: Text(project.title),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedProjectId = value;
                });
              },
            ),
    );
  }

  Widget _buildLabelsSelector(BuildContext context) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            Expanded(
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text == '') {
                    return const Iterable<String>.empty();
                  }

                  if (_debounce?.isActive ?? false) {
                    _debounce!.cancel();
                    _lastCompleter?.complete(const Iterable<String>.empty());
                  }

                  final completer = Completer<Iterable<String>>();
                  _lastCompleter = completer;

                  _debounce = Timer(const Duration(milliseconds: 500), () async {
                    var labels = await _searchLabel(textEditingValue.text);
                    if (!completer.isCompleted) {
                      completer.complete(labels);
                    }
                  });

                  return completer.future;
                },
                focusNode: FocusNode(),
                textEditingController: _labelTypeAheadController,
                onSelected: (String selection) {
                  _addLabel(selection);
                },
                fieldViewBuilder: (
                  BuildContext context,
                  TextEditingController textEditingController,
                  FocusNode focusNode,
                  VoidCallback onFieldSubmitted,
                ) {
                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: 'Etiqueta',
                      hintText: 'Buscar o crear etiqueta',
                      prefixIcon: const Icon(Icons.label_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filledTonal(
              onPressed: () =>
                  _createAndAddLabel(_labelTypeAheadController.text),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_labels.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'No hay etiquetas agregadas.',
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _labels.map((label) {
              return LabelWidget(
                label: label,
                onDelete: () => _removeLabel(label),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildColorSelector(BuildContext context) {
    final effectiveColor = (_color == null || _color == Colors.black)
        ? null
        : _color;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: .35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ElevatedButton(
              style: effectiveColor == null
                  ? null
                  : ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (_) => effectiveColor,
                      ),
                    ),
              onPressed: _onColorEdit,
              child: Text(
                AppLocalizations.of(context).setColor,
                style: effectiveColor == null
                    ? null
                    : TextStyle(
                        color: effectiveColor.computeLuminance() > 0.5
                            ? Colors.black
                            : Colors.white,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            effectiveColor != null
                ? "#${_colorToHex(effectiveColor)}"
                : AppLocalizations.of(context).none,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, AppLocalizations l10n) {
  return Column(
    children: [
      if (_submitError != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withValues(alpha: .25)),
          ),
          child: Text(
            _submitError!,
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting ? null : () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _submit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add),
              label: Text(l10n.add),
            ),
          ),
        ],
      ),
    ],
  );
}

  String _dueDateSummary(BuildContext context) {
    if (dueDate == null) {
      return AppLocalizations.of(context).dueOptionNone;
    }
    return dueDate!.formatShort();
  }

  String _advancedSummary(BuildContext context) {
    final parts = <String>[];

    if (_priority != null) {
      parts.add(priorityToString(AppLocalizations.of(context), _priority));
    }
    if (_assignees.isNotEmpty) {
      parts.add('${_assignees.length} asignado(s)');
    }
    if (_assignees.isNotEmpty && _selectedProjectId != null) {
      final selectedProject = _availableProjects.firstWhereOrNull(
        (project) => project.id == _selectedProjectId,
      );
      if (selectedProject != null) {
        parts.add('Proyecto: ${selectedProject.title}');
      }
    }
    if (_labels.isNotEmpty) {
      parts.add('${_labels.length} etiqueta(s)');
    }
    if (_color != null && _color != Colors.black) {
      parts.add(AppLocalizations.of(context).setColor);
    }

    if (parts.isEmpty) {
      return 'Prioridad, asignados, etiquetas y color';
    }

    return parts.join(' • ');
  }

  String _projectSummary() {
    if (_isLoadingProjects) {
      return 'Cargando proyectos...';
    }

    if (_selectedProjectId == null) {
      return 'Selecciona un proyecto';
    }

    final selectedProject = _availableProjects.firstWhereOrNull(
      (project) => project.id == _selectedProjectId,
    );

    return selectedProject?.title ?? 'Selecciona un proyecto';
  }

  Widget taskDueChip(String name, NewTaskDue thisNewTaskDue) {
    return ChoiceChip(
      label: Text(name),
      selected: newTaskDue == thisNewTaskDue,
      onSelected: (value) {
        newTaskDue = thisNewTaskDue;
        setState(() {
          if (newTaskDue == NewTaskDue.custom ||
              newTaskDue == NewTaskDue.none) {
            dueDate = null;
          } else {
            dueDate = newTaskDue.calculateDate(DateTime.now());
          }
        });
      },
    );
  }

  Future<void> _searchUsers(String value) async {
    final query = value.trim();

    if (query.isEmpty) {
      if (!mounted) return;
      setState(() {
        _foundUsers = [];
        _selectedUser = null;
        _isSearchingUsers = false;
      });
      return;
    }

    setState(() {
      _isSearchingUsers = true;
      _selectedUser = null;
    });

    final response = await ref.read(userRepositoryProvider).searchUsers(query);

    if (!mounted) return;

    if (response.isSuccessful) {
      final assignedIds = _assignees.map((e) => e.id).toSet();

      setState(() {
        _foundUsers = response.toSuccess().body.where((user) {
          return !assignedIds.contains(user.id);
        }).toList();
        _isSearchingUsers = false;
      });
    } else {
      setState(() {
        _foundUsers = [];
        _isSearchingUsers = false;
      });
    }
  }

  Future<void> _addSelectedUser() async {
    final user = _selectedUser;
    if (user == null) return;

    setState(() {
      _isAddingUser = true;
    });

    if (_availableProjects.isEmpty) {
      await _loadProjects();
    }

    if (!mounted) return;

    setState(() {
      _assignees.add(user);
      _selectedUser = null;
      _foundUsers = [];
      _assigneeSearchController.clear();
      _showProjectSection = true;
      _isAddingUser = false;
    });
  }

  void _removeAssignee(User user) {
    setState(() {
      _assignees.removeWhere((u) => u.id == user.id);
      if (_assignees.isEmpty) {
        _showProjectSection = false;
        _selectedProjectId = widget.projectId;
      }
    });
  }

  Future<List<String>> _searchLabel(String query) async {
    var labelsResponse = await ref.read(labelRepositoryProvider).getAll(query: query);

    if (labelsResponse.isSuccessful) {
      var labels = labelsResponse.toSuccess().body;

      labels.removeWhere((labelToRemove) => _labels.contains(labelToRemove));
      _suggestedLabels = labels;

      return labels.map((e) => e.title).toList();
    }
    return [];
  }

  void _addLabel(String labelTitle) {
    var label = _suggestedLabels?.firstWhereOrNull((e) => e.title == labelTitle);

    if (label != null) {
      setState(() {
        _labels.add(label);
        _labelTypeAheadController.clear();
      });
    }
  }

  void _removeLabel(Label label) {
    setState(() {
      _labels.removeWhere((l) => l.id == label.id);
    });
  }

  void _createAndAddLabel(String labelTitle) async {
    if (labelTitle.isEmpty ||
        _suggestedLabels?.firstWhereOrNull((label) => label.title == labelTitle) !=
            null) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);

    if (currentUser != null) {
      final newLabel = Label(title: labelTitle, createdBy: currentUser);

      ref.read(labelRepositoryProvider).create(newLabel).then((createdLabel) {
        if (createdLabel.isSuccessful) {
          setState(() {
            _labels.add(createdLabel.toSuccess().body);
            _labelTypeAheadController.clear();
          });
        }
      });
    }
  }

  void _onColorEdit() {
    var pickerColor = _color ?? Colors.black;
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        pickerColor,
        (color) {
          setState(() {
            _color = color == Colors.black ? null : color;
          });
          Navigator.of(context).pop();
        },
        () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _submit() async {
  if (textController.text.trim().isEmpty) return;

  final currentUser = ref.read(currentUserProvider);
  if (currentUser == null) return;

  setState(() {
    _submitError = null;
    _isSubmitting = true;
  });

  final taskDraft = Task(
    title: textController.text.trim(),
    dueDate: dueDate,
    priority: _priority,
    color: _color,
    labels: _labels,
    assignees: _assignees,
    createdBy: currentUser,
    projectId: _selectedProjectId ?? widget.projectId,
  );

  final result = await widget.onAddTask(taskDraft);

  if (!mounted) return;

  setState(() {
    _isSubmitting = false;
  });

  if (result.$1) {
    Navigator.pop(context);
  } else {
    setState(() {
      _submitError = result.$2 ?? 'No se pudo agregar la tarea';
    });
  }
}
}