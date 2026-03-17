import 'dart:async';

import 'package:background_downloader/background_downloader.dart'
    show TaskStatus, FileDownloader;
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/core/utils/priority.dart';
import 'package:vikunja_app/core/utils/repeat_after_parse.dart';
import 'package:vikunja_app/core/utils/repeat_after_unit.dart';
import 'package:vikunja_app/domain/entities/label.dart';
import 'package:vikunja_app/domain/entities/task.dart';
import 'package:vikunja_app/domain/entities/task_reminder.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/l10n/gen/app_localizations.dart';
import 'package:vikunja_app/presentation/manager/task_page_controller.dart';
import 'package:vikunja_app/presentation/pages/task/edit_description.dart';
import 'package:vikunja_app/presentation/widgets/date_time_field.dart';
import 'package:vikunja_app/presentation/widgets/label_widget.dart';
import 'package:vikunja_app/presentation/widgets/task/color_picker_dialog.dart';
import 'package:vikunja_app/presentation/widgets/task/task_comments.dart';
import 'package:vikunja_app/presentation/widgets/task/task_delete_dialog.dart';
import 'package:vikunja_app/presentation/widgets/task/task_save_dialog.dart';

enum TaskEditSection {
  title,
  description,
  dueDate,
  startDate,
  endDate,
  repeatAfter,
  reminders,
  priority,
  labels,
  assignees,
  color,
}

class TaskEditPage extends ConsumerStatefulWidget {
  final Task task;
  final TaskEditSection? initialSection;

  TaskEditPage({
    required this.task,
    this.initialSection,
  }) : super(key: Key(task.toString()));

  @override
  TaskEditPageState createState() => TaskEditPageState();
}

class TaskEditPageState extends ConsumerState<TaskEditPage> {
  final _formKey = GlobalKey<FormState>();

  final _titleFocusNode = FocusNode();

  final _titleKey = GlobalKey();
  final _descriptionKey = GlobalKey();
  final _dueDateKey = GlobalKey();
  final _startDateKey = GlobalKey();
  final _endDateKey = GlobalKey();
  final _repeatAfterKey = GlobalKey();
  final _remindersKey = GlobalKey();
  final _priorityKey = GlobalKey();
  final _labelsKey = GlobalKey();
  final _assigneesKey = GlobalKey();
  final _colorKey = GlobalKey();

  String? _title, _description;
  DateTime? _dueDate, _startDate, _endDate;
  int _repeatAfterValue = 0;
  RepeatAfterUnit _repeatAfterUnit = RepeatAfterUnit.days;
  int? _priority;
  List<TaskReminder>? _reminderDates;
  List<Label>? _labels;
  List<User> _assignees = [];
  List<User> _foundUsers = [];
  User? _selectedUser;
  bool _isSearchingUsers = false;
  bool _isAddingUser = false;
  Color? _color;

  List<Label>? _suggestedLabels;
  final _labelTypeAheadController = TextEditingController();
  final _assigneeSearchController = TextEditingController();

  Timer? _debounce;
  Timer? _userSearchDebounce;
  Completer<Iterable<String>>? _lastCompleter;

  bool changed = false;

  @override
  void initState() {
    _reminderDates = List.of(widget.task.reminderDates);
    _labels = List.of(widget.task.labels);
    _assignees = List.of(widget.task.assignees);

    _priority = widget.task.priority;
    _description = widget.task.description;
    _color = widget.task.color;

    _dueDate = widget.task.dueDate;
    _startDate = widget.task.startDate;
    _endDate = widget.task.endDate;

    _repeatAfterValue = getRepeatAfterValueFromDuration(
      widget.task.repeatAfter,
    );
    _repeatAfterUnit = getRepeatAfterTypeFromDuration(widget.task.repeatAfter);

    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openInitialSection();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _userSearchDebounce?.cancel();
    _labelTypeAheadController.dispose();
    _assigneeSearchController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _openInitialSection() {
    final section = widget.initialSection;
    if (section == null) return;

    switch (section) {
      case TaskEditSection.title:
        _scrollToKey(_titleKey);
        _titleFocusNode.requestFocus();
        break;
      case TaskEditSection.description:
        _scrollToKey(_descriptionKey);
        Future.delayed(const Duration(milliseconds: 200), () async {
          if (!mounted) return;
          var description = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (buildContext) =>
                  EditDescription(initialText: _description),
            ),
          );
          if (!mounted) return;
          setState(() {
            if (description != null) {
              _description = description;
              _checkChanged();
            }
          });
        });
        break;
      case TaskEditSection.dueDate:
        _scrollToKey(_dueDateKey);
        break;
      case TaskEditSection.startDate:
        _scrollToKey(_startDateKey);
        break;
      case TaskEditSection.endDate:
        _scrollToKey(_endDateKey);
        break;
      case TaskEditSection.repeatAfter:
        _scrollToKey(_repeatAfterKey);
        break;
      case TaskEditSection.reminders:
        _scrollToKey(_remindersKey);
        break;
      case TaskEditSection.priority:
        _scrollToKey(_priorityKey);
        break;
      case TaskEditSection.labels:
        _scrollToKey(_labelsKey);
        break;
      case TaskEditSection.assignees:
        _scrollToKey(_assigneesKey);
        break;
      case TaskEditSection.color:
        _scrollToKey(_colorKey);
        break;
    }
  }

  void _scrollToKey(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
        alignment: 0.15,
      );
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return PopScope(
      canPop: !changed,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _showConfirmationDialog();
        }
      },
      child: Scaffold(
        appBar: _buildAppBar(),
        body: _buildForm(context),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                if (_formKey.currentState?.validate() == true) {
                  _saveTask(ctx);
                }
              },
              icon: const Icon(Icons.save_outlined),
              label: Text(AppLocalizations.of(context).save),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context).editTaskTitle),
          Text(
            widget.task.title.isNotEmpty
                ? widget.task.title
                : AppLocalizations.of(context).newTaskName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).hintColor,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context).delete,
          icon: const Icon(Icons.delete_outline),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return TaskDeleteDialog(
                  widget.task.id,
                  onConfirm: () async {
                    var success = await ref
                        .read(taskPageControllerProvider.notifier)
                        .deleteTask(widget.task.id);

                    if (context.mounted) {
                      if (success) {
                        Navigator.of(context).pop();
                        Navigator.of(context).pop(widget.task);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              AppLocalizations.of(context).taskDeleteError,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  onCancel: () {
                    Navigator.of(context).pop();
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }

  Form _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: <Widget>[
          _buildHeroHeader(),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Información básica',
            icon: Icons.edit_note,
            children: [
              _buildTitle(),
              const SizedBox(height: 12),
              _buildDescription(context),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Planificación',
            icon: Icons.schedule,
            children: [
              _buildDueDate(),
              _buildStartDate(),
              _buildEndDate(),
              _buildRepeatAfter(),
              _buildReminderList(),
              _buildAddReminderButton(context),
            ],
          ),
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Organización',
            icon: Icons.dashboard_customize_outlined,
            children: [
              _buildPriority(),
              const SizedBox(height: 16),
              _buildAssignees(),
              const SizedBox(height: 16),
              _buildAddLabel(context),
              const SizedBox(height: 12),
              _buildLabelList(),
              const SizedBox(height: 16),
              _buildColor(),
            ],
          ),
          if (widget.task.attachments.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSectionCard(
              title: 'Adjuntos',
              icon: Icons.attach_file,
              children: [
                _buildAttachments(),
              ],
            ),
          ],
          const SizedBox(height: 12),
          _buildSectionCard(
            title: 'Comentarios',
            icon: Icons.comment_outlined,
            children: [
              _buildComments(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Container(
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
              color: Theme.of(context).colorScheme.surface.withValues(alpha: .7),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.task_alt,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.id == 0
                      ? AppLocalizations.of(context).newTaskName
                      : AppLocalizations.of(context).editTaskTitle,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Organiza los detalles, fechas, recordatorios y prioridad en un solo lugar.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: .75,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
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
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      key: _titleKey,
      child: TextFormField(
        focusNode: _titleFocusNode,
        maxLines: null,
        keyboardType: TextInputType.multiline,
        initialValue: widget.task.title,
        onChanged: (title) {
          _title = title;
          _checkChanged();
        },
        style: Theme.of(context).textTheme.titleMedium,
        decoration: InputDecoration(
          labelText: AppLocalizations.of(context).title,
          hintText: AppLocalizations.of(context).newTaskName,
          prefixIcon: const Icon(Icons.title),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    final hasDescription = _description != null && _description!.isNotEmpty;

    return Container(
      key: _descriptionKey,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          var description = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (buildContext) =>
                  EditDescription(initialText: _description),
            ),
          );
          setState(() {
            if (description != null) {
              _description = description;
              _checkChanged();
            }
          });
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.description_outlined,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).description,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).hintColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              hasDescription
                  ? HtmlWidget(_description!)
                  : Text(
                      AppLocalizations.of(context).noDescription,
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDueDate() {
    return Container(
      key: _dueDateKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: VikunjaDateTimeField(
          icon: const Icon(Icons.event_available),
          label: AppLocalizations.of(context).dueDateLabel,
          initialValue: widget.task.dueDate,
          onChanged: (duedate) {
            _dueDate = duedate;
            _checkChanged();
          },
        ),
      ),
    );
  }

  Widget _buildStartDate() {
    return Container(
      key: _startDateKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: VikunjaDateTimeField(
          icon: const Icon(Icons.play_circle_outline),
          label: AppLocalizations.of(context).startDateLabel,
          initialValue: widget.task.startDate,
          onChanged: (startDate) {
            _startDate = startDate;
            _checkChanged();
          },
        ),
      ),
    );
  }

  Widget _buildEndDate() {
    return Container(
      key: _endDateKey,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6.0),
        child: VikunjaDateTimeField(
          icon: const Icon(Icons.stop_circle_outlined),
          label: AppLocalizations.of(context).endDateLabel,
          initialValue: widget.task.endDate,
          onChanged: (endDate) {
            _endDate = endDate;
            _checkChanged();
          },
        ),
      ),
    );
  }

  Widget _buildRepeatAfter() {
    var localizations = AppLocalizations.of(context);

    return Container(
      key: _repeatAfterKey,
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: .35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            const Icon(Icons.repeat),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: TextFormField(
                keyboardType: TextInputType.number,
                initialValue: getRepeatAfterValueFromDuration(
                  widget.task.repeatAfter,
                ).toString(),
                onChanged: (newValue) {
                  _repeatAfterValue = int.tryParse(newValue) ?? 0;
                  _checkChanged();
                },
                decoration: InputDecoration(
                  labelText: localizations.repeatAfter,
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<RepeatAfterUnit>(
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
                isExpanded: true,
                initialValue: _repeatAfterUnit,
                onChanged: (RepeatAfterUnit? newType) {
                  if (newType != null) {
                    _repeatAfterUnit = newType;
                  }
                  _checkChanged();
                },
                items: RepeatAfterUnit.values
                    .map<DropdownMenuItem<RepeatAfterUnit>>((value) {
                      return DropdownMenuItem<RepeatAfterUnit>(
                        value: value,
                        child: Text(value.toLocalizedString(context)),
                      );
                    })
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderList() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        children:
            _reminderDates?.map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: VikunjaDateTimeField(
                  label: AppLocalizations.of(context).reminder,
                  initialValue: e.reminder,
                  onChanged: (date) {
                    if (date != null) {
                      e.reminder = date;
                    } else {
                      _reminderDates?.remove(e);
                    }
                  },
                ),
              );
            }).toList() ??
            [],
      ),
    );
  }

  Widget _buildAddReminderButton(BuildContext context) {
    return Container(
      key: _remindersKey,
      child: Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 4),
        child: OutlinedButton.icon(
          onPressed: () => _addNewReminder(context),
          icon: const Icon(Icons.alarm_add_outlined),
          label: Text(AppLocalizations.of(context).addReminder),
        ),
      ),
    );
  }

  Widget _buildPriority() {
    return Container(
      key: _priorityKey,
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.flag_outlined),
          labelText: AppLocalizations.of(context).priority,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        initialValue: priorityToString(AppLocalizations.of(context), _priority),
        isExpanded: true,
        onChanged: (String? newValue) {
          _priority = priorityFromString(AppLocalizations.of(context), newValue);
          _checkChanged();
        },
        items:
            [
              AppLocalizations.of(context).priorityUnset,
              AppLocalizations.of(context).priorityLow,
              AppLocalizations.of(context).priorityMedium,
              AppLocalizations.of(context).priorityHigh,
              AppLocalizations.of(context).priorityUrgent,
              AppLocalizations.of(context).priorityDoNow,
            ].map((String value) {
              return DropdownMenuItem(value: value, child: Text(value));
            }).toList(),
      ),
    );
  }

  Widget _buildAddLabel(BuildContext context) {
    return Container(
      key: _labelsKey,
      child: Row(
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
              fieldViewBuilder:
                  (
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
            onPressed: () => _createAndAddLabel(_labelTypeAheadController.text),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildColor() {
    final Color? effectiveColor = (_color == null || _color == Colors.black)
        ? null
        : _color;

    return Container(
      key: _colorKey,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest
              .withValues(alpha: .35),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: <Widget>[
            const Icon(Icons.palette_outlined),
            const SizedBox(width: 12),
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
                  ? "#${effectiveColor.toHexString()}"
                  : AppLocalizations.of(context).none,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachments() {
    return ListView.separated(
      separatorBuilder: (context, index) => const Divider(),
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.task.attachments.length,
      itemBuilder: (context, index) {
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(
            child: Icon(Icons.attach_file),
          ),
          title: Text(widget.task.attachments[index].file.name),
          trailing: IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () async {
              var taskId = await ref
                  .read(taskRepositoryProvider)
                  .downloadAttachment(
                    widget.task.id,
                    widget.task.attachments[index],
                  );
              if (taskId.status == TaskStatus.complete) {
                FileDownloader().openFile(task: taskId.task);
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildComments() {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: TaskComments(taskId: widget.task.id),
    );
  }

  Widget _buildLabelList() {
    final items = _labels ?? [];

    if (items.isEmpty) {
      return Text(
        'No hay etiquetas agregadas.',
        style: TextStyle(
          color: Theme.of(context).hintColor,
          fontStyle: FontStyle.italic,
        ),
      );
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items.map((label) {
        return LabelWidget(
          label: label,
          onDelete: () => _removeLabel(label),
        );
      }).toList(),
    );
  }

  Future<List<String>> _searchLabel(String query) async {
    var labelsResponse = await ref
        .read(labelRepositoryProvider)
        .getAll(query: query);

    if (labelsResponse.isSuccessful) {
      var labels = labelsResponse.toSuccess().body;

      labels.removeWhere(
        (labelToRemove) => _labels?.contains(labelToRemove) == true,
      );
      _suggestedLabels = labels;

      return labels.map((e) => e.title).toList();
    }
    return [];
  }

  void _addLabel(String labelTitle) {
    var label = _suggestedLabels?.firstWhereOrNull(
      (e) => e.title == labelTitle,
    );

    if (label != null) {
      setState(() {
        _labels?.add(label);
        _labelTypeAheadController.clear();
      });
    }

    _checkChanged();
  }

  void _removeLabel(Label label) {
    setState(() {
      _labels?.removeWhere((l) => l.id == label.id);
    });
  }

  void _createAndAddLabel(String labelTitle) async {
    if (labelTitle.isEmpty ||
        _suggestedLabels?.firstWhereOrNull(
              (label) => label.title == labelTitle,
            ) !=
            null) {
      return;
    }

    final currentUser = ref.read(currentUserProvider);

    if (currentUser != null) {
      final newLabel = Label(title: labelTitle, createdBy: currentUser);

      ref.read(labelRepositoryProvider).create(newLabel).then((createdLabel) {
        if (createdLabel.isSuccessful) {
          setState(() {
            _labels?.add(createdLabel.toSuccess().body);
            _labelTypeAheadController.clear();
          });
        }
      });

      _checkChanged();
    }
  }

  Future<void> _addNewReminder(BuildContext context) async {
    var selectedDate = await showDialog<DateTime>(
      context: context,
      builder: (_) => DatePickerDialog(
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime(2100),
        initialCalendarMode: DatePickerMode.day,
      ),
    );

    if (selectedDate != null && context.mounted) {
      var selectedTime = await showDialog<TimeOfDay>(
        context: context,
        builder: (_) =>
            TimePickerDialog(initialTime: TimeOfDay.fromDateTime(selectedDate)),
      );

      if (selectedTime != null) {
        setState(() {
          _reminderDates?.add(
            TaskReminder(
              selectedDate.copyWith(
                hour: selectedTime.hour,
                minute: selectedTime.minute,
              ),
            ),
          );

          _checkChanged();
        });
      }
    }
  }

  void _onColorEdit() {
    var pickerColor = _color ?? Colors.black;
    showDialog(
      context: context,
      builder: (context) => ColorPickerDialog(
        pickerColor,
        (color) {
          if (color != Colors.black) {
            setState(() {
              _color = color;
            });
          } else {
            setState(() {
              _color = null;
            });
          }
          Navigator.of(context).pop();

          _checkChanged();
        },
        () {
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TaskSaveDialog(
          onConfirm: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          onCancel: () {
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildAssignees() {
    return Container(
      key: _assigneesKey,
      child: Container(
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
          crossAxisAlignment: CrossAxisAlignment.start,
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
      ),
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

    if (!mounted) return;

    setState(() {
      _assignees.add(user);
      _selectedUser = null;
      _foundUsers = [];
      _assigneeSearchController.clear();
      _isAddingUser = false;
      _checkChanged();
    });
  }

  void _removeAssignee(User user) {
    setState(() {
      _assignees.removeWhere((u) => u.id == user.id);
      _checkChanged();
    });
  }

  void _checkChanged() {
    setState(() {
      var repeatAfterValue = getRepeatAfterValueFromDuration(
        widget.task.repeatAfter,
      );
      var repeatAfterType = getRepeatAfterTypeFromDuration(
        widget.task.repeatAfter,
      );

      var repeatAfter = repeatAfterType.getDuration(repeatAfterValue);

      final assigneeIdsCurrent = widget.task.assignees.map((e) => e.id).toList()..sort();
      final assigneeIdsEdited = _assignees.map((e) => e.id).toList()..sort();

      changed =
          widget.task.title != _title ||
          widget.task.description != _description ||
          widget.task.dueDate != _dueDate ||
          widget.task.startDate != _startDate ||
          widget.task.endDate != _endDate ||
          widget.task.repeatAfter != repeatAfter ||
          widget.task.priority != _priority ||
          widget.task.reminderDates != _reminderDates ||
          widget.task.labels != _labels ||
          widget.task.color != _color ||
          !const ListEquality<int>().equals(assigneeIdsCurrent, assigneeIdsEdited);
    });
  }

  Future<void> _saveTask(BuildContext context) async {
    _reminderDates?.removeWhere((d) => d.reminder == DateTime(0));

    final updatedTask =
        widget.task.copyWith(
            title: _title,
            description: _description,
            reminderDates: _reminderDates,
            priority: _priority,
            labels: _labels,
            assignees: _assignees,
            repeatAfter: _repeatAfterUnit.getDuration(_repeatAfterValue),
          )
          ..dueDate = _dueDate
          ..startDate = _startDate
          ..endDate = _endDate
          ..color = _color;

    if (_labels != null) {
      var updateLabelSuccess = await ref
          .read(taskLabelBulkRepositoryProvider)
          .update(updatedTask, _labels!);

      if (!updateLabelSuccess.isSuccessful && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).taskSaveError)),
        );
        return;
      }
    }

    var saveSuccess = await ref
        .read(taskPageControllerProvider.notifier)
        .updateTask(updatedTask);

    if (context.mounted) {
      if (saveSuccess) {
        Navigator.of(context).pop(updatedTask);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).taskUpdatedSuccess),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).taskSaveError)),
        );
      }
    }
  }
}