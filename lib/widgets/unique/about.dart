import 'package:flutter/material.dart';

import '/widgets/dialog.dart';
import '/widgets/markup_text.dart';
import '/widgets/title_bar.dart';

void showSlyAboutDialog(BuildContext context) {
  showSlyDialog(
    context,
    'Sly',
    <Widget>[
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 240),
        child: Column(
          children: [
            SlyMarkupText('''
##### A Friendly Image Editor

Sly is a free and open source application licensed under
the [GPLv3](https://www.gnu.org/licenses/gpl-3.0.en.html).
The source code is available [here](https://git.kramo.page/Sly).

If you would like to support continued development
of the app, consider donating via
[GitHub Sponsors](https://github.com/sponsors/kra-mo)
or [LiberaPay](https://liberapay.com/kramo).

Licenses of other open source libraries used by the app
can be viewed [here](slycallback://0).
''', callbacks: [
              () => Navigator.push(
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
                              applicationLegalese: '© 2024 kramo',
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
                  )
            ]),
            const SizedBox(height: 12),
            const SlyCancelButton(label: 'Done', suggested: false),
          ],
        ),
      ),
    ],
  );
}
