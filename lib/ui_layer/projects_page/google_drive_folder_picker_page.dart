import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleDriveService.dart';
import 'package:ice_gate/utils/l10n_extensions.dart';
import 'package:shimmer/shimmer.dart';

class GoogleDriveFolderPickerPage extends StatefulWidget {
  final Function(String folderId, String folderName) onFolderSelected;

  const GoogleDriveFolderPickerPage({
    super.key,
    required this.onFolderSelected,
  });

  @override
  State<GoogleDriveFolderPickerPage> createState() => _GoogleDriveFolderPickerPageState();
}

class _GoogleDriveFolderPickerPageState extends State<GoogleDriveFolderPickerPage> {
  final GoogleDriveService _driveService = GoogleDriveService();
  final List<DriveFile> _breadcrumbs = [];
  List<DriveFile>? _folders;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    setState(() => _isLoading = true);
    final success = await _driveService.signIn();
    if (success) {
      await _loadFolders();
    } else {
      setState(() {
        _isLoading = false;
        _error = "Sign-in failed. Please check your connection.";
      });
    }
  }

  Future<void> _loadFolders({String? parentId}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final folders = await _driveService.fetchFolders(parentId: parentId);
      setState(() {
        _folders = folders;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  void _navigateToFolder(DriveFile folder) {
    setState(() {
      _breadcrumbs.add(folder);
    });
    _loadFolders(parentId: folder.id);
  }

  void _navigateBack(int index) {
    if (index == -1) {
      // Root
      setState(() => _breadcrumbs.clear());
      _loadFolders();
    } else {
      final folder = _breadcrumbs[index];
      setState(() {
        _breadcrumbs.removeRange(index + 1, _breadcrumbs.length);
      });
      _loadFolders(parentId: folder.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          l10n.select_folder,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildBreadcrumbs(l10n),
          Expanded(
            child: _buildFolderList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBreadcrumbs(dynamic l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        border: Border.symmetric(
          horizontal: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildBreadcrumbItem(l10n.my_drive, -1),
            if (_breadcrumbs.isNotEmpty)
              ..._breadcrumbs.asMap().entries.map((entry) {
                return Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        l10n.breadcrumb_separator,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 10),
                      ),
                    ),
                    _buildBreadcrumbItem(entry.value.name, entry.key),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem(String label, int index) {
    final isLast = index == _breadcrumbs.length - 1;
    return GestureDetector(
      onTap: isLast ? null : () => _navigateBack(index),
      child: Text(
        label,
        style: TextStyle(
          color: isLast ? Colors.white : Colors.white.withValues(alpha: 0.5),
          fontWeight: isLast ? FontWeight.bold : FontWeight.normal,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildFolderList() {
    if (_isLoading) {
      return _buildShimmerGrid();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.redAccent.withValues(alpha: 0.5), size: 48),
            const SizedBox(height: 16),
            Text(_error!, style: TextStyle(color: Colors.white.withValues(alpha: 0.4))),
            TextButton(onPressed: _init, child: const Text("Retry")),
          ],
        ),
      );
    }

    if (_folders == null || _folders!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open_outlined, color: Colors.white.withValues(alpha: 0.1), size: 64),
            const SizedBox(height: 16),
            Text("No folders found", style: TextStyle(color: Colors.white.withValues(alpha: 0.2))),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _folders!.length,
      itemBuilder: (context, index) {
        final folder = _folders![index];
        return _buildFolderTile(folder);
      },
    );
  }

  Widget _buildFolderTile(DriveFile folder) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.folder, color: Colors.blueAccent, size: 20),
        ),
        title: Text(
          folder.name,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          "Modified: ${folder.modifiedTime != null ? folder.modifiedTime!.toLocal().toString().split('.')[0] : 'Unknown'}",
          style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle_outline, color: Colors.greenAccent),
              onPressed: () => widget.onFolderSelected(folder.id, folder.name),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
        onTap: () => _navigateToFolder(folder),
      ),
    );
  }

  Widget _buildShimmerGrid() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withValues(alpha: 0.05),
          highlightColor: Colors.white.withValues(alpha: 0.1),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}
