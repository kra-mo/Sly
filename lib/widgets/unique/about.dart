import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:sly/widgets/button.dart';
import '/widgets/dialog.dart';
import '/widgets/title_bar.dart';

Future<void> showSlyAboutDialog(BuildContext context) async {
  final packageInfo = await PackageInfo.fromPlatform();

  if (context.mounted) {
    showSlyDialog(context, 'About', [
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [
            Row(
              spacing: 12,
              children: [
                ImageIcon(
                  size: 96,
                  color: Colors.deepOrangeAccent,
                  AssetImage('assets/sly.webp'),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Wrap(
                        crossAxisAlignment: .center,
                        spacing: 6,
                        children: [
                          Text(
                            'Sly',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          Text(
                            '(${packageInfo.version}+${packageInfo.buildNumber})',
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ],
                      ),

                      Text(
                        'A Friendly Image Editor',
                        overflow: .ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SlyButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Column(
                    children: <Widget>[
                      Container(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        child: const SlyTitleBar(),
                      ),
                      const Expanded(
                        child: LicensePage(
                          applicationLegalese: '© 2026 The Sly Developers',
                          applicationIcon: ImageIcon(
                            size: 96,
                            color: Colors.deepOrangeAccent,
                            AssetImage('assets/sly.webp'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              child: Text('View Licenses'),
            ),
            const SizedBox(height: 4),
            const SlyCancelButton(label: 'Done', suggested: false),
          ],
        ),
      ),
    ], hideTitle: true);
  }
}
