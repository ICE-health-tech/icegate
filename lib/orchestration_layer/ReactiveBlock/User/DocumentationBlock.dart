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
import '../../../data_layer/Services/cloud/GoogleDriveService.dart';

class DocumentationBlock {
  String get _googleClientId {
    if (Platform.isIOS || Platform.isMacOS) {
      return GoogleDriveService.googleDarwinClientId;
    }
    return GoogleDriveService.googleWebClientId;
  }

  // Cloud Service
  final driveService = GoogleDriveService();

  // Sync Engine State
  final syncHistory = signal<List<Map<String, dynamic>>>([]);
  final uptimeSeconds = signal<int>(0);
  final syncMethod = signal<String>('Mirror'); // Default: Mirror
  final refreshRate = signal<Duration>(const Duration(minutes: 5));
  final systemHealth = signal<double>(98.4);
  Timer? _uptimeTimer;

  final files = signal<List<File>>([]);
  final directories = signal<List<Directory>>([]);
  final isSyncing = signal<bool>(false);
  final syncStatus = signal<String?>(null);
  final activeDocumentTab = signal<int>(0); // Syncs with NoteManagerPage PageView

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
    _startUptimeCounter();
  }

  void _startUptimeCounter() {
    _uptimeTimer?.cancel();
    _uptimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      uptimeSeconds.value++;
    });
  }

  void logActivity(String title, {String? details, bool isError = false}) {
    final now = DateTime.now();
    final entry = {
      'title': title,
      'details': details,
      'timestamp': now,
      'isError': isError,
    };
    syncHistory.value = [entry, ...syncHistory.value];
    if (syncHistory.value.length > 50) {
      syncHistory.value = syncHistory.value.sublist(0, 50);
    }
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

  /// Deletes a file.
  Future<void> deleteFile(File file) async {
    try {
      if (await file.exists()) {
        syncStatus.value = "Deleting ${p.basename(file.path)}...";
        await file.delete();
        syncStatus.value = "✅ File deleted!";
        _loadFiles();
      }
    } catch (e) {
      print("Error deleting file: $e");
      syncStatus.value = "❌ Delete failed: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
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

  /// Moves a file to a new destination folder.
  Future<void> moveFile(File file, Directory destination) async {
    try {
      final newPath = p.join(destination.path, p.basename(file.path));
      if (file.path == newPath) return; // Same location

      syncStatus.value = "Moving ${p.basename(file.path)}...";
      await file.rename(newPath);
      syncStatus.value = "✅ Moved!";
      _loadFiles();
    } catch (e) {
      syncStatus.value = "❌ Move failed: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  /// Copies a file to a new destination folder.
  Future<void> copyFile(File file, Directory destination) async {
    try {
      final newPath = p.join(destination.path, p.basename(file.path));
      if (file.path == newPath) return; // Same location

      syncStatus.value = "Copying ${p.basename(file.path)}...";
      await file.copy(newPath);
      syncStatus.value = "✅ Copied!";
      _loadFiles();
    } catch (e) {
      syncStatus.value = "❌ Copy failed: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  /// Moves a folder to a new parent folder.
  Future<void> moveFolder(Directory source, Directory destinationParent) async {
    try {
      final newPath = p.join(destinationParent.path, p.basename(source.path));
      if (source.path == newPath) return;

      syncStatus.value = "Moving folder ${p.basename(source.path)}...";
      await source.rename(newPath);
      syncStatus.value = "✅ Folder moved!";
      _loadFiles();
    } catch (e) {
      syncStatus.value = "❌ Move failed: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  /// Copies a folder (recursively) to a new destination.
  Future<void> copyFolder(Directory source, Directory destinationParent) async {
    try {
      final newPath = p.join(destinationParent.path, p.basename(source.path));
      if (source.path == newPath) return;

      syncStatus.value = "Copying folder ${p.basename(source.path)}...";
      await _copyDirRecursive(source, Directory(newPath));
      syncStatus.value = "✅ Folder copied!";
      _loadFiles();
    } catch (e) {
      syncStatus.value = "❌ Copy failed: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  Future<void> _copyDirRecursive(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      if (entity is Directory) {
        final newDir = Directory(p.join(destination.path, p.basename(entity.path)));
        await _copyDirRecursive(entity, newDir);
      } else if (entity is File) {
        await entity.copy(p.join(destination.path, p.basename(entity.path)));
      }
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
      // 1. Pre-create 'Notion' local folder at root
      final notionRoot = Directory(p.join(_docDir!.path, 'Notion'));
      if (!await notionRoot.exists()) {
        await notionRoot.create(recursive: true);
      }
      
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

        if (objectType == 'database') {
          totalIngested += await _ingestPagesFromDatabase(item);
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
      _loadFiles(); // Refresh UI to show the new 'Notion' folder and files
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
    }
  }

  Future<int> _ingestPagesFromDatabase(Map dbData) async {
    final String databaseId = dbData['id'];
    String dbTitle = "Untitled Database";
    
    // Extract database title
    if (dbData['title'] != null && (dbData['title'] as List).isNotEmpty) {
      final List titleList = dbData['title'];
      dbTitle = titleList[0]['plain_text'] ?? "Untitled Database";
    }

    final folderName = dbTitle.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');

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
          await _ingestSinglePage(page, subFolder: folderName);
          count++;
        }
      }
    } catch (e) {
      print("Error querying database $databaseId: $e");
    }
    return count;
  }

  Future<void> _ingestSinglePage(Map pageData, {String? subFolder}) async {
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
    
    // Determine target directory
    String parentPath = p.join(_docDir!.path, 'Notion');
    if (subFolder != null) {
      parentPath = p.join(parentPath, subFolder);
      final dir = Directory(parentPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
    }

    // Save into the 'Notion' vault folder (or subfolder)
    final targetPath = p.join(parentPath, '$fileName.md');
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

    // Load Folders (Children of current directory)
    final allDirs = allEntities.whereType<Directory>().where((dir) {
      final name = p.basename(dir.path);
      if (_shouldIgnore(name)) return false;
      
      final parentPath = selectedDirectory.value?.path ?? _docDir!.path;
      // Only show immediate children of the parent path
      return p.equals(dir.parent.path, parentPath);
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
    logActivity("Sync Start", details: "Two-way mirroring initiated");

    try {
      final success = await driveService.signIn();
      if (!success) {
        logActivity("Auth Failed", details: "Google Drive sign-in unsuccessful", isError: true);
        syncStatus.value = "❌ Sign-in failed";
        return;
      }

      final driveApi = driveService.driveApi!;

      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id ?? "unknown_user";
      final folderNameToUse = obsidianFolderName.value?.isNotEmpty == true 
          ? obsidianFolderName.value! 
          : userId;

      // 1. Get/Create Distribution Folder (Robust Search)
      syncStatus.value = "Locating Cloud Vault...";
      logActivity("Vault Access", details: "Finding '$folderNameToUse'");
      String? rootFolderId;
      
      final folderQuery = "name = '$folderNameToUse' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final folderList = await driveApi.files.list(
        q: folderQuery,
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
      await _syncRecursive(rootFolderId, _docDir!.path);

      logActivity("Sync Complete", details: "Two-way mirroring finished successfully");
      systemHealth.value = 100.0;
      syncStatus.value = "✅ Full Recursive Sync Complete!";
    } catch (e) {
      logActivity("Sync Error", details: e.toString(), isError: true);
      systemHealth.value = 78.5; // Significant drop on full sync error
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
    try {
      final parentPath = selectedDirectory.value?.path ?? _docDir!.path;
      final dirPath = p.join(parentPath, name);
      final dir = Directory(dirPath);
      
      if (!await dir.exists()) {
        syncStatus.value = "Creating folder '$name'...";
        await dir.create(recursive: true);
        syncStatus.value = "✅ Folder created!";
        _loadFiles(); // Instant UI update
      } else {
        syncStatus.value = "⚠️ Folder '$name' already exists.";
      }
    } catch (e) {
      print("Error creating folder: $e");
      syncStatus.value = "❌ Error creating folder: $e";
    } finally {
      Future.delayed(const Duration(seconds: 3), () => syncStatus.value = null);
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
      await _downloadRecursive(rootFolderId, targetPath);

      logActivity("Fetch Success", details: "Downloaded folder '$targetRemoteName'");
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
  Future<void> _downloadRecursive(String remoteId, String localPath) async {
    final driveApi = driveService.driveApi; 
    if (driveApi == null) return;

    final dir = Directory(localPath);
    if (!await dir.exists()) await dir.create(recursive: true);

    final remoteFiles = await driveApi.files.list(
      q: "'$remoteId' in parents and trashed = false",
      $fields: "files(id, name, modifiedTime, size, mimeType)",
    );

    for (var file in remoteFiles.files ?? []) {
      if (_shouldIgnore(file.name!)) continue;

      final localFilePath = p.join(localPath, file.name!);

      if (file.mimeType == 'application/vnd.google-apps.folder') {
        await _downloadRecursive(file.id!, localFilePath);
      } else {
        final localFile = File(localFilePath);
        bool shouldDownload = true;
        
        if (await localFile.exists()) {
          final localMtime = (await localFile.lastModified()).toUtc();
          final remoteMtime = file.modifiedTime?.toUtc();
          if (remoteMtime != null && localMtime.isAfter(remoteMtime)) {
            shouldDownload = false;
          }
        }

        if (shouldDownload) {
          logActivity("Downloading", details: file.name);
          syncStatus.value = "Downloading ${file.name}...";
          final media = await driveApi.files.get(file.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
          final bytes = <int>[];
          await for (var chunk in media.stream) {
            bytes.addAll(chunk);
          }
          await localFile.writeAsBytes(bytes);
        }
      }
    }
  }
  /// Core Recursive Sync Engine (Two-Way)
  Future<void> _syncRecursive(String remoteParentId, String localDirPath) async {
    final driveApi = driveService.driveApi;
    if (driveApi == null) return;
    final localDir = Directory(localDirPath);
    if (!await localDir.exists()) await localDir.create(recursive: true);

    // 1. Fetch Remote Items in this Folder
    syncStatus.value = "Scanning Cloud: ${p.basename(localDirPath)}...";
    final remoteFilesList = await driveApi.files.list(
      q: "'$remoteParentId' in parents and trashed = false",
      $fields: "files(id, name, modifiedTime, size, mimeType)",
      supportsAllDrives: true,
      includeItemsFromAllDrives: true,
    );
    final List<drive.File> remoteItems = remoteFilesList.files ?? [];

    // 2. Local Inventory
    final localItems = localDir.listSync();

    // --- Part A: Sync Remote items to Local ---
    for (var remoteItem in remoteItems) {
      final name = remoteItem.name!;
      if (_shouldIgnore(name)) continue;

      final localPath = p.join(localDirPath, name);
      
      if (remoteItem.mimeType == 'application/vnd.google-apps.folder') {
        // Enforce local folder existence and recurse
        final subDir = Directory(localPath);
        if (!await subDir.exists()) await subDir.create(recursive: true);
        await _syncRecursive(remoteItem.id!, localPath);
      } else {
        // It's a file - Robust Sync
        final localFile = File(localPath);
        bool shouldDownload = false;
        
        if (!await localFile.exists()) {
          shouldDownload = true;
        } else if (remoteItem.modifiedTime != null) {
          final localModified = (await localFile.lastModified()).toUtc();
          final remoteModified = remoteItem.modifiedTime!.toUtc();
          
          // Download only if remote is significantly newer (2s buffer for FAT/SMB/Clock skew)
          if (remoteModified.isAfter(localModified.add(const Duration(seconds: 2)))) {
            shouldDownload = true;
          }
        }

        if (shouldDownload) {
          try {
            syncStatus.value = "Downloading $name...";
            final media = await driveApi.files.get(remoteItem.id!, downloadOptions: drive.DownloadOptions.fullMedia) as drive.Media;
            final fileSink = localFile.openWrite();
            await fileSink.addStream(media.stream);
            await fileSink.close();
            
            // Re-stamp local file to match remote modified time to prevent immediate re-upload
            if (remoteItem.modifiedTime != null) {
              await localFile.setLastModified(remoteItem.modifiedTime!.toLocal());
            }
          } catch (e) {
            print("Failed to download $name: $e");
          }
        }
      }
    }

    // --- Part B: Sync Local items to Remote ---
    for (var entity in localItems) {
      final name = p.basename(entity.path);
      if (_shouldIgnore(name)) continue;

      // Check if this local item exists on remote
      final matchedRemote = remoteItems.firstWhere((f) => f.name == name, orElse: () => drive.File());

      if (entity is Directory) {
        // If directory doesn't exist on remote at all, create it and recurse
        if (matchedRemote.id == null) {
          try {
            syncStatus.value = "Creating Cloud Folder $name...";
            final newFolder = drive.File()
              ..name = name
              ..mimeType = 'application/vnd.google-apps.folder'
              ..parents = [remoteParentId];
            final created = await driveApi.files.create(newFolder);
            await _syncRecursive(created.id!, entity.path);
          } catch (e) {
            print("Failed to create remote folder $name: $e");
          }
        }
        // Subfolders that already exist on remote were already recursed in Part A
      } else if (entity is File) {
        final localModified = (await entity.lastModified()).toUtc();
        bool shouldUpload = false;

        if (matchedRemote.id == null) {
          shouldUpload = true;
        } else if (matchedRemote.modifiedTime != null) {
          final remoteModified = matchedRemote.modifiedTime!.toUtc();
          // Upload only if local is significantly newer
          if (localModified.isAfter(remoteModified.add(const Duration(seconds: 2)))) {
            shouldUpload = true;
          }
        }

        if (shouldUpload) {
          try {
            syncStatus.value = "Uploading $name...";
            final media = drive.Media(entity.openRead(), await entity.length());
            
            final driveFile = drive.File()
              ..name = name
              ..modifiedTime = localModified;

            if (matchedRemote.id != null) {
              await driveApi.files.update(driveFile, matchedRemote.id!, uploadMedia: media);
            } else {
              driveFile.parents = [remoteParentId];
              await driveApi.files.create(driveFile, uploadMedia: media);
            }
          } catch (e) {
            print("Failed to upload $name: $e");
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
