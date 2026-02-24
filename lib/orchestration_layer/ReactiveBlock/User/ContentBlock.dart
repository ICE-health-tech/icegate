import 'dart:async';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/Protocol/User/ContentProtocols.dart';

class ContentBlock {
  final posts = listSignal<BlogPostProtocol>([]);

  StreamSubscription? _postsSubscription;

  void updatePosts(List<BlogPostProtocol> data) => posts.value = data;

  void init(ContentDAO dao, String authorID) {
    if (authorID.isEmpty) {
      debugPrint("ContentBlock: Skipping init, authorID is empty.");
      return;
    }
    _postsSubscription?.cancel();
    _postsSubscription = dao.watchPosts(authorID).listen((data) {
      updatePosts(
        data
            .map(
              (e) => BlogPostProtocol(
                blogPostID: e.postID ?? "",
                authorID: e.authorID,
                title: e.title,
                slug: e.slug,
                excerpt: e.excerpt,
                content: e.content,
                featuredImageUrl: e.featuredImageUrl,
                status: e.status.name,
                isFeatured: e.isFeatured,
                viewCount: e.viewCount,
                likeCount: e.likeCount,
                publishedAt: e.publishedAt,
                scheduledFor: e.scheduledFor,
              ),
            )
            .toList(),
      );
    });
  }

  void dispose() {
    _postsSubscription?.cancel();
  }
}
