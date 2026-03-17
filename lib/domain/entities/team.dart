import 'package:vikunja_app/domain/entities/team_member.dart';
import 'package:vikunja_app/domain/entities/user.dart';

class Team {
  int id;
  String name;
  String description;
  List<TeamMember> members;
  int permission;
  String externalId;
  bool isPublic;
  User? createdBy;
  DateTime created;
  DateTime updated;

  Team({
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

  Team copyWith({
    int? id,
    String? name,
    String? description,
    List<TeamMember>? members,
    int? permission,
    String? externalId,
    bool? isPublic,
    User? createdBy,
    DateTime? created,
    DateTime? updated,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      members: members ?? this.members,
      permission: permission ?? this.permission,
      externalId: externalId ?? this.externalId,
      isPublic: isPublic ?? this.isPublic,
      createdBy: createdBy ?? this.createdBy,
      created: created ?? this.created,
      updated: updated ?? this.updated,
    );
  }
}
