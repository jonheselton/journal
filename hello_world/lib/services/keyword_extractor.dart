/// Local RAKE (Rapid Automatic Keyword Extraction) implementation.
/// Extracts meaningful keywords from text, 100% offline.
class KeywordExtractor {
  /// Common English stop words to filter out.
  static const Set<String> _stopWords = {
    'i', 'me', 'my', 'myself', 'we', 'our', 'ours', 'ourselves', 'you',
    'your', 'yours', 'yourself', 'yourselves', 'he', 'him', 'his',
    'himself', 'she', 'her', 'hers', 'herself', 'it', 'its', 'itself',
    'they', 'them', 'their', 'theirs', 'themselves', 'what', 'which',
    'who', 'whom', 'this', 'that', 'these', 'those', 'am', 'is', 'are',
    'was', 'were', 'be', 'been', 'being', 'have', 'has', 'had', 'having',
    'do', 'does', 'did', 'doing', 'a', 'an', 'the', 'and', 'but', 'if',
    'or', 'because', 'as', 'until', 'while', 'of', 'at', 'by', 'for',
    'with', 'about', 'against', 'between', 'through', 'during', 'before',
    'after', 'above', 'below', 'to', 'from', 'up', 'down', 'in', 'out',
    'on', 'off', 'over', 'under', 'again', 'further', 'then', 'once',
    'here', 'there', 'when', 'where', 'why', 'how', 'all', 'both',
    'each', 'few', 'more', 'most', 'other', 'some', 'such', 'no', 'nor',
    'not', 'only', 'own', 'same', 'so', 'than', 'too', 'very', 's', 't',
    'can', 'will', 'just', 'don', 'should', 'now', 'd', 'll', 'm', 'o',
    're', 've', 'y', 'ain', 'aren', 'couldn', 'didn', 'doesn', 'hadn',
    'hasn', 'haven', 'isn', 'ma', 'mightn', 'mustn', 'needn', 'shan',
    'shouldn', 'wasn', 'weren', 'won', 'wouldn',
    // Additional common filler words
    'also', 'could', 'would', 'get', 'got', 'getting', 'go', 'going',
    'went', 'come', 'came', 'like', 'really', 'much', 'still', 'well',
    'back', 'even', 'way', 'thing', 'things', 'lot', 'lots', 'made',
    'make', 'making', 'day', 'today', 'yesterday', 'tomorrow', 'time',
    'feel', 'feeling', 'felt', 'think', 'thought', 'know', 'knew',
    'want', 'wanted', 'need', 'needed', 'try', 'tried', 'trying',
    'take', 'took', 'taking', 'put', 'say', 'said', 'tell', 'told',
    'see', 'saw', 'look', 'looked', 'looking', 'good', 'bad', 'better',
    'worse', 'best', 'worst', 'little', 'big', 'long', 'new', 'old',
    'right', 'left', 'last', 'next', 'first',
  };

  /// Sensitive terms that should be filtered from extracted keywords.
  /// Includes medication names, financial terms, and relationship terms.
  static const Set<String> _sensitiveTerms = {
    // Medications
    'xanax', 'adderall', 'prozac', 'lexapro', 'zoloft', 'ambien',
    'klonopin', 'valium', 'oxycodone', 'vicodin', 'suboxone',
    // Financial
    'debt', 'bankruptcy', 'loan', 'mortgage', 'overdue', 'collections',
    // Relationship
    'divorce', 'affair', 'custody', 'abuse', 'assault', 'restraining',
  };

  /// Check if a keyword contains any sensitive term as a substring.
  static bool _containsSensitiveTerm(String keyword) {
    final lower = keyword.toLowerCase();
    for (final term in _sensitiveTerms) {
      if (lower.contains(term)) return true;
    }
    return false;
  }

  /// Extract keywords from the given text using a simplified RAKE algorithm.
  /// Returns a list of keywords sorted by relevance (most relevant first).
  ///
  /// When [filterSensitive] is true (default), keywords containing terms from
  /// the sensitive-term blacklist are excluded from results.
  static List<String> extract(
    String text, {
    int maxKeywords = 10,
    bool filterSensitive = true,
  }) {
    if (text.trim().isEmpty) return [];

    // Normalize text
    final normalized = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Split into candidate phrases using stop words as delimiters
    final phrases = _splitIntoPhrases(normalized);

    // Score each phrase/word using word frequency & degree
    final wordFreq = <String, int>{};
    final wordDegree = <String, int>{};

    for (final phrase in phrases) {
      final words = phrase.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      final degree = words.length - 1;
      for (final word in words) {
        wordFreq[word] = (wordFreq[word] ?? 0) + 1;
        wordDegree[word] = (wordDegree[word] ?? 0) + degree;
      }
    }

    // Calculate word scores: (degree + frequency) / frequency
    final wordScore = <String, double>{};
    for (final word in wordFreq.keys) {
      wordScore[word] =
          (wordDegree[word]! + wordFreq[word]!) / wordFreq[word]!;
    }

    // Score each phrase as the sum of its word scores
    final phraseScores = <String, double>{};
    for (final phrase in phrases) {
      final words = phrase.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
      double score = 0;
      for (final word in words) {
        score += wordScore[word] ?? 0;
      }
      // Prefer single meaningful words and short phrases (2-3 words)
      if (words.length <= 3 && words.isNotEmpty) {
        phraseScores[phrase] = score;
      }
    }

    // Sort by score descending and return top N
    final sorted = phraseScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Deduplicate and filter very short words
    final seen = <String>{};
    final results = <String>[];
    for (final entry in sorted) {
      final keyword = entry.key.trim();
      if (keyword.length < 3) continue;
      if (seen.contains(keyword)) continue;
      // Apply sensitive-term filter
      if (filterSensitive && _containsSensitiveTerm(keyword)) continue;
      seen.add(keyword);
      results.add(keyword);
      if (results.length >= maxKeywords) break;
    }

    return results;
  }

  /// Split text into candidate phrases using stop words as delimiters.
  static List<String> _splitIntoPhrases(String text) {
    final words = text.split(RegExp(r'\s+'));
    final phrases = <String>[];
    final current = <String>[];

    for (final word in words) {
      if (word.isEmpty) continue;
      if (_stopWords.contains(word) || word.length < 2) {
        if (current.isNotEmpty) {
          phrases.add(current.join(' '));
          current.clear();
        }
      } else {
        // Filter out pure numbers
        if (RegExp(r'^\d+$').hasMatch(word)) {
          if (current.isNotEmpty) {
            phrases.add(current.join(' '));
            current.clear();
          }
          continue;
        }
        current.add(word);
      }
    }
    if (current.isNotEmpty) {
      phrases.add(current.join(' '));
    }

    return phrases;
  }
}
