import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:quds_yaghmour/Server/domains/domains.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<NotificationModel> _all = [];
  bool _loading = false;
  bool _hasError = false;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _loadingMore = false;
  final Set<String> _deletingIds = <String>{};
  final ScrollController _allScrollController = ScrollController();
  final ScrollController _unreadScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _allScrollController.addListener(_onAllScroll);
    _unreadScrollController.addListener(_onUnreadScroll);
    _fetchNotifications(reset: true);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _allScrollController.dispose();
    _unreadScrollController.dispose();
    super.dispose();
  }

  void _onAllScroll() {
    if (_allScrollController.position.pixels >=
            _allScrollController.position.maxScrollExtent - 100 &&
        !_loadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  void _onUnreadScroll() {
    if (_unreadScrollController.position.pixels >=
            _unreadScrollController.position.maxScrollExtent - 100 &&
        !_loadingMore &&
        _currentPage < _lastPage) {
      _loadMore();
    }
  }

  Future<void> _fetchNotifications({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _hasError = false;
        _currentPage = 1;
      });
    }
    try {
      final page = reset ? 1 : _currentPage;
      final url = '${AppLink.notifications}?scope=mine&page=$page';
      print(  'Fetching notifications from: $url');

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      print(token);

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 30));

      final res = jsonDecode(response.body);

      if (res['success'] == true) {
        final items = (res['data']['items'] as List)
            .map((e) => NotificationModel.fromJson(e))
            .toList();
        final pagination = res['data']['pagination'];
        setState(() {
          if (reset) {
            _all.clear();
          }
          _all.addAll(items);
          _currentPage = pagination['current_page'] ?? 1;
          _lastPage = pagination['last_page'] ?? 1;
        });
      } else {
        setState(() => _hasError = true);
      }
    } catch (e) {
      setState(() => _hasError = true);
    } finally {
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _currentPage >= _lastPage) return;
    setState(() {
      _loadingMore = true;
      _currentPage++;
    });
    await _fetchNotifications();
  }

  int get _unreadCount => _all.where((n) => !n.isRead).length;

  Future<void> _refresh() async {
    await _fetchNotifications(reset: true);
  }

  void _markAllRead() {
    setState(() {
      for (final n in _all) {
        n.isRead = true;
      }
    });
  }

  void _markRead(NotificationModel n) {
    setState(() => n.isRead = true);
  }

  Future<void> _delete(NotificationModel n) async {
    if (_deletingIds.contains(n.id)) return;

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('حذف الإشعار'),
            content: const Text('هل تريد حذف هذا الإشعار؟'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Color(0xFFEF4444)),
                ),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final removedIndex = _all.indexWhere((x) => x.id == n.id);
    if (removedIndex == -1) return;

    final removedItem = _all[removedIndex];

    setState(() {
      _deletingIds.add(n.id);
      _all.removeAt(removedIndex);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token') ?? '';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      http.Response response = await http
          .delete(
            Uri.parse('${AppLink.notifications}/${n.id}'),
            headers: headers,
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 404 || response.statusCode == 405) {
        response = await http
            .post(
              Uri.parse('${AppLink.notifications}/${n.id}/delete'),
              headers: headers,
            )
            .timeout(const Duration(seconds: 30));
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Delete request failed with ${response.statusCode}');
      }

      if (response.body.isNotEmpty) {
        final body = jsonDecode(response.body);
        if (body is Map<String, dynamic> && body['success'] == false) {
          throw Exception(body['message'] ?? 'Delete request failed');
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم حذف الإشعار')),
      );
    } catch (_) {
      if (!mounted) return;

      setState(() {
        final safeIndex = removedIndex <= _all.length ? removedIndex : _all.length;
        _all.insert(safeIndex, removedItem);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تعذر حذف الإشعار'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      if (!mounted) return;
      setState(() => _deletingIds.remove(n.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _all.where((n) => !n.isRead).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          centerTitle: true,
          title: const Text(
            "الإشعارات",
            style: TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            if (_unreadCount > 0)
              TextButton(
                onPressed: _markAllRead,
                child: const Text(
                  "قراءة الكل",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  dividerColor: Colors.transparent,
                  labelColor: const Color(0xFF111827),
                  unselectedLabelColor: const Color(0xFF6B7280),
                  labelStyle: const TextStyle(fontWeight: FontWeight.w900),
                  unselectedLabelStyle:
                      const TextStyle(fontWeight: FontWeight.w800),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("الكل"),
                          const SizedBox(width: 8),
                          _pill("${_all.length}"),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("غير مقروء"),
                          const SizedBox(width: 8),
                          _pill("$_unreadCount",
                              highlight: _unreadCount > 0),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildList(_all, _allScrollController),
              _buildList(unread, _unreadScrollController),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFFEF4444) : const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: highlight ? Colors.white : const Color(0xFF111827),
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildList(List<NotificationModel> list, ScrollController scrollController) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 180),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_hasError && list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      size: 44, color: Color(0xFFEF4444)),
                  const SizedBox(height: 10),
                  const Text(
                    "فشل تحميل الإشعارات",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextButton.icon(
                    onPressed: () => _fetchNotifications(reset: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text("إعادة المحاولة"),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: const [
                  Icon(Icons.notifications_off_outlined,
                      size: 44, color: Color(0xFF6B7280)),
                  SizedBox(height: 10),
                  Text(
                    "لا توجد إشعارات",
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: Color(0xFF111827),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "عندما تصلك إشعارات ستظهر هنا.",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemCount: list.length + (_loadingMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == list.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final n = list[index];
        return _notifCard(n);
      },
    );
  }

  Widget _notifCard(NotificationModel n) {
    final meta = _typeMeta(n.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: n.isRead ? const Color(0xFFE5E7EB) : meta.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          // TODO: open details or navigate based on type
          if (!n.isRead) _markRead(n);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: meta.bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(meta.icon, color: meta.fg, size: 24),
              ),
              const SizedBox(width: 12),

              // Texts
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: meta.fg,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      n.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6B7280),
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.schedule,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 6),
                        Text(
                          _timeAgo(n.createdAt),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade700,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        if (!n.isRead)
                          TextButton(
                            onPressed: () => _markRead(n),
                            style: TextButton.styleFrom(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              minimumSize: const Size(0, 32),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: const Text(
                              "تحديد كمقروء",
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF2563EB),
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _NotifTypeMeta _typeMeta(NotificationType t) {
    switch (t) {
      case NotificationType.success:
        return _NotifTypeMeta(
          icon: Icons.check_circle_outline,
          bg: const Color(0xFFECFDF5),
          fg: const Color(0xFF10B981),
          border: const Color(0xFFB7F7DD),
        );
      case NotificationType.warning:
        return _NotifTypeMeta(
          icon: Icons.warning_amber_rounded,
          bg: const Color(0xFFFFFBEB),
          fg: const Color(0xFFF59E0B),
          border: const Color(0xFFFFE7B3),
        );
      case NotificationType.info:
      default:
        return _NotifTypeMeta(
          icon: Icons.notifications_none,
          bg: const Color(0xFFEFF6FF),
          fg: const Color(0xFF2563EB),
          border: const Color(0xFFBFD7FF),
        );
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return "منذ ${diff.inMinutes} دقيقة";
    if (diff.inHours < 24) return "منذ ${diff.inHours} ساعة";
    return "منذ ${diff.inDays} يوم";
  }
}

// ===================== Models =====================

enum NotificationType { info, success, warning }

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final DateTime createdAt;
  final Map<String, dynamic>? data;
  bool isRead;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    required this.isRead,
    this.data,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final typeStr = (json['type'] ?? 'info').toString().toLowerCase();
    NotificationType type;
    switch (typeStr) {
      case 'success':
        type = NotificationType.success;
        break;
      case 'warning':
        type = NotificationType.warning;
        break;
      default:
        type = NotificationType.info;
    }

    DateTime createdAt;
    try {
      // Format: "2026-02-24 14:09:28" — replace space with T for ISO parsing
      createdAt = DateTime.parse(
          (json['created_at'] as String).replaceFirst(' ', 'T'));
    } catch (_) {
      createdAt = DateTime.now();
    }

    return NotificationModel(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: type,
      createdAt: createdAt,
      isRead: json['is_read'] == true,
      data: json['data'] != null
          ? Map<String, dynamic>.from(json['data'])
          : null,
    );
  }
}

class _NotifTypeMeta {
  final IconData icon;
  final Color bg;
  final Color fg;
  final Color border;

  _NotifTypeMeta({
    required this.icon,
    required this.bg,
    required this.fg,
    required this.border,
  });
}