import 'package:flutter/material.dart';

class CategoryModel {
  final String id;
  final String title;
  final IconData icon;
  final int? jioCategoryId;

  const CategoryModel({
    required this.id,
    required this.title,
    required this.icon,
    this.jioCategoryId,
  });

  static const List<CategoryModel> defaultCategories = [
    CategoryModel(id: 'all', title: 'All Channels', icon: Icons.grid_view_rounded),
    CategoryModel(id: 'favorites', title: 'Favorites', icon: Icons.favorite_rounded),
    CategoryModel(id: 'entertainment', title: 'Entertainment', icon: Icons.tv_rounded, jioCategoryId: 5),
    CategoryModel(id: 'movies', title: 'Movies', icon: Icons.movie_creation_rounded, jioCategoryId: 6),
    CategoryModel(id: 'sports', title: 'Sports', icon: Icons.sports_cricket_rounded, jioCategoryId: 8),
    CategoryModel(id: 'news', title: 'News', icon: Icons.newspaper_rounded, jioCategoryId: 12),
    CategoryModel(id: 'kids', title: 'Kids', icon: Icons.child_care_rounded, jioCategoryId: 7),
    CategoryModel(id: 'music', title: 'Music', icon: Icons.music_note_rounded, jioCategoryId: 13),
    CategoryModel(id: 'infotainment', title: 'Infotainment', icon: Icons.explore_rounded, jioCategoryId: 10),
    CategoryModel(id: 'lifestyle', title: 'Lifestyle', icon: Icons.style_rounded, jioCategoryId: 9),
    CategoryModel(id: 'devotional', title: 'Devotional', icon: Icons.self_improvement_rounded, jioCategoryId: 15),
  ];
}
