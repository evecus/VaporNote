import 'dart:convert';

enum NoteType { text, checklist, doodle, mixed }

class CheckItem {
  String id;
  String text;
  bool isChecked;

  CheckItem({
    required this.id,
    required this.text,
    this.isChecked = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'isChecked': isChecked ? 1 : 0,
      };

  factory CheckItem.fromMap(Map<String, dynamic> map) => CheckItem(
        id: map['id'],
        text: map['text'],
        isChecked: map['isChecked'] == 1,
      );
}

class NoteImage {
  String id;
  String path;

  NoteImage({required this.id, required this.path});

  Map<String, dynamic> toMap() => {'id': id, 'path': path};
  factory NoteImage.fromMap(Map<String, dynamic> map) =>
      NoteImage(id: map['id'], path: map['path']);
}

class Note {
  String id;
  String title;
  String content;
  String category;
  NoteType type;
  List<CheckItem> checkItems;
  List<NoteImage> images;
  String? doodlePath;
  DateTime createdAt;
  DateTime updatedAt;
  bool isPinned;
  int colorIndex;

  Note({
    required this.id,
    this.title = '',
    this.content = '',
    this.category = '全部',
    this.type = NoteType.text,
    List<CheckItem>? checkItems,
    List<NoteImage>? images,
    this.doodlePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.isPinned = false,
    this.colorIndex = 0,
  })  : checkItems = checkItems ?? [],
        images = images ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Note copyWith({
    String? title,
    String? content,
    String? category,
    NoteType? type,
    List<CheckItem>? checkItems,
    List<NoteImage>? images,
    String? doodlePath,
    bool? isPinned,
    int? colorIndex,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      type: type ?? this.type,
      checkItems: checkItems ?? this.checkItems,
      images: images ?? this.images,
      doodlePath: doodlePath ?? this.doodlePath,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isPinned: isPinned ?? this.isPinned,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'type': type.index,
        'checkItems': jsonEncode(checkItems.map((e) => e.toMap()).toList()),
        'images': jsonEncode(images.map((e) => e.toMap()).toList()),
        'doodlePath': doodlePath,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'updatedAt': updatedAt.millisecondsSinceEpoch,
        'isPinned': isPinned ? 1 : 0,
        'colorIndex': colorIndex,
      };

  factory Note.fromMap(Map<String, dynamic> map) {
    List<CheckItem> items = [];
    List<NoteImage> imgs = [];
    try {
      final rawItems = jsonDecode(map['checkItems'] ?? '[]') as List;
      items = rawItems.map((e) => CheckItem.fromMap(e)).toList();
    } catch (_) {}
    try {
      final rawImgs = jsonDecode(map['images'] ?? '[]') as List;
      imgs = rawImgs.map((e) => NoteImage.fromMap(e)).toList();
    } catch (_) {}
    return Note(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      category: map['category'] ?? '全部',
      type: NoteType.values[map['type'] ?? 0],
      checkItems: items,
      images: imgs,
      doodlePath: map['doodlePath'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
      isPinned: map['isPinned'] == 1,
      colorIndex: map['colorIndex'] ?? 0,
    );
  }

  String get preview {
    if (content.isNotEmpty) return content;
    if (checkItems.isNotEmpty) return checkItems.map((e) => e.text).join(', ');
    return '无内容';
  }
}
