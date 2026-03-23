import 'author_model.dart';
import 'category_model.dart';

class BookModel {
  final int id;
  final String title;
  final String slug;
  final AuthorModel? author;
  final CategoryModel? category;
  final int? seriesId;
  final int? seriesOrder;
  final String? coverImageUrl;
  final String? description;
  final String? isbn;
  final String language;
  final List<String> tags;
  final bool isPublished;
  final bool isFeatured;
  final bool isPremium;
  final bool isKids;
  final int totalParagraphs;
  final int? estimatedReadMinutes;
  final int viewCount;
  final double rating;
  final int reviewsCount;

  const BookModel({
    required this.id,
    required this.title,
    required this.slug,
    this.author,
    this.category,
    this.seriesId,
    this.seriesOrder,
    this.coverImageUrl,
    this.description,
    this.isbn,
    required this.language,
    required this.tags,
    required this.isPublished,
    required this.isFeatured,
    required this.isPremium,
    required this.isKids,
    required this.totalParagraphs,
    this.estimatedReadMinutes,
    required this.viewCount,
    this.rating = 0.0,
    this.reviewsCount = 0,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) => BookModel(
    id: _asInt(json['id']),
    title: json['title'] as String,
    slug: json['slug'] as String,
    author: json['author'] != null
        ? AuthorModel.fromJson(json['author'] as Map<String, dynamic>)
        : null,
    category: json['category'] != null
        ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    seriesId: _asNullableInt(json['series_id']),
    seriesOrder: _asNullableInt(json['series_order']),
    coverImageUrl: json['cover_image_url'] as String?,
    description: json['description'] as String?,
    isbn: json['isbn'] as String?,
    language: json['language'] as String? ?? 'tr',
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    isPublished: _asBool(json['is_published']),
    isFeatured: _asBool(json['is_featured']),
    isPremium: _asBool(json['is_premium']),
    isKids: _asBool(json['is_kids']),
    totalParagraphs: _asInt(json['total_paragraphs']),
    estimatedReadMinutes: _asNullableInt(json['estimated_read_minutes']),
    viewCount: _asInt(json['view_count']),
    rating: _asDouble(json['reviews_avg_rating']),
    reviewsCount: _asInt(json['reviews_count']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'slug': slug,
    'author': author?.toJson(),
    'category': category?.toJson(),
    'series_id': seriesId,
    'series_order': seriesOrder,
    'cover_image_url': coverImageUrl,
    'description': description,
    'isbn': isbn,
    'language': language,
    'tags': tags,
    'is_published': isPublished,
    'is_featured': isFeatured,
    'is_premium': isPremium,
    'is_kids': isKids,
    'total_paragraphs': totalParagraphs,
    'estimated_read_minutes': estimatedReadMinutes,
    'view_count': viewCount,
    'reviews_avg_rating': rating,
    'reviews_count': reviewsCount,
  };

  static int _asInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? fallback;
    }
    return fallback;
  }

  static int? _asNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt();
    }
    return null;
  }

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized == '1' || normalized == 'true';
    }
    return false;
  }
}
