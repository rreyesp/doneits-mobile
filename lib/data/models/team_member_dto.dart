import 'package:vikunja_app/data/models/dto.dart';
import 'package:vikunja_app/data/models/user_dto.dart';
import 'package:vikunja_app/domain/entities/team_member.dart';

class TeamMemberDto extends Dto<TeamMember> {
  final int id;
  final String name;
  final String username;
  final DateTime created;
  final DateTime updated;
  final bool admin;
  final int teamId;
  final UserSettingsDto? settings;

  TeamMemberDto({
    this.id = 0,
    this.name = '',
    required this.username,
    DateTime? created,
    DateTime? updated,
    this.admin = false,
    this.teamId = 0,
    this.settings,
  }) : created = created ?? DateTime.now(),
       updated = updated ?? DateTime.now();

  TeamMemberDto.fromJson(Map<String, dynamic> json)
    : id = json.containsKey('id') ? json['id'] : 0,
      name = json.containsKey('name') ? json['name'] : '',
      username = json['username'],
      created = json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
      updated = json['updated'] != null
          ? DateTime.parse(json['updated'])
          : DateTime.now(),
      admin = json.containsKey('admin') ? json['admin'] : false,
      teamId = json.containsKey('team_id') ? json['team_id'] : 0,
      settings = json.containsKey('settings') && json['settings'] != null
          ? UserSettingsDto.fromJson(json['settings'])
          : null;

  Map<String, dynamic> toJSON() => {
    'id': id,
    'name': name,
    'username': username,
    'created': created.toUtc().toIso8601String(),
    'updated': updated.toUtc().toIso8601String(),
    'admin': admin,
    'team_id': teamId,
    'user_id': id,
    'settings': settings?.toJson(),
  };

  Map<String, dynamic> toUpdateJSON() => {
    'admin': admin,
  };

  @override
  TeamMember toDomain() => TeamMember(
    id: id,
    name: name,
    username: username,
    created: created,
    updated: updated,
    admin: admin,
    teamId: teamId,
    settings: settings?.toDomain(),
  );

  static TeamMemberDto fromDomain(TeamMember member) => TeamMemberDto(
    id: member.id,
    name: member.name,
    username: member.username,
    created: member.created,
    updated: member.updated,
    admin: member.admin,
    teamId: member.teamId,
    settings: member.settings != null
        ? UserSettingsDto.fromDomain(member.settings!)
        : null,
  );
}
