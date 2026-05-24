import 'owner.dart';

class OwnerPage {
  const OwnerPage({
    required this.content,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
  });

  final List<Owner> content;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;

  factory OwnerPage.fromJson(Map<String, dynamic> json) {
    return OwnerPage(
      content: (json['content'] as List<dynamic>)
          .map((item) => Owner.fromJson(item as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int,
      size: json['size'] as int,
      totalElements: json['totalElements'] as int,
      totalPages: json['totalPages'] as int,
    );
  }
}
