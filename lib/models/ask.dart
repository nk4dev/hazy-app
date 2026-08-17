class AskCitation {
  const AskCitation({
    required this.savedUrlId,
    required this.title,
    required this.domain,
    required this.url,
    required this.faviconUrl,
    required this.snippet,
    required this.rank,
  });

  factory AskCitation.fromJson(Map<String, dynamic> json) {
    return AskCitation(
      savedUrlId: json['savedUrlId'] as String,
      title: json['title'] as String?,
      domain: json['domain'] as String?,
      url: json['url'] as String,
      faviconUrl: json['faviconUrl'] as String?,
      snippet: json['snippet'] as String,
      rank: (json['rank'] as num).toInt(),
    );
  }

  final String savedUrlId;
  final String? title;
  final String? domain;
  final String url;
  final String? faviconUrl;
  final String snippet;
  final int rank;
}

class AskMessage {
  const AskMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.modelId,
    required this.usedFallback,
    required this.createdAt,
    required this.citations,
  });

  factory AskMessage.fromJson(Map<String, dynamic> json) {
    return AskMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      modelId: json['modelId'] as String?,
      usedFallback: json['usedFallback'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => AskCitation.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }

  final String id;
  final String role; // "user" | "assistant"
  final String content;
  final String? modelId;
  final bool usedFallback;
  final DateTime createdAt;
  final List<AskCitation> citations;

  bool get isUser => role == 'user';
}

class AskThread {
  const AskThread({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AskThread.fromJson(Map<String, dynamic> json) {
    return AskThread(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class AskThreadWithMessages {
  const AskThreadWithMessages({required this.thread, required this.messages});

  factory AskThreadWithMessages.fromJson(Map<String, dynamic> json) {
    return AskThreadWithMessages(
      thread: AskThread.fromJson(json['thread'] as Map<String, dynamic>),
      messages: (json['messages'] as List<dynamic>)
          .map((e) => AskMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final AskThread thread;
  final List<AskMessage> messages;
}

class AskResponse {
  const AskResponse({
    required this.thread,
    required this.message,
    required this.citations,
    required this.sourceCount,
  });

  factory AskResponse.fromJson(Map<String, dynamic> json) {
    return AskResponse(
      thread: AskThread.fromJson(json['thread'] as Map<String, dynamic>),
      message: AskMessage.fromJson(json['message'] as Map<String, dynamic>),
      citations: (json['citations'] as List<dynamic>)
          .map((e) => AskCitation.fromJson(e as Map<String, dynamic>))
          .toList(),
      sourceCount: (json['meta'] as Map<String, dynamic>)['sourceCount']
          as int,
    );
  }

  final AskThread thread;
  final AskMessage message;
  final List<AskCitation> citations;
  final int sourceCount;
}
