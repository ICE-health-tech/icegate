import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:signals/signals.dart';

class UserObjectResource {
  final String avatarImage;
  final String coverImage;
  static String baseObjectUrl = 'https://backend.duylong.art';
  UserObjectResource({required this.avatarImage, required this.coverImage});
}

class ObjectDatabaseBlock {
  final userObjectResource = signal<UserObjectResource>(
    UserObjectResource(avatarImage: '', coverImage: ''),
  );

  Future<void> updateUrlOfUser(PersonBlock personBlock) async {
    String alias = personBlock.information.value.profiles.alias;
    print("alias: $alias");

    if (alias.isEmpty) {
      userObjectResource.value = UserObjectResource(
        avatarImage: '',
        coverImage: '',
      );
      return;
    }

    // Ensure baseObjectUrl doesn't end with slash, prevent double slashes
    final baseUrl = UserObjectResource.baseObjectUrl.endsWith('/')
        ? UserObjectResource.baseObjectUrl.substring(
            0,
            UserObjectResource.baseObjectUrl.length - 1,
          )
        : UserObjectResource.baseObjectUrl;

    if (alias == 'Guest-Shield') {
      userObjectResource.value = UserObjectResource(
        avatarImage:
            "https://ui-avatars.com/api/?name=Guest+User&background=6366F1&color=fff",
        coverImage:
            "https://images.unsplash.com/photo-1614850523296-d8c1af93d400?q=80&w=1000&auto=format&fit=crop",
      );
      return;
    }

    userObjectResource.value = UserObjectResource(
      avatarImage:
          "$baseUrl/object/duylongwebappobjectdatabase/$alias/admin.png",
      coverImage:
          "$baseUrl/object/duylongwebappobjectdatabase/$alias/cover.png",
    );
  }
}
