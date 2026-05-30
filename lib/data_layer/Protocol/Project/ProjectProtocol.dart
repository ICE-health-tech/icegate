class ProjectProtocol {
  final String id;
  final String projectID;
  final String personID;
  final String name;
  final String? description;
  final String? color;
  final String? sshHostId;
  final String? remotePath;
  final String? aiModel;
  final String? parentProjectId;
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
    this.aiModel,
    this.parentProjectId,
    required this.createdAt,
    required this.updatedAt,
    this.status = 0,
  });

  bool get isRoot =>
      parentProjectId == null || parentProjectId!.trim().isEmpty;
}

extension ProjectProtocolListX on Iterable<ProjectProtocol> {
  List<ProjectProtocol> get rootsOnly =>
      where((p) => p.isRoot).toList(growable: false);

  List<ProjectProtocol> childrenOf(String parentId) => where(
        (p) => p.parentProjectId == parentId,
      ).toList(growable: false);
}
