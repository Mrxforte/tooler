import 'package:flutter/material.dart';
import '../../../data/models/tool.dart';
import 'move_tools_screen.dart';

void showMoveToolsScreen(BuildContext context, List<Tool> selectedTools) async {
  await Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => MoveToolsScreen(selectedTools: selectedTools),
    ),
  );
}
