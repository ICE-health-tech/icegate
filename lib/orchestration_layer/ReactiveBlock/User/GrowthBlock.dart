import 'dart:async';
import 'package:rxdart/rxdart.dart';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';
import 'package:ice_gate/data_layer/Protocol/Project/SdlcPhase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GrowthBlock {
  final goals = signal<List<GoalProtocol>>([]);
  final habits = signal<List<HabitProtocol>>([]);
  final skills = signal<List<SkillProtocol>>([]);

  StreamSubscription? _goalsSubscription;
  StreamSubscription? _habitsSubscription;
  StreamSubscription? _skillsSubscription;

  late GrowthDAO _dao;
  late String _personId;
  bool _alive = false;
  int _initGeneration = 0;

  void updateGoals(List<GoalProtocol> data) => goals.value = data;
  void updateHabits(List<HabitProtocol> data) => habits.value = data;
  void updateSkills(List<SkillProtocol> data) => skills.value = data;

  void init(GrowthDAO dao, String personId) {
    _dao = dao;
    _personId = personId;
    _goalsSubscription?.cancel();
    _habitsSubscription?.cancel();
    _skillsSubscription?.cancel();

    if (personId.isEmpty) {
      _alive = false;
      debugPrint("GrowthBlock: Skipping init, personId is empty.");
      return;
    }

    _alive = true;
    final generation = ++_initGeneration;

    _goalsSubscription = dao
        .watchGoals(personId)
        .debounceTime(const Duration(milliseconds: 300))
        .listen((data) {
      if (!_alive || generation != _initGeneration) return;
      untracked(() {
        updateGoals(
          data
              .map(
                (e) => GoalProtocol(
                  id: e.id,
                  goalID: e.goalID ?? "",
                  personID: e.personID ?? "",
                  title: e.title,
                  description: e.description,
                  category: e.category,
                  priority: e.priority,
                  status: e.status,
                  targetDate: e.targetDate,
                  completionDate: e.completionDate,
                  progressPercentage: e.progressPercentage,
                  projectID: e.projectID,
                ),
              )
              .toList(),
        );
      });
    });

    _habitsSubscription = dao
        .watchHabits(personId)
        .debounceTime(const Duration(milliseconds: 300))
        .listen((data) {
      if (!_alive || generation != _initGeneration) return;
      untracked(() {
        updateHabits(
          data
              .map(
                (e) => HabitProtocol(
                  id: e.id,
                  habitID: e.habitID ?? "",
                  personID: e.personID ?? "",
                  goalID: e.goalID,
                  habitName: e.habitName,
                  description: e.description,
                  frequency: e.frequency,
                  frequencyDetails: e.frequencyDetails,
                  targetCount: e.targetCount,
                  isActive: e.isActive,
                  startedDate: e.startedDate,
                ),
              )
              .toList(),
        );
      });
    });

    _skillsSubscription = dao
        .watchSkills(personId)
        .debounceTime(const Duration(milliseconds: 300))
        .listen((data) {
      if (!_alive || generation != _initGeneration) return;
      untracked(() {
        updateSkills(
          data
              .map(
                (e) => SkillProtocol(
                  id: e.id,
                  skillID: e.skillID ?? "",
                  personID: e.personID ?? "",
                  skillName: e.skillName,
                  skillCategory: e.skillCategory,
                  proficiencyLevel: e.proficiencyLevel.name,
                  practicePoints: e.point,
                  description: e.description,
                  isFeatured: e.isFeatured,
                  createdAt: e.createdAt,
                  updatedAt: e.updatedAt,
                ),
              )
              .toList(),
        );
      });
    });

    unawaited(_bootstrapPersonSkills(generation));
  }

  Future<void> _bootstrapPersonSkills(int generation) async {
    if (!_alive || generation != _initGeneration || _personId.isEmpty) return;
    try {
      await _dao.syncSkillsFromCloud(_personId);
    } catch (e) {
      debugPrint('GrowthBlock: skills sync down skipped: $e');
    }
    if (!_alive || generation != _initGeneration) return;
    await ensurePersonSkillLibrary();
    if (!_alive || generation != _initGeneration) return;
    try {
      await _dao.pushAllSkillsToCloud(_personId);
    } catch (e) {
      debugPrint('GrowthBlock: skills push up skipped: $e');
    }
  }

  /// Seeds [MindSkillCatalog.defaults] into Drift once per person.
  Future<void> ensurePersonSkillLibrary() async {
    if (_personId.isEmpty) return;
    for (final name in MindSkillCatalog.defaults) {
      await ensurePersonLibrarySkill(name);
    }
  }

  SkillProtocol? personLibrarySkillByName(String name) {
    for (final s in personLibrarySkills()) {
      if (MindSkillCatalog.namesMatch(s.skillName, name)) return s;
    }
    return null;
  }

  Future<String?> ensurePersonLibrarySkill(String name) async {
    final trimmed = MindSkillCatalog.normalizeName(name) ?? name.trim();
    if (_personId.isEmpty || trimmed.isEmpty) return null;

    final match = skills.value
        .where((s) => MindSkillCatalog.namesMatch(s.skillName, trimmed))
        .toList();
    if (match.isNotEmpty) {
      final library = match
          .where((s) => MindSkillCatalog.isPersonLibrary(s.skillCategory))
          .toList();
      if (library.isNotEmpty) {
        library.sort((a, b) {
          final aCanon =
              a.skillCategory == MindSkillCatalog.personLibraryCategory();
          final bCanon =
              b.skillCategory == MindSkillCatalog.personLibraryCategory();
          if (aCanon != bCanon) return aCanon ? -1 : 1;
          return b.practicePoints.compareTo(a.practicePoints);
        });
        return library.first.id;
      }
      // e.g. project-only "Flutter" — still create a person:library row below.
    }

    final id = IDGen.UUIDV7();
    final now = DateTime.now().toUtc();
    await _dao.createSkill(
      SkillsTableCompanion(
        id: Value(id),
        personID: Value(_personId),
        skillName: Value(trimmed),
        skillCategory: Value(MindSkillCatalog.personLibraryCategory()),
        proficiencyLevel: const Value(SkillLevel.beginner),
        point: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  List<SkillProtocol> personLibrarySkills() {
    final lib = <SkillProtocol>[];
    final byName = <String, SkillProtocol>{};
    for (final s in skills.value) {
      if (!MindSkillCatalog.isPersonLibrary(s.skillCategory)) continue;
      final key = s.skillName.trim().toLowerCase();
      if (key.isEmpty) continue;
      final existing = byName[key];
      if (existing == null || _preferPersonLibrarySkill(s, existing)) {
        byName[key] = s;
      }
    }
    lib.addAll(byName.values);
    lib.sort((a, b) {
      int indexOf(String name) {
        final i = MindSkillCatalog.defaults.indexWhere(
          (d) => MindSkillCatalog.namesMatch(d, name),
        );
        return i < 0 ? 999 : i;
      }

      return indexOf(a.skillName).compareTo(indexOf(b.skillName));
    });
    return lib;
  }

  /// Fixed skill names for this person (DB library, else catalog defaults).
  List<String> personSkillNames() {
    final fromDb = MindSkillCatalog.dedupeNames(
      personLibrarySkills().map((s) => s.skillName),
    );
    if (fromDb.isNotEmpty) return fromDb;
    return List<String>.from(MindSkillCatalog.defaults);
  }

  /// Same name → same XP on every card: **total** from all project links + Mind library.
  int unifiedPracticePointsFor(String skillName) {
    var total = 0;
    for (final s in skills.value) {
      if (!MindSkillCatalog.namesMatch(s.skillName, skillName)) continue;
      total += s.practicePoints;
    }
    return total;
  }

  /// All skill names for pickers: catalog + library + project / custom rows.
  List<String> skillNamesForPicker({Iterable<String> extra = const []}) {
    final merged = <String>[
      ...MindSkillCatalog.defaults,
      ...skills.value.map((s) => s.skillName),
      ...extra,
    ];
    final deduped = MindSkillCatalog.dedupeNames(merged);
    deduped.sort((a, b) {
      int indexOf(String name) {
        final i = MindSkillCatalog.defaults.indexWhere(
          (d) => MindSkillCatalog.namesMatch(d, name),
        );
        return i < 0 ? 999 : i;
      }

      final byDefault = indexOf(a).compareTo(indexOf(b));
      if (byDefault != 0) return byDefault;
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return deduped;
  }

  /// Same skill tiles as Mind → Skills (library + custom, minus hidden defaults).
  List<String> mindVisibleSkillNames({
    Iterable<String> customSkills = const [],
    Iterable<String> hiddenDefaultSkillsLower = const [],
  }) {
    final hidden = hiddenDefaultSkillsLower
        .map((s) => s.toLowerCase().trim())
        .where((s) => s.isNotEmpty)
        .toSet();
    final base = personSkillNames()
        .where((s) => !hidden.contains(s.toLowerCase()))
        .toList();
    final extra = customSkills.where(
      (c) => !base.any((b) => MindSkillCatalog.namesMatch(b, c)),
    );
    if (base.isNotEmpty) {
      return MindSkillCatalog.dedupeNames([...base, ...extra]);
    }
    return MindSkillCatalog.dedupeNames([
      ...MindSkillCatalog.defaults
          .where((s) => !hidden.contains(s.toLowerCase())),
      ...customSkills,
    ]);
  }

  /// Prefer `person:library` over legacy `mind:boost`, then higher XP.
  static bool _preferPersonLibrarySkill(SkillProtocol a, SkillProtocol b) {
    final aCanon = a.skillCategory == MindSkillCatalog.personLibraryCategory();
    final bCanon = b.skillCategory == MindSkillCatalog.personLibraryCategory();
    if (aCanon != bCanon) return aCanon;
    return a.practicePoints >= b.practicePoints;
  }

  Future<void> completeGoal(
    String id, {
    String? projectId,
    String? altProjectId,
    int skillXp = 15,
  }) async {
    await _dao.updateGoalStatusByUuid(id, 'done');
    if (projectId != null && projectId.isNotEmpty) {
      await grantSkillXpForProject(
        projectId,
        altProjectId: altProjectId,
        xp: skillXp,
      );
    }
  }

  static int sessionXpForMinutes(int minutes) =>
      (minutes / 2).round().clamp(10, 60);

  Future<String?> createProjectSkill(
    String projectId,
    String name, {
    String? altProjectId,
  }) async {
    final trimmed = MindSkillCatalog.normalizeName(name) ?? name.trim();
    if (_personId.isEmpty || trimmed.isEmpty) return null;
    final existing = skillsForProject(
      projectId,
      altProjectId: altProjectId,
    ).where(
      (s) => s.skillName.toLowerCase() == trimmed.toLowerCase(),
    );
    if (existing.isNotEmpty) return existing.first.id;

    await ensurePersonLibrarySkill(trimmed);

    final id = IDGen.UUIDV7();
    final now = DateTime.now().toUtc();
    await _dao.createSkill(
      SkillsTableCompanion(
        id: Value(id),
        personID: Value(_personId),
        skillName: Value(trimmed),
        skillCategory: Value(GrowthDAO.projectSkillCategory(projectId)),
        proficiencyLevel: const Value(SkillLevel.beginner),
        point: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
      ),
    );
    return id;
  }

  static String mindSkillCategory() => MindSkillCatalog.personLibraryCategory();

  Future<String?> createMindSkill(String name) =>
      ensurePersonLibrarySkill(name);

  /// Appends a custom skill to Mind prefs + person library (shared with Mind → Skills).
  Future<List<String>> appendCustomMindSkill(String name) async {
    final trimmed = MindSkillCatalog.normalizeName(name);
    if (_personId.isEmpty || trimmed == null) {
      return const [];
    }
    final prefs = await SharedPreferences.getInstance();
    final key = 'mind_custom_skills_$_personId';
    final merged = MindSkillCatalog.dedupeNames([
      ...prefs.getStringList(key) ?? const [],
      trimmed,
    ]);
    await prefs.setStringList(key, merged);
    await ensurePersonLibrarySkill(trimmed);
    return merged;
  }

  /// Skill Boost session → XP on global mind skills (creates row if missing).
  Future<int> grantSessionXpToMindSkills({
    required List<String> skillNames,
    required int minutes,
  }) async {
    if (_personId.isEmpty || skillNames.isEmpty || minutes <= 0) return 0;
    final xpEach = sessionXpForMinutes(minutes);
    var total = 0;
    for (final raw in skillNames) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      final match = skills.value
          .where((s) => MindSkillCatalog.namesMatch(s.skillName, name))
          .toList();
      final library = match
          .where((s) => MindSkillCatalog.isPersonLibrary(s.skillCategory))
          .toList();
      final skillId = library.isNotEmpty
          ? library.first.id
          : (match.isNotEmpty
              ? match.first.id
              : await ensurePersonLibrarySkill(name));
      if (skillId == null) continue;
      await _dao.addSkillPracticePoints(skillId, xpEach);
      total += xpEach;
    }
    return total;
  }

  /// Mind session → XP on project skills with matching names (creates row if missing).
  Future<int> grantSessionXpToProjectSkills({
    required String projectId,
    required List<String> skillNames,
    required int minutes,
    String? altProjectId,
  }) async {
    if (_personId.isEmpty || skillNames.isEmpty || minutes <= 0) return 0;
    final xpEach = sessionXpForMinutes(minutes);
    var total = 0;
    for (final raw in skillNames) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      await ensurePersonLibrarySkill(name);

      final projectMatches = skillsForProject(projectId, altProjectId: altProjectId)
          .where((s) => s.skillName.toLowerCase() == name.toLowerCase())
          .toList();
      final projectSkillId = projectMatches.isNotEmpty
          ? projectMatches.first.id
          : await createProjectSkill(
              projectId,
              name,
              altProjectId: altProjectId,
            );
      if (projectSkillId != null) {
        await _dao.addSkillPracticePoints(projectSkillId, xpEach);
        total += xpEach;
      }
    }
    return total;
  }

  Future<void> deleteSkill(String id) async {
    await _dao.deleteSkillByUuid(id);
  }

  /// Updates certificate metadata stored on the person library skill row.
  Future<bool> updateSkillCertificateDetails({
    required String skillName,
    String? description,
    DateTime? createdAt,
  }) async {
    if (_personId.isEmpty) return false;
    final skill = personLibrarySkillByName(skillName);
    if (skill == null) return false;
    await _dao.updateSkillCertificateDetails(
      id: skill.id,
      description: description,
      createdAt: createdAt,
    );
    return true;
  }

  /// Rename `person:library` row (and sync). Returns false if name invalid or taken.
  Future<bool> renamePersonLibrarySkill(String oldName, String newName) async {
    if (_personId.isEmpty) return false;
    final normalized = MindSkillCatalog.normalizeName(newName);
    if (normalized == null) return false;
    if (MindSkillCatalog.namesMatch(oldName, normalized)) return true;

    final taken = skills.value.any(
      (s) =>
          MindSkillCatalog.isPersonLibrary(s.skillCategory) &&
          MindSkillCatalog.namesMatch(s.skillName, normalized) &&
          !MindSkillCatalog.namesMatch(s.skillName, oldName),
    );
    if (taken) return false;

    final existing = personLibrarySkillByName(oldName);
    if (existing != null) {
      await _dao.updateSkillName(existing.id, normalized);
      return true;
    }
    await ensurePersonLibrarySkill(normalized);
    return true;
  }

  /// Removes all `person:library` rows for this display name.
  Future<void> deletePersonLibrarySkillByName(String name) async {
    if (_personId.isEmpty) return;
    final targets = skills.value
        .where(
          (s) =>
              MindSkillCatalog.isPersonLibrary(s.skillCategory) &&
              MindSkillCatalog.namesMatch(s.skillName, name),
        )
        .toList();
    for (final s in targets) {
      await deleteSkill(s.id);
    }
  }

  /// Awards practice XP to every skill linked to this project.
  Future<void> grantSkillXpForProject(
    String projectId, {
    String? altProjectId,
    int xp = 15,
  }) async {
    if (xp <= 0) return;
    for (final skill in skillsForProject(projectId, altProjectId: altProjectId)) {
      await _dao.addSkillPracticePoints(skill.id, xp);
    }
  }

  List<SkillProtocol> skillsForProject(String projectId, {String? altProjectId}) {
    return skills.value.where((s) {
      final linked = s.linkedProjectId;
      if (linked == null) return false;
      if (linked == projectId) return true;
      if (altProjectId != null && linked == altProjectId) return true;
      return false;
    }).toList();
  }

  Future<void> deleteGoal(String id) async {
    await _dao.deleteGoalByUuid(id);
  }

  Future<void> completeGoalByGoalId(
    String goalID,
  ) async {
    await _dao.updateGoalStatusByUuid(goalID, 'done');
  }


  Future<void> createNewTask(
    String title,
    String description, {
    String? projectID,
    String category = 'project',
  }) async {
    if (_personId.isEmpty) return;
    await _dao.createGoal(
      GoalsTableCompanion(
        personID: Value(_personId),
        title: Value(title),
        projectID: Value(projectID),
        description: Value(description),
        status: const Value('active'),
        category: Value(category),
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> updateGoalSdlcPhase(String id, SdlcPhase phase) async {
    await _dao.updateGoalCategoryByUuid(
      id,
      SdlcPhaseCodec.toCategory(phase),
    );
  }

  Future<void> updateGoalDetails(
    String id, {
    required String title,
    required String description,
  }) async {
    await _dao.updateGoalDetailsByUuid(
      id,
      title: title,
      description: description,
    );
  }

  /// Push local skills to Supabase, then pull (Drift watch stream updates UI).
  Future<void> syncSkills() async {
    if (_personId.isEmpty) return;
    await _dao.pushAllSkillsToCloud(_personId);
    await _dao.syncSkillsFromCloud(_personId);
  }

  /// Push local tasks/skills up, then pull from Supabase (watch stream updates UI).
  Future<void> sync() async {
    if (_personId.isEmpty) return;
    await _dao.pushAllGoalsToCloud(_personId);
    await _dao.syncGoalsFromCloud(_personId);
    await syncSkills();
  }

  void dispose() {
    _alive = false;
    _initGeneration++;
    _goalsSubscription?.cancel();
    _goalsSubscription = null;
    _habitsSubscription?.cancel();
    _habitsSubscription = null;
    _skillsSubscription?.cancel();
    _skillsSubscription = null;
  }
}
