class ProjectProtocol {
  final String id;
  final int projectID;
  final int personID;
  final String name;
  final String? description;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int status;

  ProjectProtocol({
    required this.id,
    required this.projectID,
    required this.personID,
    required this.name,
    this.description,
    this.color,
    required this.createdAt,
    required this.updatedAt,
    this.status = 0,
  });
}
