// city-model.dart

import 'dart:convert';

bool? _toBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final t = v.trim().toLowerCase();
    return t == '1' || t == 'true' || t == 'yes' || t == 'y';
  }
  return null;
}

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String? _toStr(dynamic v) => v == null ? null : v.toString();

/// --- Mojibake fixer ---
/// Detects strings like "Ø§Ù„Ù‚Ø¯Ø³" and re-decodes them from latin1->utf8.
/// Leaves already-correct Arabic untouched.
String _fixMojibake(String? value) {
  if (value == null) return '';
  final s = value;
  // Heuristic: mojibake often has these characters
  final looksBroken = RegExp(r'[ØÙÆÂÃ]|Ã|Â').hasMatch(s);
  if (!looksBroken) return s;
  try {
    return utf8.decode(latin1.encode(s));
  } catch (_) {
    return s;
  }
}

class City {
  final int id;
  final String? name;
  final String? arabicName;
  final String? englishName;
  final int? regionId;
  final bool? isSelected;
  final bool? isActive;

  City({
    required this.id,
    this.name,
    this.arabicName,
    this.englishName,
    this.regionId,
    this.isSelected,
    this.isActive,
  });

  factory City.fromJson(Map<String, dynamic> j) {
    return City(
      id: _toInt(j['id']) ?? 0,
      // ✅ only change: pass through mojibake fixer
      name: _fixMojibake(_toStr(j['name'])),
      arabicName: _fixMojibake(_toStr(j['arabic_name'])),
      englishName: _fixMojibake(_toStr(j['english_name'])),
      regionId: _toInt(j['region_id']),
      isSelected: _toBool(j['is_selected']),
      isActive: _toBool(j['is_active']),
    );
  }

  String displayName() {
    if ((arabicName?.trim().isNotEmpty ?? false)) return arabicName!.trim();
    if ((name?.trim().isNotEmpty ?? false)) return name!.trim();
    return (englishName ?? '').trim();
  }
}

class CitiesPage {
  final List<City> data;
  final int currentPage;
  final int lastPage;

  CitiesPage({
    required this.data,
    required this.currentPage,
    required this.lastPage,
  });

  factory CitiesPage.fromJson(Map<String, dynamic> j) {
    final List list = (j['data'] ?? []) as List;
    final meta = (j['meta'] ?? {}) as Map<String, dynamic>;
    return CitiesPage(
      data: list.map((e) => City.fromJson(e as Map<String, dynamic>)).toList(),
      currentPage: _toInt(meta['current_page']) ?? 1,
      lastPage: _toInt(meta['last_page']) ?? 1,
    );
  }
}
