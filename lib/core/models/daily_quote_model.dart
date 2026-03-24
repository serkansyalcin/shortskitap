class DailyQuoteModel {
  final int id;
  final String content;
  final QuoteBook book;

  DailyQuoteModel({
    required this.id,
    required this.content,
    required this.book,
  });

  factory DailyQuoteModel.fromJson(Map<String, dynamic> json) {
    return DailyQuoteModel(
      id: json['id'],
      content: json['content'],
      book: QuoteBook.fromJson(json['book']),
    );
  }
}

class QuoteBook {
  final int id;
  final String title;
  final String slug;
  final String? author;

  QuoteBook({
    required this.id,
    required this.title,
    required this.slug,
    this.author,
  });

  factory QuoteBook.fromJson(Map<String, dynamic> json) {
    return QuoteBook(
      id: json['id'],
      title: json['title'],
      slug: json['slug'],
      author: json['author'],
    );
  }
}
