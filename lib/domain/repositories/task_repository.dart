Future<void> _addSelectedUser() async {
  final user = _selectedUser;
  if (user == null) return;

  setState(() {
    _isAddingUser = true;
  });

  final result = await ref
      .read(taskPageControllerProvider.notifier)
      .addAssigneeToTask(widget.task.id, user);

  if (!mounted) return;

  setState(() {
    _isAddingUser = false;
  });

  if (result.$1) {
    setState(() {
      _assignees.add(user);
      _selectedUser = null;
      _foundUsers = [];
      _assigneeSearchController.clear();
    });
    return;
  }

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.$2 ?? 'No se pudo asignar el usuario a la tarea',
      ),
    ),
  );
}