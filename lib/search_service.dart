import 'package:my_app/appwrite_service.dart';

class SearchService {
  final AppwriteService _appwriteService;

  SearchService(this._appwriteService);

  Future<List<Map<String, dynamic>>> search(String query) async {
    final results = await Future.wait([
      _appwriteService.searchProfiles(query: query),
      _appwriteService.searchPosts(query: query),
    ]);

    final profiles = results[0].rows.map((row) {
      final data = row.data;
      data['\$id'] = row.data['\$id'];
      return {'type': 'profile', 'data': data};
    }).toList();

    final posts = results[1].rows.map((row) {
      final data = row.data;
      data['\$id'] = row.data['\$id'];
      return {'type': 'post', 'data': data};
    }).toList();

    final allResults = [...profiles, ...posts];

    allResults.sort((a, b) => _calculateScore(b, query).compareTo(_calculateScore(a, query)));

    return allResults;
  }

  double _calculateScore(Map<String, dynamic> item, String query) {
    double score = 0.0;
    final data = item['data'];

    if (item['type'] == 'profile') {
      score += _getRelevance(data['name'], query) * 2.0; // Higher weight for name
      score += _getRelevance(data['bio'], query);
    } else if (item['type'] == 'post') {
      score += _getRelevance(data['caption'], query) * 1.5;
      score += _getRelevance(data['linkTitle'], query);
      if (data['tags'] != null) {
        for (final tag in data['tags']) {
          score += _getRelevance(tag, query) * 1.2; // Weight for tags
        }
      }
    }

    return score;
  }

  double _getRelevance(String? text, String query) {
    if (text != null && text.toLowerCase().contains(query.toLowerCase())) {
      return 1.0;
    }
    return 0.0;
  }
}
