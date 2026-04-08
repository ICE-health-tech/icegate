import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:watcher/watcher.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;

class DocumentationBlock {
  // Web Client ID (needed for Web)
  static const String googleWebClientId =
      '1076295055088-s88o9d59unnd0p68be5pmsiv6h2a0rgo.apps.googleusercontent.com';
  // iOS/macOS Client ID (from Info.plist)
  static const String googleDarwinClientId =
      '807274985161-2tgda6mbjop0k2vnf85q5plac7t6d1aq.apps.googleusercontent.com';

  String get _googleClientId {
    if (Platform.isIOS || Platform.isMacOS) {
      return googleDarwinClientId;
    }
    return googleWebClientId;
  }

  final files = signal<List<File>>([]);
  final directories = signal<List<Directory>>([]);
  final isSyncing = signal<bool>(false);
  final syncStatus = signal<String?>(null);
  final activeDocumentTab = signal<int>(0); // Syncs with DocumentManagerPage PageView

  final notionSecret = signal<String?>(null); // Notion Phase 4
  final obsidianFolderName = signal<String?>(null); // Custom Obsidian Folder Name
  
  // Editor State
  final activeEditingFile = signal<File?>(null);
  final selectedDirectory = signal<Directory?>(null);

  StreamSubscription<WatchEvent>? _watcherSubscription;
  Directory? _docDir;

  DocumentationBlock() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    notionSecret.value = prefs.getString('notion_secret');
    obsidianFolderName.value = prefs.getString('obsidian_folder_name');

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final appDir = await getApplicationDocumentsDirectory();
    _docDir = Directory(
      '${appDir.path}/${user.id}/user_markdown_documentation',
    );

    if (!await _docDir!.exists()) {
      await _docDir!.create(recursive: true);
    }

    _loadFiles();
    _startWatching();
  }

  Future<void> setNotionSecret(String? secret) async {
    final prefs = await SharedPreferences.getInstance();
    if (secret == null || secret.isEmpty) {
      await prefs.remove('notion_secret');
      notionSecret.value = null;
    } else {
      await prefs.setString('notion_secret', secret);
      notionSecret.value = secret;
    }
  }

  Future<void> setObsidianFolderName(String? name) async {
    final prefs = await SharedPreferences.getInstance();
    if (name == null || name.isEmpty) {
      await prefs.remove('obsidian_folder_name');
      obsidianFolderName.value = null;
    } else {
      await prefs.setString('obsidian_folder_name', name);
      obsidianFolderName.value = name;
    }
  }

  /// Import files from local device storage (Phase 1)
  Future<void> importFromDevice() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: ['md', 'txt', 'json', 'pdf', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        syncStatus.value = "Importing ${result.files.length} files...";
        for (var pickedFile in result.files) {
          if (pickedFile.path != null) {
            final file = File(pickedFile.path!);
            final fileName = pickedFile.name;
            final destination = File('${_docDir!.path}/$fileName');

            // Safeguard: Don't copy if source and destination are the same
            if (file.path != destination.path) {
              await file.copy(destination.path);
            }
          }
        }
        syncStatus.value = "✅ Import complete!";
        _loadFiles();
      }
    } catch (e) {
      syncStatus.value = "❌ Import failed: $e";
    }
  }

  /// Deletes a folder and all its contents recursively.
  Future<void> deleteFolder(Directory directory) async {
    try {
      if (await directory.exists()) {
        syncStatus.value = "Deleting folder ${p.basename(directory.path)}...";
        await directory.delete(recursive: true);
        syncStatus.value = "✅ Folder deleted!";
        
        // If the deleted directory was the selected one, go back to root
        if (selectedDirectory.value?.path == directory.path) {
          selectedDirectory.value = null;
        }
        
        _loadFiles();
      }
    } catch (e) {
      print("Error deleting folder: $e");
      syncStatus.value = "❌ Delete failed: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  /// Ingests all shared Notion databases and pages automatically (Phase 4)
  Future<void> fetchFromNotionAuto() async {
    if (notionSecret.value == null) {
      syncStatus.value = "⚠️ Please configure Notion Secret first.";
      return;
    }

    isSyncing.value = true;
    syncStatus.value = "Searching Notion for shared content...";

    try {
      // 1. Pre-create 'Notion' local folder
      await createLocalFolder('Notion');
      await _cleanupNotionFiles(); // Move legacy files to the new vault
      
      // 2. Search for everything shared with this integration
      final searchResponse = await http.post(
        Uri.parse('https://api.notion.com/v1/search'),
        headers: {
          'Authorization': 'Bearer ${notionSecret.value}',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "sort": {"direction": "descending", "timestamp": "last_edited_time"},
        }),
      );

      if (searchResponse.statusCode != 200) {
        throw Exception(
          "Search Failed: ${searchResponse.statusCode} - ${searchResponse.body}",
        );
      }

      final searchData = jsonDecode(searchResponse.body);
      final List results = searchData['results'];
      int totalIngested = 0;

      for (var item in results) {
        final String objectType = item['object'];
        final String id = item['id'];

        if (objectType == 'database') {
          totalIngested += await _ingestPagesFromDatabase(id);
        } else if (objectType == 'page') {
          await _ingestSinglePage(item);
          totalIngested++;
        }
      }

      syncStatus.value =
          "✅ Pipeline Ingested $totalIngested items from Notion!";
    } catch (e) {
      print('❌ Notion Auto-Ingestion failed: $e');
      syncStatus.value = "❌ Ingestion failed: $e";
    } finally {
      isSyncing.value = false;
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  Future<int> _ingestPagesFromDatabase(String databaseId) async {
    int count = 0;
    try {
      final response = await http.post(
        Uri.parse('https://api.notion.com/v1/databases/$databaseId/query'),
        headers: {
          'Authorization': 'Bearer ${notionSecret.value}',
          'Notion-Version': '2022-06-28',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List pages = data['results'];
        for (var page in pages) {
          await _ingestSinglePage(page);
          count++;
        }
      }
    } catch (e) {
      print("Error querying database $databaseId: $e");
    }
    return count;
  }

  Future<void> _ingestSinglePage(Map pageData) async {
    final String pageId = pageData['id'];
    final properties = pageData['properties'];

    String title = "Untitled Notion Page";
    if (properties != null) {
      properties.forEach((key, val) {
        if (val['type'] == 'title' && val['title'] != null) {
          final List titleList = val['title'];
          if (titleList.isNotEmpty) {
            title = titleList[0]['plain_text'];
          }
        }
      });
    }

    final markdownContent = await _fetchPageContentAsMarkdown(pageId, title);
    final fileName = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    
    // Save into the 'Notion' vault folder
    final targetPath = p.join(_docDir!.path, 'Notion', '$fileName.md');
    final file = File(targetPath);
    await file.writeAsString(markdownContent);
  }

  Future<String> _fetchPageContentAsMarkdown(
    String blockId,
    String title,
  ) async {
    final buffer = StringBuffer();
    buffer.writeln("# $title");
    // buffer.writeln();
    // buffer.writeln("> *Ingested from Notion Pipeline*");
    buffer.writeln();

    try {
      final response = await http.get(
        Uri.parse('https://api.notion.com/v1/blocks/$blockId/children'),
        headers: {
          'Authorization': 'Bearer ${notionSecret.value}',
          'Notion-Version': '2022-06-28',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List blocks = data['results'];

        for (var block in blocks) {
          final String type = block['type'];
          final Map? content = block[type];
          if (content == null) continue;

          switch (type) {
            case 'paragraph':
              buffer.writeln(_parseRichText(content['rich_text']));
              buffer.writeln();
              break;
            case 'heading_1':
              buffer.writeln("# ${_parseRichText(content['rich_text'])}");
              buffer.writeln();
              break;
            case 'heading_2':
              buffer.writeln("## ${_parseRichText(content['rich_text'])}");
              buffer.writeln();
              break;
            case 'heading_3':
              buffer.writeln("### ${_parseRichText(content['rich_text'])}");
              buffer.writeln();
              break;
            case 'bulleted_list_item':
              buffer.writeln("- ${_parseRichText(content['rich_text'])}");
              break;
            case 'numbered_list_item':
              buffer.writeln("1. ${_parseRichText(content['rich_text'])}");
              break;
            case 'to_do':
              final bool checked = content['checked'] ?? false;
              buffer.writeln(
                "${checked ? '[x]' : '[ ]'} ${_parseRichText(content['rich_text'])}",
              );
              break;
            case 'code':
              buffer.writeln("```${content['language'] ?? ''}");
              buffer.writeln(_parseRichText(content['rich_text']));
              buffer.writeln("```");
              buffer.writeln();
              break;
            case 'quote':
              buffer.writeln("> ${_parseRichText(content['rich_text'])}");
              buffer.writeln();
              break;
            case 'divider':
              buffer.writeln("---");
              buffer.writeln();
              break;
          }
        }
      }
    } catch (e) {
      buffer.writeln("\n\n> ⚠️ Error fetching children blocks: $e");
    }

    return buffer.toString();
  }

  String _parseRichText(dynamic richTextList) {
    if (richTextList == null || richTextList is! List) return "";
    final buffer = StringBuffer();
    for (var text in richTextList) {
      String plain = text['plain_text'] ?? "";
      final annotations = text['annotations'];
      if (annotations != null) {
        if (annotations['bold'] == true) plain = "**$plain**";
        if (annotations['italic'] == true) plain = "_${plain}_";
        if (annotations['strikethrough'] == true) plain = "~~$plain~~";
        if (annotations['code'] == true) plain = "`$plain`";
      }
      buffer.write(plain);
    }
    return buffer.toString();
  }

  void _loadFiles() {
    if (_docDir == null) return;

    final allEntities = _docDir!.listSync(recursive: true);
    
    // Load Files
    final allFiles = allEntities.whereType<File>().where((file) {
      final pathStr = file.path.toLowerCase();
      // Skip hidden/system files in subfolders
      if (pathStr.contains('/.') || pathStr.contains('\\.')) return false;
      
      return pathStr.endsWith('.md') ||
          pathStr.endsWith('.txt') ||
          pathStr.endsWith('.json') ||
          pathStr.endsWith('.log') ||
          pathStr.endsWith('.sql') ||
          pathStr.endsWith('.pdf') ||
          pathStr.endsWith('.docx') ||
          pathStr.endsWith('.doc');
    }).toList();

    allFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    
    // Filter by selected directory and avoid duplicates
    final filteredFiles = allFiles.where((file) {
      if (selectedDirectory.value == null) return true;
      // Ensure file is inside the selected directory (or its subfolders)
      return p.isWithin(selectedDirectory.value!.path, file.path);
    }).toList();
    
    files.value = filteredFiles;

    // Load Folders (Top-level or with content)
    final allDirs = allEntities.whereType<Directory>().where((dir) {
      final name = p.basename(dir.path);
      return !_shouldIgnore(name);
    }).toList();
    
    directories.value = allDirs;
  }

  void _startWatching() {
    _watcherSubscription?.cancel();
    if (_docDir == null) return;

    final watcher = DirectoryWatcher(_docDir!.path);
    _watcherSubscription = watcher.events.listen((event) {
      _loadFiles();
    });
  }

  /// Two-Way Recursive Sync Logic
  Future<void> syncWithGoogleDrive() async {
    isSyncing.value = true;
    syncStatus.value = "Initiating Recursive Sync...";

    try {
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId,
        scopes: [drive.DriveApi.driveFileScope],
      );

      GoogleSignInAccount? account = await googleSignIn.signInSilently();
      account ??= await googleSignIn.signIn();

      if (account == null) {
        syncStatus.value = "Sync cancelled";
        isSyncing.value = false;
        return;
      }

      final authHeaders = await account.authHeaders;
      final authenticateClient = _GoogleAuthClient(authHeaders);
      final driveApi = drive.DriveApi(authenticateClient);

      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? "unknown_user";
      final folderNameToUse = obsidianFolderName.value?.isNotEmpty == true 
          ? obsidianFolderName.value! 
          : userId;

      // 1. Get/Create Distribution Folder (Robust Search)
      syncStatus.value = "Locating Cloud Vault...";
      String? rootFolderId;
      
      final folderQuery = "name = '$folderNameToUse' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final folderList = await driveApi.files.list(
        q: folderQuery,
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      );

      if (folderList.files != null && folderList.files!.isNotEmpty) {
        rootFolderId = folderList.files!.first.id;
      } else {
        final newFolder = drive.File()
          ..name = folderNameToUse
          ..mimeType = 'application/vnd.google-apps.folder';
        final createdFolder = await driveApi.files.create(newFolder);
        rootFolderId = createdFolder.id;
      }

      if (rootFolderId == null) throw Exception("Could not resolve Google Drive folder.");

      // 2. Start Recursive Sync
      await _syncRecursive(driveApi, rootFolderId, _docDir!.path);

      syncStatus.value = "✅ Full Recursive Sync Complete!";
    } catch (e) {
      print('❌ Google Drive Sync Error: $e');
      syncStatus.value = "❌ Sync failed: $e";
    } finally {
      isSyncing.value = false;
      _loadFiles();
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  /// Helper to filter out system folders (Obsidian/Git)
  bool _shouldIgnore(String name) {
    final n = name.toLowerCase();
    return n.startsWith('.') || 
           n == 'node_modules' || 
           n == '.obsidian' || 
           n == '.git' || 
           n == '.trash';
  }

  /// Create a Local Folder and refresh UI
  Future<void> createLocalFolder(String name) async {
    if (_docDir == null) return;
    final dirPath = p.join(_docDir!.path, name);
    final dir = Directory(dirPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      _loadFiles(); // Instant UI update
    }
  }

  /// Retroactive cleanup: move any root Notion files into the Notion vault
  Future<void> _cleanupNotionFiles() async {
    if (_docDir == null) return;
    final notionDirPath = p.join(_docDir!.path, 'Notion');
    final notionDir = Directory(notionDirPath);
    
    // We assume 'Notion' folder was already created by createLocalFolder
    if (!await notionDir.exists()) return;

    final files = _docDir!.listSync();
    for (var f in files) {
      if (f is File) {
        final name = p.basename(f.path);
        // Heuristic: items that have 'Notion' in name or were untitled Notion items
        if (name.endsWith('.md') && 
            (name.contains('Notion') || name == 'Untitled_Notion_Page.md')) {
          final targetPath = p.join(notionDirPath, name);
          // Only move if target doesn't already exist to avoid conflicts
          if (!await File(targetPath).exists()) {
            await f.rename(targetPath);
          }
        }
      }
    }
    _loadFiles();
  }

  /// Explicit Folder Fetch (One-Way Pull from Drive)
  Future<void> fetchFolderFromDrive({String? remoteName, String? localName}) async {
    isSyncing.value = true;
    final targetRemoteName = remoteName ?? obsidianFolderName.value;
    final targetLocalName = localName ?? targetRemoteName;
    
    if (targetRemoteName == null || targetRemoteName.isEmpty) {
      syncStatus.value = "❌ No folder name specified";
      isSyncing.value = false;
      return;
    }

    syncStatus.value = "Fetching '$targetRemoteName'...";

    try {
      // 1. Pre-create local folder immediately so it appears in UI
      await createLocalFolder(targetLocalName!);
      
      final googleSignIn = GoogleSignIn(
        clientId: _googleClientId,
        scopes: [drive.DriveApi.driveFileScope],
      );

      GoogleSignInAccount? account = await googleSignIn.signInSilently();
      account ??= await googleSignIn.signIn();

      if (account == null) {
        syncStatus.value = "Cancelled";
        isSyncing.value = false;
        return;
      }

      final authHeaders = await account.authHeaders;
      final driveApi = drive.DriveApi(_GoogleAuthClient(authHeaders));

      // 1. Locate Folder
      final folderList = await driveApi.files.list(
        q: "name = '$targetRemoteName' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
        $fields: "files(id, name)",
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      );

      if (folderList.files == null || folderList.files!.isEmpty) {
        syncStatus.value = "❌ Folder not found in Drive";
        return;
      }

      final rootFolderId = folderList.files!.first.id!;

      // 2. Start Recursive Download in a dedicated sub-folder
      final targetPath = p.join(_docDir!.path, targetLocalName);
      await _downloadRecursive(driveApi, rootFolderId, targetPath);

      syncStatus.value = "✅ Folder Fetch Complete!";
    } catch (e) {
      print('❌ Fetch Error: $e');
      syncStatus.value = "❌ Fetch failed: $e";
    } finally {
      isSyncing.value = false;
      _loadFiles();
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  /// Helper for one-way recursive download
  Future<void> _downloadRecursive(drive.DriveApi driveApi, String remoteId, String localPath) async {
    final dir = Directory(localPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final remoteFiles = await driveApi.files.list(
      q: "'$remoteId' in parents and trashed = false",
      $fields: "files(id, name, modifiedTime, size, mimeType)",
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    );

    for (var file in remoteFiles.files ?? []) {
      if (_shouldIgnore(file.name!)) continue;

      final localFilePath = p.join(localPath, file.name!);

      if (file.mimeType == 'application/vnd.google-apps.folder') {
        // Recursive directory
        await _downloadRecursive(driveApi, file.id!, localFilePath);
      } else {
        // Simple file download
        final localFile = File(localFilePath);
        
        // Only download if missing or remote is newer
        bool shouldDownload = true;
        if (await localFile.exists()) {
          final localMtime = (await localFile.lastModified()).toUtc();
          final remoteMtime = file.modifiedTime?.toUtc();
          if (remoteMtime != null && localMtime.isAfter(remoteMtime)) {
            shouldDownload = false;
          }
        }

        if (shouldDownload) {
          syncStatus.value = "Downloading ${file.name}...";
          final media = await driveApi.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
          final bytes = <int>[];
          await for (var chunk in media.stream) {
            bytes.addAll(chunk);
          }
          await localFile.writeAsBytes(bytes);
          // Set modification time to match remote if possible (optional)
        }
      }
    }
  }
  /// Core Recursive Sync Engine (Two-Way)
  Future<void> _syncRecursive(drive.DriveApi driveApi, String remoteParentId, String localDirPath) async {
    final localDir = Directory(localDirPath);
    if (!await localDir.exists()) await localDir.create(recursive: true);

    // 1. Fetch Remote Files in this Folder
    final remoteFilesList = await driveApi.files.list(
      q: "'$remoteParentId' in parents and trashed = false",
      $fields: "files(id, name, modifiedTime, size, mimeType)",
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    );
    final List<drive.File> remoteItems = remoteFilesList.files ?? [];

    // 2. Local Inventory
    final localItems = localDir.listSync();

    // --- Part A: Remote to Local (Downloads & Step Into Folders) ---
    for (var remoteItem in remoteItems) {
      final name = remoteItem.name!;
      if (_shouldIgnore(name)) continue;

      final localPath = "$localDirPath/$name";
      
      if (remoteItem.mimeType == 'application/vnd.google-apps.folder') {
        // Recurse into subfolder
        await _syncRecursive(driveApi, remoteItem.id!, localPath);
      } else {
        // It's a file - Sync it
        final localFile = File(localPath);
        bool shouldDownload = false;
        
        if (!await localFile.exists()) {
          shouldDownload = true;
        } else if (remoteItem.modifiedTime != null) {
          final localModified = await localFile.lastModified();
          if (remoteItem.modifiedTime!.isAfter(localModified.add(const Duration(seconds: 2)))) {
            shouldDownload = true;
          }
        }

        if (shouldDownload) {
          syncStatus.value = "Downloading $name...";
          final media = await driveApi.files.get(remoteItem.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
          final sink = localFile.openWrite();
          await sink.addStream(media.stream);
          await sink.close();
          if (remoteItem.modifiedTime != null) await localFile.setLastModified(remoteItem.modifiedTime!);
        }
      }
    }

    // --- Part B: Local to Remote (Uploads & Create Subfolders) ---
    for (var entity in localItems) {
      final name = p.basename(entity.path);
      if (_shouldIgnore(name)) continue;

      // Find if it exists on remote
      final matchedRemote = remoteItems.firstWhere((f) => f.name == name, orElse: () => drive.File());

      if (entity is Directory) {
        // If directory doesn't exist on remote, create it
        if (matchedRemote.id == null) {
          syncStatus.value = "Creating Cloud Folder $name...";
          final newFolder = drive.File()
            ..name = name
            ..mimeType = 'application/vnd.google-apps.folder'
            ..parents = [remoteParentId];
          final created = await driveApi.files.create(newFolder);
          // Recursively sync its contents
          await _syncRecursive(driveApi, created.id!, entity.path);
        }
        // Note: recursion for existing folders is already handled in Part A
      } else if (entity is File) {
        final localModified = await entity.lastModified();
        bool shouldUpload = false;

        if (matchedRemote.id == null) {
          shouldUpload = true;
        } else if (matchedRemote.modifiedTime != null) {
          if (localModified.isAfter(matchedRemote.modifiedTime!.add(const Duration(seconds: 2)))) {
            shouldUpload = true;
          }
        }

        if (shouldUpload) {
          syncStatus.value = "Uploading $name...";
          final media = drive.Media(entity.openRead(), await entity.length());
          
          if (matchedRemote.id != null) {
            final driveFile = drive.File()..name = name..modifiedTime = localModified.toUtc();
            await driveApi.files.update(driveFile, matchedRemote.id!, uploadMedia: media);
          } else {
            final driveFile = drive.File()..name = name..parents = [remoteParentId]..modifiedTime = localModified.toUtc();
            await driveApi.files.create(driveFile, uploadMedia: media);
          }
        }
      }
    }
  }

  void dispose() {
    _watcherSubscription?.cancel();
  }
}

/// Helper client to inject Google Auth headers into every request
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
