import 'package:fluent_ui/fluent_ui.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return ScaffoldPage(
      header: Column(
        children: [
          Row(
            children: const [
              Divider(),
              Icon(FluentIcons.view_dashboard),
              Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text('Dashboard', style: TextStyle(fontSize: 32)),
              ),
            ],
          ),
        ],
      ),
      bottomBar: CommandBar(
        primaryItems: [
          CommandBarButton(
              onPressed: () {},
              icon: const Tooltip(message: 'Export/Import Data', child: Icon(FluentIcons.database_sync)))
        ],
      ),
    );
  }
}
