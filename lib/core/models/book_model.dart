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
    id: json['id'] as int,
    title: json['title'] as String,
    slug: json['slug'] as String,
    author: json['author'] != null
        ? AuthorModel.fromJson(json['author'] as Map<String, dynamic>)
        : null,
    category: json['category'] != null
        ? CategoryModel.fromJson(json['category'] as Map<String, dynamic>)
        : null,
    seriesId: json['series_id'] as int?,
    seriesOrder: json['series_order'] as int?,
    coverImageUrl: json['cover_image_url'] as String?,
    description: json['description'] as String?,
    isbn: json['isbn'] as String?,
    language: json['language'] as String? ?? 'tr',
    tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    isPublished: json['is_published'] == true,
    isFeatured: json['is_featured'] == true,
    isPremium: json['is_premium'] == true,
    isKids: json['is_kids'] == true,
    totalParagraphs: json['total_paragraphs'] as int? ?? 0,
    estimatedReadMinutes: json['estimated_read_minutes'] as int?,
    viewCount: json['view_count'] as int? ?? 0,
    rating: (json['reviews_avg_rating'] as num?)?.toDouble() ?? 0.0,
    reviewsCount: json['reviews_count'] as int? ?? 0,
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
}
