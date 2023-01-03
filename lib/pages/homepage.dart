import 'package:flutter/material.dart';
import 'package:flutter_admin_scaffold/admin_scaffold.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:jtasks/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      appBar: AppBar(
        title: const Text('JTasks'),
      ),
      sideBar: SideBar(
        backgroundColor: flexScheme(context).background,
        activeBackgroundColor: flexScheme(context).surfaceVariant,
        iconColor: flexScheme(context).secondary,
        activeIconColor: flexScheme(context).surfaceTint,
        textStyle: TextStyle(
            color: flexScheme(context).onBackground, fontFamily: GoogleFonts.notoSans().fontFamily, fontSize: 12),
        activeTextStyle: TextStyle(
            color: flexScheme(context).onPrimaryContainer, fontFamily: GoogleFonts.notoSans().fontFamily, fontSize: 12),
        items: const [
          AdminMenuItem(
            title: 'Dashboard',
            route: '/',
            icon: Icons.dashboard_rounded,
          ),
          AdminMenuItem(
            title: 'Boards',
            icon: Icons.horizontal_split_rounded,
            children: [
              AdminMenuItem(
                title: 'Koler Dev Board',
                icon: Icons.view_array_rounded,
                route: '/secondLevelItem1',
              ),
              AdminMenuItem(
                title: 'JTasks Dev Board',
                icon: Icons.view_array_rounded,
                route: '/secondLevelItem2',
              ),
            ],
          ),
        ],
        selectedRoute: '/',
        onSelected: (item) {
          if (item.route != null) {
            // Navigator.of(context).pushNamed(item.route!);
            print(item.route);
          }
        },
        header: SizedBox(
            height: 40,
            width: double.infinity,
            child: Stack(
              children: [
                const Align(
                  child: Text('Boards'),
                ),
                Positioned(
                    right: 0,
                    child: IconButton(
                        tooltip: 'Create new boards',
                        onPressed: () {
                          setState(() {
                            count++;
                          });
                        },
                        icon: const Icon(Icons.add_box_rounded)))
              ],
            )),
        footer: SizedBox(
          height: 24,
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              IconButton(
                  onPressed: () {},
                  tooltip: 'Visit official site.',
                  icon: const Icon(
                    Icons.web,
                    size: 12,
                  )),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          alignment: Alignment.topLeft,
          padding: const EdgeInsets.all(10),
          child: Text(
            '$count',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 36,
            ),
          ),
        ),
      ),
    );
  }
}
