import 'dart:convert';
import 'package:http/http.dart' as http;

class AirtableService {
  static const String _baseUrl = 'https://api.airtable.com/v0';
  
  // Local Ads configuration
  static const String _localAdsBaseId = 'app7yrCmMRyLNt2BP'; 
  static const String _localAdsTable = 'tbldEORhvw7bygAHv';
  
  // Quick Tips configuration
  static const String _quickTipsBaseId = 'appdGQC1UmfAIXINl';
  static const String _quickTipsTable = 'tblXRPnMNaksNK6at';
  
  static const String _personalAccessToken = 'patjR5LcLuINBNXX8.54bc8ad0dbe670f08c098141206b26df2722c737f661140c3fb4a71f8303155d';
  
  static const Map<String, String> _headers = {
    'Authorization': 'Bearer $_personalAccessToken',
    'Content-Type': 'application/json',
  };

  /// Fetches all local ads from Airtable
  static Future<List<LocalAd>> fetchLocalAds({String? province, String? city}) async {
    try {
      // Using table ID directly (no encoding needed)
      String url = '$_baseUrl/$_localAdsBaseId/$_localAdsTable';
      
      // Add filters for location if provided
      List<String> filters = [];
      if (province != null && province.isNotEmpty) {
        filters.add("({Province/State} = '$province')");
      }
      if (city != null && city.isNotEmpty) {
        filters.add("({City/Town} = '$city')");
      }
      
      // Only show active ads
      filters.add("({Status} = 'Active')");
      
      if (filters.isNotEmpty) {
        String filterFormula = 'AND(${filters.join(', ')})';
        url += '?filterByFormula=${Uri.encodeComponent(filterFormula)}';
      }
      
      print('Fetching ads from URL: $url'); // Debug log
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'] ?? [];
        print('Successfully fetched ${records.length} records');
        
        return records.map((record) => LocalAd.fromAirtable(record)).toList();
      } else {
        print('HTTP Error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to load ads: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching local ads: $e');
      return [];
    }
  }

  /// Fetches ads for a specific location
  static Future<List<LocalAd>> fetchLocalAdsForLocation(String province, String city) async {
    return await fetchLocalAds(province: province, city: city);
  }

  /// Updates ad click/view statistics (if you want to track engagement)
  static Future<void> trackAdInteraction(String recordId, String interactionType) async {
    try {
      // This is optional - you could add interaction tracking fields to your Airtable
      print('Tracking $interactionType for ad: $recordId');
    } catch (e) {
      print('Error tracking ad interaction: $e');
    }
  }

  /// Fetches all quick tips from Airtable
  static Future<List<QuickTip>> fetchQuickTips() async {
    try {
      String url = '$_baseUrl/$_quickTipsBaseId/$_quickTipsTable';
      
      // Only show active tips
      String filterFormula = "({Status} = 'Active')";
      url += '?filterByFormula=${Uri.encodeComponent(filterFormula)}';
      
      print('Fetching quick tips from URL: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> records = data['records'] ?? [];
        print('Successfully fetched ${records.length} quick tips');
        
        return records.map((record) => QuickTip.fromAirtable(record)).toList();
      } else {
        print('HTTP Error ${response.statusCode}: ${response.body}');
        throw Exception('Failed to load quick tips: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error fetching quick tips: $e');
      return [];
    }
  }
}

class LocalAd {
  final String id;
  final String headline;
  final String description;
  final String status;
  final String? url;
  final List<String> attachments;
  final String? province;
  final String? city;

  LocalAd({
    required this.id,
    required this.headline,
    required this.description,
    required this.status,
    this.url,
    required this.attachments,
    this.province,
    this.city,
  });

  factory LocalAd.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] ?? {};
    
    return LocalAd(
      id: record['id'] ?? '',
      headline: fields['Headline'] ?? '',
      description: fields['Description'] ?? '',
      status: fields['Status'] ?? '',
      url: fields['URL'],
      attachments: _parseAttachments(fields['Attachments']),
      province: fields['Province/State'],
      city: fields['City/Town'],
    );
  }

  static List<String> _parseAttachments(dynamic attachments) {
    if (attachments == null) return [];
    
    if (attachments is List) {
      List<String> urls = [];
      
      for (final attachment in attachments) {
        if (attachment is Map<String, dynamic>) {
          final url = attachment['url']?.toString();
          if (url != null && url.isNotEmpty) {
            urls.add(url);
          }
        }
      }
      
      print('Parsed ${urls.length} attachment URLs');
      return urls;
    }
    
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      'description': description,
      'status': status,
      'url': url,
      'attachments': attachments,
      'province': province,
      'city': city,
    };
  }

  @override
  String toString() {
    return 'LocalAd(id: $id, headline: $headline, city: $city, province: $province)';
  }
}

class QuickTip {
  final String id;
  final String headline;
  final String excerpt;
  final String status;
  final String? sponsor;

  QuickTip({
    required this.id,
    required this.headline,
    required this.excerpt,
    required this.status,
    this.sponsor,
  });

  factory QuickTip.fromAirtable(Map<String, dynamic> record) {
    final fields = record['fields'] ?? {};
    
    return QuickTip(
      id: record['id'] ?? '',
      headline: fields['Headline'] ?? '',
      excerpt: fields['Excerpt'] ?? '',
      status: fields['Status'] ?? '',
      sponsor: fields['Sponsor'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'headline': headline,
      'excerpt': excerpt,
      'status': status,
      'sponsor': sponsor,
    };
  }

  @override
  String toString() {
    return 'QuickTip(id: $id, headline: $headline, sponsor: $sponsor)';
  }
}
