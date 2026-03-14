class ProjectProtocol {
  final String id;
  final String projectID;
  final String personID;
  final String name;
  final String? description;
  final String? color;
  final String? sshHostId;
  final String? remotePath;
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
    this.sshHostId,
    this.remotePath,
    required this.createdAt,
    required this.updatedAt,
    this.status = 0,
  });
}
