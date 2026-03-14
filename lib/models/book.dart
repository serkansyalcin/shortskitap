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
  });

  final String id;
  final String title;
  final String author;
  final List<String> paragraphs;
  final String? coverImageUrl;
  final String? description;
  final String? genre;

  int get totalParagraphs => paragraphs.length;
}
