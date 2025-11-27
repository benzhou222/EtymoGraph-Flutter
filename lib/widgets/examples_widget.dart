import 'package:flutter/material.dart';
import '../models.dart';

class ExamplesWidget extends StatelessWidget {
  // Icon/Color pools and assignment caches to ensure each unique context
  // string receives a unique icon and color consistently.
  static final List<IconData> _iconPool = [
    Icons.lightbulb,
    Icons.star,
    Icons.chat_bubble,
    Icons.business,
    Icons.school,
    Icons.article,
    Icons.gavel,
    Icons.local_hospital,
    Icons.build,
    Icons.format_quote,
    Icons.menu_book,
    Icons.flight,
    Icons.emoji_emotions,
    Icons.restaurant,
    Icons.sports_soccer,
    Icons.attach_money,
    Icons.campaign,
    Icons.people,
    Icons.public,
    Icons.mail,
    Icons.message,
    Icons.phone,
    Icons.notifications,
    Icons.support_agent,
    Icons.storefront,
    Icons.rss_feed,
    Icons.rate_review,
  ];
  static int _iconIdx = 0;
  static final Map<String, IconData> _contextIconCache = {};

  static final List<Color> _colorPool = [
    Colors.purple,
    Colors.blueAccent,
    Colors.indigo,
    Colors.teal,
    Colors.orange,
    Colors.grey,
    Colors.redAccent,
    Colors.deepPurple,
    Colors.lightBlue,
    Colors.blueGrey,
    Colors.deepOrange,
    Colors.green,
    Colors.amber,
    Colors.brown,
  ];
  static int _colorIdx = 0;
  static final Map<String, Color> _contextColorCache = {};
  final List<ExampleUsage> examples;
  final String currentWord;
  final List<String> historyWords;

  const ExamplesWidget({
    super.key,
    required this.examples,
    required this.currentWord,
    required this.historyWords,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.1))),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.format_quote, color: Colors.purple),
            title: const Text('场景例句',
                style: TextStyle(fontWeight: FontWeight.bold)),
            tileColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withOpacity(0.3),
            shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children:
                  examples.map((ex) => _buildExampleItem(context, ex)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleItem(BuildContext context, ExampleUsage ex) {
    // Use a fixed left slot for the context pill so that all sentences
    // are aligned at the same horizontal position regardless of pill width.
    // const leftSlotWidth = 110.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.only(left: 12, right: 8),
      decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Colors.purple, width: 4))),
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(flex: 1, child: SizedBox()),
          SizedBox(
            width: 200,
            child: Row(
              children: [
                if (ex.context.trim().isNotEmpty) ...[
                  _buildContextPill(context, ex.context),
                  // const SizedBox(height: 8),
                ]
              ],
            ),
          ),
          const SizedBox(width: 30),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  textAlign: TextAlign.left,
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 16,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                      height: 1.5,
                      fontFamily: 'Roboto', // Sans-serif
                      letterSpacing: 0.5,
                    ),
                    children: _highlightText(ex.sentence, context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(ex.explanation,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).textTheme.bodySmall?.color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextPill(BuildContext context, String ctx) {
    final icon = _iconForContext(ctx);
    final color = _colorForContext(ctx);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(message: ctx, child: Icon(icon, size: 14, color: color)),
          const SizedBox(width: 6),
          Text(ctx,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Color _colorForContext(String ctx) {
    final s = ctx.trim().toLowerCase();
    if (s.contains('conversation') ||
        s.contains('chat') ||
        s.contains('对话') ||
        s.contains('聊天')) {
      return Colors.blueAccent;
    }
    if (s.contains('business') ||
        s.contains('formal') ||
        s.contains('商务') ||
        s.contains('正式')) {
      return Colors.indigo;
    }
    if (s.contains('academic') ||
        s.contains('school') ||
        s.contains('学术') ||
        s.contains('学校')) {
      return Colors.teal;
    }
    if (s.contains('news') ||
        s.contains('article') ||
        s.contains('新闻') ||
        s.contains('报道')) {
      return Colors.orange;
    }
    if (s.contains('legal') || s.contains('法律') || s.contains('合同')) {
      return Colors.grey;
    }
    if (s.contains('medical') ||
        s.contains('health') ||
        s.contains('医疗') ||
        s.contains('健康')) {
      return Colors.redAccent;
    }
    if (s.contains('technical') ||
        s.contains('tech') ||
        s.contains('技术') ||
        s.contains('科技')) {
      return Colors.deepPurple;
    }
    if (s.contains('travel') || s.contains('机场') || s.contains('旅行')) {
      return Colors.lightBlue;
    }
    if (s.contains('email') ||
        s.contains('sms') ||
        s.contains('phone') ||
        s.contains('邮件') ||
        s.contains('短信') ||
        s.contains('电话')) {
      return Colors.blueGrey;
    }
    if (s.contains('recipe') ||
        s.contains('food') ||
        s.contains('餐饮') ||
        s.contains('食谱')) {
      return Colors.deepOrange;
    }
    if (s.contains('sport') || s.contains('体育')) {
      return Colors.green;
    }

    // Assign a unique color for previously unseen contexts as a fallback
    if (_contextColorCache.containsKey(s)) return _contextColorCache[s]!;
    // Avoid reserved colors if possible (colors used by known categories)
    final reserved = <Color>{
      Colors.blueAccent,
      Colors.indigo,
      Colors.teal,
      Colors.orange,
      Colors.grey,
      Colors.redAccent,
      Colors.deepPurple,
      Colors.lightBlue,
      Colors.blueGrey,
      Colors.deepOrange,
      Colors.green,
      Colors.purple,
    };

    Color chosen;
    for (var i = 0; i < _colorPool.length; i++) {
      final idx = (_colorIdx + i) % _colorPool.length;
      final candidate = _colorPool[idx];
      if (!reserved.contains(candidate) &&
          !_contextColorCache.containsValue(candidate)) {
        chosen = candidate;
        _colorIdx = (idx + 1) % _colorPool.length;
        _contextColorCache[s] = chosen;
        return chosen;
      }
    }
    // fall back
    chosen = _colorPool[_colorIdx];
    _colorIdx = (_colorIdx + 1) % _colorPool.length;
    _contextColorCache[s] = chosen;
    return chosen;
  }

  IconData _iconForContext(String ctx) {
    // Normalize
    final s = ctx.trim().toLowerCase();

    // Known exact categories (often returned by LLMs)
    final exact = {
      'customer service': Icons.support_agent,
      'customer support': Icons.support_agent,
      'conversation': Icons.chat_bubble,
      'dialog': Icons.chat_bubble,
      'chat': Icons.chat_bubble,
      'casual': Icons.emoji_emotions,
      'informal': Icons.emoji_emotions,
      'business': Icons.business,
      'formal': Icons.business,
      'academic': Icons.school,
      'school': Icons.school,
      'news': Icons.article,
      'article': Icons.article,
      'legal': Icons.gavel,
      'medical': Icons.local_hospital,
      'technical': Icons.build,
      'idiom': Icons.format_quote,
      'literature': Icons.menu_book,
      'novel': Icons.menu_book,
      'poem': Icons.menu_book,
      'travel': Icons.flight,
      'email': Icons.mail,
      'sms': Icons.message,
      'text message': Icons.message,
      'phone': Icons.phone,
      'recipe': Icons.restaurant,
      'food': Icons.restaurant,
      'sport': Icons.sports_soccer,
      'finance': Icons.attach_money,
      'marketing': Icons.campaign,
      'advert': Icons.campaign,
      'advertisement': Icons.campaign,
      'notification': Icons.notifications,
      'tweet': Icons.travel_explore, // light placeholder
      'social media': Icons.public,
      'review': Icons.rate_review,
      'product description': Icons.storefront,
      'blog': Icons.rss_feed,
      'social': Icons.people,
    };

    // If hits an exact token, return it
    for (final key in exact.keys) {
      if (s == key) return exact[key]!;
    }

    // Continue to keyword checks below; if none matched, an unique icon
    // will be assigned at the end as a fallback.

    // English keywords
    if (s.contains('conversation') ||
        s.contains('dialog') ||
        s.contains('chat')) {
      return Icons.chat_bubble;
    }
    // Chinese: 对话 / 聊天
    if (s.contains('对话') || s.contains('聊天')) {
      return Icons.chat_bubble;
    }

    if (s.contains('formal') ||
        s.contains('business') ||
        s.contains('official')) {
      return Icons.business;
    }
    // Chinese: 商务 / 正式
    if (s.contains('商务') || s.contains('正式') || s.contains('官方')) {
      return Icons.business;
    }

    if (s.contains('academic') ||
        s.contains('school') ||
        s.contains('lecture')) {
      return Icons.school;
    }
    // Chinese: 学术 / 学校 / 演讲
    if (s.contains('学术') || s.contains('学校') || s.contains('演讲')) {
      return Icons.school;
    }

    if (s.contains('news') || s.contains('article') || s.contains('report')) {
      return Icons.article;
    }
    // Chinese: 新闻 / 报道 / 文章
    if (s.contains('新闻') || s.contains('报道') || s.contains('文章')) {
      return Icons.article;
    }

    if (s.contains('legal') || s.contains('law') || s.contains('contract')) {
      return Icons.gavel;
    }
    // Chinese: 法律 / 合同 / 法律文件
    if (s.contains('法律') || s.contains('合同') || s.contains('法条')) {
      return Icons.gavel;
    }

    if (s.contains('medical') || s.contains('health') || s.contains('doctor')) {
      return Icons.local_hospital;
    }
    // Chinese: 医疗 / 健康 / 医生
    if (s.contains('医疗') || s.contains('健康') || s.contains('医生')) {
      return Icons.local_hospital;
    }

    if (s.contains('technical') || s.contains('tech') || s.contains('code')) {
      return Icons.build;
    }
    // Chinese: 技术 / 代码 / 科技
    if (s.contains('技术') || s.contains('代码') || s.contains('科技')) {
      return Icons.build;
    }

    if (s.contains('idiom') || s.contains('idiomatic')) {
      return Icons.format_quote;
    }
    // Chinese: 习语 / 惯用法
    if (s.contains('习语') || s.contains('惯用') || s.contains('成语')) {
      return Icons.format_quote;
    }

    if (s.contains('literature') || s.contains('novel') || s.contains('poem')) {
      return Icons.menu_book;
    }
    // Chinese: 文学 / 小说 / 诗歌
    if (s.contains('文学') || s.contains('小说') || s.contains('诗歌')) {
      return Icons.menu_book;
    }

    if (s.contains('travel') || s.contains('airport') || s.contains('flight')) {
      return Icons.flight;
    }
    // Chinese: 旅行 / 机场 / 航班
    if (s.contains('旅行') || s.contains('机场') || s.contains('航班')) {
      return Icons.flight;
    }

    // If no keyword matched, try to assign a unique icon for this
    // specific context string so different scenes are visually distinct.
    final reserved = exact.values.toSet();
    if (_contextIconCache.containsKey(s)) return _contextIconCache[s]!;
    IconData? chosen;
    for (var i = 0; i < _iconPool.length; i++) {
      final idx = (_iconIdx + i) % _iconPool.length;
      final candidate = _iconPool[idx];
      if (!reserved.contains(candidate) &&
          !_contextIconCache.containsValue(candidate)) {
        chosen = candidate;
        _iconIdx = (idx + 1) % _iconPool.length;
        break;
      }
    }
    chosen ??= _iconPool[_iconIdx];
    _iconIdx = (_iconIdx + 1) % _iconPool.length;
    _contextIconCache[s] = chosen;
    return chosen;
  }

  List<TextSpan> _highlightText(String text, BuildContext context) {
    List<TextSpan> spans = [];

    // Create a combined regex pattern for current word and history words
    final wordsToHighlight = [
      currentWord,
      ...historyWords.where((h) => h.toLowerCase() != currentWord.toLowerCase())
    ];
    if (wordsToHighlight.isEmpty) return [TextSpan(text: text)];

    final patternStr = wordsToHighlight.map((w) => RegExp.escape(w)).join('|');
    // Match word boundaries to avoid partial matches inside other words
    final pattern =
        RegExp(r"\b(" + patternStr + r")\w*\b", caseSensitive: false);

    text.splitMapJoin(
      pattern,
      onMatch: (Match m) {
        final word = m.group(0)!;
        final lowerWord = word.toLowerCase();

        if (lowerWord.startsWith(currentWord.toLowerCase())) {
          // Current Word: Blue + Bold
          spans.add(TextSpan(
              text: word,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.blue)));
        } else {
          // History Word: Amber + Bold
          spans.add(TextSpan(
              text: word,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.amber)));
        }
        return word;
      },
      onNonMatch: (String s) {
        spans.add(TextSpan(text: s));
        return s;
      },
    );
    return spans;
  }
}
