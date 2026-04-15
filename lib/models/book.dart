import '../core/models/interactive_element_model.dart';

/// Kitap modeli - dikey shorts formatında paragraflarla
class Book {
  const Book({
    required this.id,
    required this.title,
    required this.author,
    required this.paragraphs,
    this.coverImageUrl,
    this.description,
    this.genre,
    this.interactiveElements,
  });

  final String id;
  final String title;
  final String author;
  final List<String> paragraphs;
  final String? coverImageUrl;
  final String? description;
  final String? genre;
  final List<InteractiveElementModel>? interactiveElements;

  int get totalParagraphs => paragraphs.length;

  int get totalItems => paragraphs.length + (interactiveElements?.length ?? 0);
}
