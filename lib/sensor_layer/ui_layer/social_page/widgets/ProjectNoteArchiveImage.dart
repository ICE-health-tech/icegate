import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';

/// Resolves journal / archive image paths for [project_notes].
class ProjectNoteArchiveImage extends StatelessWidget {
  const ProjectNoteArchiveImage({
    super.key,
    required this.note,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.width,
    this.height,
  });

  final ProjectNoteData note;
  final BoxFit fit;
  final Widget? placeholder;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final local = ProjectNoteArchiveUtils.imagePath(note);
    if (local == null || local.isEmpty) {
      return placeholder ??
          ColoredBox(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(child: Icon(Icons.image_not_supported_outlined)),
          );
    }

    final remote = ProjectNoteArchiveUtils.imageRemotePath(note) ?? '';
    return LocalFirstImage(
      localPath: local,
      remoteUrl: remote,
      fit: fit,
      width: width,
      height: height,
      ownerId: note.personID,
      subFolder: ProjectNoteArchiveUtils.imageSubFolder(local),
      placeholder: placeholder,
    );
  }
}
