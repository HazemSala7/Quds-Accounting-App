import 'package:flutter/material.dart';
import 'package:quds_yaghmour/Screens/notifications_page/notifications_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppBarMain extends StatefulWidget {
  const AppBarMain({Key? key}) : super(key: key);

  @override
  State<AppBarMain> createState() => _AppBarMainState();
}

class _AppBarMainState extends State<AppBarMain> {
  String type = "";

  // optional unread notifications count (set it from prefs/api later)
  int unreadCount = 0;

  Future<void> initiatePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final String _type = prefs.getString('type') ?? "quds";

    // if you have stored unread count in prefs:
    // final int _unread = prefs.getInt('unread_notifications') ?? 0;

    setState(() {
      type = _type;
      // unreadCount = _unread;
    });
  }

  @override
  void initState() {
    super.initState();
    initiatePrefs();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromRGBO(83, 89, 219, 1),
              Color.fromRGBO(32, 39, 160, 0.6),
            ],
          ),
        ),
      ),
      title: Text(
        type.toString() == "quds" ? "القدس موبايل" : "القدس موبايل Vansale",
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 17,
          color: Colors.white,
        ),
      ),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
        icon: const Icon(Icons.menu, color: Colors.white),
        iconSize: 26,
      ),

      // ✅ Notifications Icon on the other side
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: _notifAction(
            count: unreadCount,
            onTap: () {
              Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const NotificationsPage()),
);
            },
          ),
        ),
      ],
    );
  }

  Widget _notifAction({required int count, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: SizedBox(
        width: 46,
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none, color: Colors.white, size: 26),

            // ✅ Badge only if count > 0
            if (count > 0)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18),
                  child: Text(
                    count > 99 ? "99+" : "$count",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}