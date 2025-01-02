import 'package:app_luyen_de_thpt/components/list_tile.dart';
import 'package:app_luyen_de_thpt/providers/auth.dart';
import 'package:app_luyen_de_thpt/screens/adminscreens.dart';
import 'package:app_luyen_de_thpt/screens/profilescreens.dart';
import 'package:app_luyen_de_thpt/screens/resultuserscreens.dart';
import 'package:app_luyen_de_thpt/screens/settingscreens.dart';
import 'package:app_luyen_de_thpt/screens/usercreens.dart';
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class Mydrawer extends StatelessWidget {
  final void Function()? onSignoutTap;
  final void Function()? onCreateTap;
  final AppUser user;

  const Mydrawer({
    super.key,
    required this.onSignoutTap,
    required this.onCreateTap,
    required this.user,
  });

  void _navigateToHome(BuildContext context) {
    Navigator.pop(context);
    if (user.isAdmin) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AdminDashboardScreen(
            admin: user,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserScreen(
            user: user,
          ),
        ),
      );
    }
  }

  void _navigateResultUser(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestResultsUserScreen(
          user: user,
          userId: user.id!,
        ),
      ),
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Profilescreens(
          user: user,
        ),
      ),
    );
  }

  void _navigateToSetting(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Settingscreens(
          user: user,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xff88976C),
      child: Column(
        children: [
          const DrawerHeader(
            child: Icon(
              Ionicons.person,
              color: Colors.white,
              size: 64,
            ),
          ),
          MyListTile(
            icon: Icons.home,
            onTap: () => _navigateToHome(context),
            title: 'H O M E',
          ),
          if (user.isAdmin)
            MyListTile(
              icon: Icons.create,
              title: 'C R E A T E',
              onTap: onCreateTap,
            ),
          if (user.isAdmin == false)
            MyListTile(
              icon: Icons.list_alt_rounded,
              title: 'M Y  R E S U L T',
              onTap: () => _navigateResultUser(context),
            ),
          MyListTile(
            icon: Icons.person,
            title: 'P R O F I L E',
            onTap: () => _navigateToProfile(context),
          ),
          MyListTile(
            icon: Icons.settings,
            title: 'S E T T I N G',
            onTap: () => _navigateToSetting(context),
          ),
          MyListTile(
            icon: Icons.close_rounded,
            onTap: () => Navigator.pop(context),
            title: 'C L O S E',
          ),
          const Spacer(),
          MyListTile(
            icon: Icons.logout,
            title: 'L O G O U T',
            onTap: onSignoutTap,
          ),
          const SizedBox(
            height: 20,
          ),
        ],
      ),
    );
  }
}
