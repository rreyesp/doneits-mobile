import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vikunja_app/core/di/network_provider.dart';
import 'package:vikunja_app/core/di/repository_provider.dart';
import 'package:vikunja_app/domain/entities/project.dart';
import 'package:vikunja_app/domain/entities/team.dart';
import 'package:vikunja_app/domain/entities/team_project.dart';
import 'package:vikunja_app/domain/entities/user.dart';
import 'package:vikunja_app/domain/entities/user_project.dart';

class ProjectSharePage extends ConsumerStatefulWidget {
  final Project project;

  const ProjectSharePage({super.key, required this.project});

  @override
  ConsumerState<ProjectSharePage> createState() => _ProjectSharePageState();
}

class _ProjectSharePageState extends ConsumerState<ProjectSharePage> {
  static const int _readPermission = 0;
  static const int _writePermission = 1;
  static const int _adminPermission = 2;

  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _teamSearchController = TextEditingController();

  List<User> _sharedUsers = [];
  List<Team> _sharedTeams = [];

  List<User> _foundUsers = [];
  List<Team> _foundTeams = [];
  List<Team> _allTeams = [];

  User? _selectedUser;
  Team? _selectedTeam;

  int _selectedUserPermission = _readPermission;
  int _selectedTeamPermission = _readPermission;

  bool _isLoading = true;
  bool _isSearchingUsers = false;
  bool _isSearchingTeams = false;
  bool _isSharingUser = false;
  bool _isSharingTeam = false;

  final Set<String> _removingUsers = {};
  final Set<int> _updatingTeams = {};
  final Set<int> _removingTeams = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _teamSearchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final usersResponse = await ref
        .read(userProjectRepositoryProvider)
        .getAll(widget.project.id);
    final teamsResponse = await ref
        .read(teamProjectRepositoryProvider)
        .getAll(widget.project.id);
    final allTeamsResponse = await ref.read(teamRepositoryProvider).getAll();

    if (!mounted) return;

    setState(() {
      _sharedUsers = usersResponse.isSuccessful
          ? usersResponse.toSuccess().body
          : [];
      _sharedTeams = teamsResponse.isSuccessful
          ? teamsResponse.toSuccess().body
          : [];
      _allTeams = allTeamsResponse.isSuccessful
          ? allTeamsResponse.toSuccess().body
          : [];
      _isLoading = false;
    });
  }

  Future<void> _searchUsers(String value) async {
    final query = value.trim();

    if (query.isEmpty) {
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
      final sharedIds = _sharedUsers.map((e) => e.id).toSet();
      final currentUserId = ref.read(currentUserProvider)?.id;

      setState(() {
        _foundUsers = response.toSuccess().body.where((user) {
          if (currentUserId != null && user.id == currentUserId) {
            return false;
          }
          return !sharedIds.contains(user.id);
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

  void _searchTeams(String value) {
    final query = value.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _foundTeams = [];
        _selectedTeam = null;
        _isSearchingTeams = false;
      });
      return;
    }

    setState(() {
      _isSearchingTeams = true;
      _selectedTeam = null;
    });

    final sharedIds = _sharedTeams.map((e) => e.id).toSet();

    final filtered = _allTeams.where((team) {
      final notShared = !sharedIds.contains(team.id);
      final matches = team.name.toLowerCase().contains(query);
      return notShared && matches;
    }).toList();

    setState(() {
      _foundTeams = filtered;
      _isSearchingTeams = false;
    });
  }

  Future<void> _shareSelectedUser() async {
    final user = _selectedUser;
    if (user == null) return;

    setState(() {
      _isSharingUser = true;
    });

    final response = await ref.read(userProjectRepositoryProvider).create(
          UserProject(
            projectId: widget.project.id,
            username: user.username,
            permission: _selectedUserPermission,
          ),
        );

    if (!mounted) return;

    setState(() {
      _isSharingUser = false;
    });

    if (response.isSuccessful) {
      _userSearchController.clear();
      _foundUsers = [];
      _selectedUser = null;
      _selectedUserPermission = _readPermission;
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User shared successfully')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isError
                ? 'Could not share user: ${response.toError().error}'
                : 'Could not share user',
          ),
        ),
      );
    }
  }

  Future<void> _shareSelectedTeam() async {
    final team = _selectedTeam;
    if (team == null) return;

    setState(() {
      _isSharingTeam = true;
    });

    final response = await ref.read(teamProjectRepositoryProvider).create(
          TeamProject(
            projectId: widget.project.id,
            teamId: team.id,
            permission: _selectedTeamPermission,
          ),
        );

    if (!mounted) return;

    setState(() {
      _isSharingTeam = false;
    });

    if (response.isSuccessful) {
      _teamSearchController.clear();
      _foundTeams = [];
      _selectedTeam = null;
      _selectedTeamPermission = _readPermission;
      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Team shared successfully')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isError
                ? 'Could not share team: ${response.toError().error}'
                : 'Could not share team',
          ),
        ),
      );
    }
  }

  Future<void> _updateTeamPermission(Team team, int permission) async {
    setState(() {
      _updatingTeams.add(team.id);
    });

    final response = await ref.read(teamProjectRepositoryProvider).update(
          TeamProject(
            projectId: widget.project.id,
            teamId: team.id,
            permission: permission,
          ),
        );

    if (!mounted) return;

    setState(() {
      _updatingTeams.remove(team.id);
    });

    if (response.isSuccessful) {
      setState(() {
        _sharedTeams = _sharedTeams.map((t) {
          if (t.id == team.id) {
            return t.copyWith(permission: permission);
          }
          return t;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team permission updated')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isError
                ? 'Could not update team permission: ${response.toError().error}'
                : 'Could not update team permission',
          ),
        ),
      );
    }
  }

  Future<void> _removeUserShare(User user) async {
    setState(() {
      _removingUsers.add(user.username);
    });

    final response = await ref
        .read(userProjectRepositoryProvider)
        .delete(widget.project.id, user.username);

    if (!mounted) return;

    setState(() {
      _removingUsers.remove(user.username);
    });

    if (response.isSuccessful) {
      setState(() {
        _sharedUsers.removeWhere((u) => u.username == user.username);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User share removed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isError
                ? 'Could not remove user share: ${response.toError().error}'
                : 'Could not remove user share',
          ),
        ),
      );
    }
  }

  Future<void> _removeTeamShare(Team team) async {
    setState(() {
      _removingTeams.add(team.id);
    });

    final response = await ref
        .read(teamProjectRepositoryProvider)
        .delete(widget.project.id, team.id);

    if (!mounted) return;

    setState(() {
      _removingTeams.remove(team.id);
    });

    if (response.isSuccessful) {
      setState(() {
        _sharedTeams.removeWhere((t) => t.id == team.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Team share removed')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response.isError
                ? 'Could not remove team share: ${response.toError().error}'
                : 'Could not remove team share',
          ),
        ),
      );
    }
  }

  String _permissionLabel(int permission) {
    switch (permission) {
      case _writePermission:
        return 'Read & Write';
      case _adminPermission:
        return 'Admin';
      case _readPermission:
      default:
        return 'Read only';
    }
  }

  List<DropdownMenuItem<int>> _permissionItems() {
    return [
      DropdownMenuItem(
        value: _readPermission,
        child: Text(_permissionLabel(_readPermission)),
      ),
      DropdownMenuItem(
        value: _writePermission,
        child: Text(_permissionLabel(_writePermission)),
      ),
      DropdownMenuItem(
        value: _adminPermission,
        child: Text(_permissionLabel(_adminPermission)),
      ),
    ];
  }

  Widget _buildUsersCard(BuildContext context) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shared with users',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 640;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _userSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search by username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onChanged: _searchUsers,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _selectedUserPermission,
                        decoration: InputDecoration(
                          labelText: 'Permission',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _permissionItems(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedUserPermission = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _selectedUser == null || _isSharingUser
                              ? null
                              : _shareSelectedUser,
                          child: _isSharingUser
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Share'),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _userSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search by username',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onChanged: _searchUsers,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<int>(
                        value: _selectedUserPermission,
                        decoration: InputDecoration(
                          labelText: 'Permission',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _permissionItems(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedUserPermission = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _selectedUser == null || _isSharingUser
                            ? null
                            : _shareSelectedUser,
                        child: _isSharingUser
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Share'),
                      ),
                    ),
                  ],
                );
              },
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
                  subtitle: Text(
                    user.username,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (_) {
                    setState(() {
                      _selectedUser = user;
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (_sharedUsers.isEmpty)
              Center(
                child: Text(
                  'Not shared with any users yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              )
            else
              ..._sharedUsers.map(
                (user) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline),
                  ),
                  title: Text(
                    user.name.isNotEmpty ? user.name : user.username,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    user.username,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: _removingUsers.contains(user.username)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Remove share',
                          onPressed: () => _removeUserShare(user),
                          icon: const Icon(Icons.delete_outline),
                        ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Note: existing user shares cannot show their current permission here yet because the current User model does not expose permission. Creating new user shares with permission works correctly.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharedTeamTile(BuildContext context, Team team) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 640;

        if (isNarrow) {
          return Container(
            padding: const EdgeInsets.all(12),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      child: Icon(Icons.group_outlined),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            team.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            team.description.isNotEmpty
                                ? team.description
                                : 'No description',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: team.permission,
                  decoration: InputDecoration(
                    labelText: 'Permission',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                  items: _permissionItems(),
                  onChanged: _updatingTeams.contains(team.id)
                      ? null
                      : (value) {
                          if (value == null || value == team.permission) {
                            return;
                          }
                          _updateTeamPermission(team, value);
                        },
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _updatingTeams.contains(team.id) ||
                          _removingTeams.contains(team.id)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          tooltip: 'Remove share',
                          onPressed: () => _removeTeamShare(team),
                          icon: const Icon(Icons.delete_outline),
                        ),
                ),
              ],
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: .35),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                child: Icon(Icons.group_outlined),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      team.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      team.description.isNotEmpty
                          ? team.description
                          : 'No description',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 170,
                child: DropdownButtonFormField<int>(
                  value: team.permission,
                  decoration: InputDecoration(
                    labelText: 'Permission',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    isDense: true,
                  ),
                  items: _permissionItems(),
                  onChanged: _updatingTeams.contains(team.id)
                      ? null
                      : (value) {
                          if (value == null || value == team.permission) {
                            return;
                          }
                          _updateTeamPermission(team, value);
                        },
                ),
              ),
              const SizedBox(width: 8),
              _updatingTeams.contains(team.id) || _removingTeams.contains(team.id)
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton(
                      tooltip: 'Remove share',
                      onPressed: () => _removeTeamShare(team),
                      icon: const Icon(Icons.delete_outline),
                    ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTeamsCard(BuildContext context) {
    return Card(
      elevation: 1.5,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Shared with teams',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 640;

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _teamSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search by team name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onChanged: _searchTeams,
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _selectedTeamPermission,
                        decoration: InputDecoration(
                          labelText: 'Permission',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _permissionItems(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedTeamPermission = value;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 48,
                        child: FilledButton(
                          onPressed: _selectedTeam == null || _isSharingTeam
                              ? null
                              : _shareSelectedTeam,
                          child: _isSharingTeam
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Share'),
                        ),
                      ),
                    ],
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _teamSearchController,
                        decoration: InputDecoration(
                          hintText: 'Search by team name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onChanged: _searchTeams,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<int>(
                        value: _selectedTeamPermission,
                        decoration: InputDecoration(
                          labelText: 'Permission',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: _permissionItems(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            _selectedTeamPermission = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        onPressed: _selectedTeam == null || _isSharingTeam
                            ? null
                            : _shareSelectedTeam,
                        child: _isSharingTeam
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Share'),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_isSearchingTeams) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (_foundTeams.isNotEmpty) ...[
              const SizedBox(height: 12),
              ..._foundTeams.map(
                (team) => RadioListTile<int>(
                  value: team.id,
                  groupValue: _selectedTeam?.id,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    team.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    team.description.isNotEmpty
                        ? team.description
                        : 'No description',
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (_) {
                    setState(() {
                      _selectedTeam = team;
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 18),
            if (_sharedTeams.isEmpty)
              Center(
                child: Text(
                  'Not shared with any teams yet.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                ),
              )
            else
              ..._sharedTeams.map(
                (team) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildSharedTeamTile(context, team),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Share project'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Share "${widget.project.title}"',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 20),
                  _buildUsersCard(context),
                  const SizedBox(height: 20),
                  _buildTeamsCard(context),
                ],
              ),
            ),
    );
  }
}