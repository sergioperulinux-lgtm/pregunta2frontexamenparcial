// widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alzheimer_classifier/main.dart'; // coincide con pubspec.yaml

import 'package:alzheimer_classifier/screens/home_screen.dart'; // import necesario para HomeScreen

void main() {
  testWidgets('AlzheimerApp se carga correctamente', (WidgetTester tester) async {
    // Construir el widget principal
    await tester.pumpWidget(const AlzheimerApp());

    // Verificar que existe un MaterialApp
    expect(find.byType(MaterialApp), findsOneWidget);

    // Verificar que la pantalla principal (HomeScreen) se muestra
    expect(find.byType(HomeScreen), findsOneWidget);
  });
}