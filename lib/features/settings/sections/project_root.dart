import 'package:fluship/shared/widgets/app_card.dart';
import 'package:flutter/material.dart';

import '../widgets/field_button.dart';

class ProjectRoot extends StatelessWidget {
  const ProjectRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Project Root',
      description:
          'Point Fluship at your Flutter app folder — the directory that contains pubspec.yaml. '
          'Build commands, config files, and artifact paths are all resolved from here.',
      children: [
        FieldButton(
          hint: 'C:/Users/Username/Desktop/flutter_project',
          label: 'Flutter project path',
          onBrowse: () {},
        ),
      ],
    );
  }
}
