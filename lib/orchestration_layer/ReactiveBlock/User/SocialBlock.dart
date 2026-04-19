import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

class SocialBlock {
  final activeTab = signal(0);
  final totalTabs = 4;

  SocialBlock();

  Future<String> getMonthlyReflection(AchievementsDAO dao, String personId) async {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final stream = dao.watchAchievementsByPerson(personId);
    final allAchievements = await stream.first;
    
    final recent = allAchievements.where((a) {
      return a.createdAt.isAfter(thirtyDaysAgo);
    }).toList();

    if (recent.isEmpty) {
      return "No wins logged this month. Start logging to get reflection insights!";
    }

    final domainCounts = <String, int>{};
    for (var a in recent) {
      domainCounts[a.domain] = (domainCounts[a.domain] ?? 0) + 1;
    }

    String topDomain = '';
    int maxCount = 0;
    domainCounts.forEach((domain, count) {
      if (count > maxCount) {
        maxCount = count;
        topDomain = domain;
      }
    });

    final avgMeaning = recent.fold<double>(0, (sum, a) => sum + (a.meaningScore ?? 5)) / recent.length;
    final avgImpact = recent.fold<double>(0, (sum, a) => sum + a.impactScore) / recent.length;

    String reflection = "You logged ${recent.length} wins this month! ";
    reflection += "Your main focus was '$topDomain' ($maxCount wins). ";

    if (avgMeaning >= 8) {
      reflection += "You felt highly fulfilled by these efforts. ";
    } else if (avgMeaning < 5) {
      reflection += "Consider doing things that bring you more personal meaning next month. ";
    }

    if (avgImpact >= 8) {
      reflection += "You also made a MASSIVE positive impact on others. Hero work! ";
    } else {
      reflection += "How can you broaden your impact next month? ";
    }

    // Level up suggestion
    final allDomains = ['health', 'finance', 'good social impact', 'relationship', 'project', 'knowledge'];
    final unusedDomains = allDomains.where((d) => !domainCounts.containsKey(d)).toList();
    
    if (unusedDomains.isNotEmpty) {
      reflection += "\n\n**Next Level Goal:** Try focusing on '${unusedDomains.first}' next month to balance your growth.";
    } else {
      reflection += "\n\n**Next Level Goal:** You've achieved cross-domain success! Try deepening your expertise in your favorite area.";
    }

    return reflection;
  }
}
