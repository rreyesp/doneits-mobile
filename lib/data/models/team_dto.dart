import 'package:vikunja_app/data/models/dto.dart';
import 'package:vikunja_app/data/models/team_member_dto.dart';
import 'package:vikunja_app/data/models/user_dto.dart';
import 'package:vikunja_app/domain/entities/team.dart';

class TeamDto extends Dto<Team> {
  final int id;
  final String name;
  final String description;
  final List<TeamMemberDto> members;
  final int permission;
  final String externalId;
  final bool isPublic;
  final UserDto? createdBy;
  final DateTime created;
  final DateTime updated;

  TeamDto({
    this.id = 0,
    this.name = '',
    this.description = '',
    this.members = const [],
    this.permission = 0,
    this.externalId = '',
    this.isPublic = false,
    this.createdBy,
    DateTime? created,
    DateTime? updated,
  }) : created = created ?? DateTime.now(),
       updated = updated ?? DateTime.now();

  TeamDto.fromJson(Map<String, dynamic> json)
    : id = json['id'] ?? 0,
      name = json['name'] ?? '',
      description = json['description'] ?? '',
      members = (json['members'] is List)
          ? (json['members'] as List)
                .map<TeamMemberDto>((m) => TeamMemberDto.fromJson(m))
                .toList()
          : [],
      permission = json['permission'] ?? 0,
      externalId = json['external_id'] ?? '',
      isPublic = json['is_public'] ?? false,
      createdBy = json['created_by'] != null
          ? UserDto.fromJson(json['created_by'])
          : null,
      created = json['created'] != null
          ? DateTime.parse(json['created'])
          : DateTime.now(),
      updated = json['updated'] != null
          ? DateTime.parse(json['updated'])
          : DateTime.now();

  Map<String, dynamic> toJSON() => {
    'id': id,
    'name': name,
    'description': description,
    'members': members.map((e) => e.toJSON()).toList(),
    'permission': permission,
    'external_id': externalId,
    'is_public': isPublic,
    'created_by': createdBy?.toJSON(),
    'created': created.toUtc().toIso8601String(),
    'updated': updated.toUtc().toIso8601String(),
  };

  @override
  Team toDomain() => Team(
    id: id,
    name: name,
    description: description,
    members: members.map((e) => e.toDomain()).toList(),
    permission: permission,
    externalId: externalId,
    isPublic: isPublic,
    createdBy: createdBy?.toDomain(),
    created: created,
    updated: updated,
  );

  static TeamDto fromDomain(Team team) => TeamDto(
    id: team.id,
    name: team.name,
    description: team.description,
    members: team.members.map(TeamMemberDto.fromDomain).toList(),
    permission: team.permission,
    externalId: team.externalId,
    isPublic: team.isPublic,
    createdBy: team.createdBy != null
        ? UserDto.fromDomain(team.createdBy!)
        : null,
    created: team.created,
    updated: team.updated,
  );
}
