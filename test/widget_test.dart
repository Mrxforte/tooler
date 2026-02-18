// Tooler App Integration Tests
//
// Comprehensive tests for the Tooler construction tool management application.
// These tests cover initialization, data models, and core app functionality.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tooler/main.dart';
import 'package:tooler/data/models/tool.dart';
import 'package:tooler/data/models/construction_object.dart';
import 'package:tooler/data/models/sync_item.dart';

void main() {
  // Setup and teardown for all tests
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Initialization Tests', () {
    testWidgets('MyApp builds and shows loading indicator initially', 
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());

      // Initially should show a loading indicator while SharedPreferences loads
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('MyApp shows MaterialApp after initialization', 
        (WidgetTester tester) async {
      // Build the app
      await tester.pumpWidget(const MyApp());
      
      // Wait for SharedPreferences to initialize
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // After initialization, should have MaterialApp
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });

  group('Tool Model Tests', () {
    test('Tool model creates instance with required fields', () {
      final tool = Tool(
        id: 'test-123',
        title: 'Test Drill',
        description: 'A powerful drill',
        brand: 'DeWalt',
        uniqueId: 'DRILL-001',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-123',
      );

      expect(tool.id, 'test-123');
      expect(tool.title, 'Test Drill');
      expect(tool.description, 'A powerful drill');
      expect(tool.brand, 'DeWalt');
      expect(tool.uniqueId, 'DRILL-001');
      expect(tool.currentLocation, 'garage');
      expect(tool.currentLocationName, 'Гараж');
      expect(tool.userId, 'user-123');
      expect(tool.isFavorite, false);
      expect(tool.isSelected, false);
      expect(tool.locationHistory, isEmpty);
    });

    test('Tool model serialization to JSON', () {
      final tool = Tool(
        id: 'test-123',
        title: 'Test Hammer',
        description: 'Heavy duty hammer',
        brand: 'Stanley',
        uniqueId: 'HAMMER-001',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-456',
        isFavorite: true,
      );

      final json = tool.toJson();

      expect(json['id'], 'test-123');
      expect(json['title'], 'Test Hammer');
      expect(json['description'], 'Heavy duty hammer');
      expect(json['brand'], 'Stanley');
      expect(json['uniqueId'], 'HAMMER-001');
      expect(json['currentLocation'], 'garage');
      expect(json['currentLocationName'], 'Гараж');
      expect(json['userId'], 'user-456');
      expect(json['isFavorite'], true);
      expect(json['isSelected'], false);
      expect(json['locationHistory'], isList);
    });

    test('Tool model deserialization from JSON', () {
      final json = {
        'id': 'test-789',
        'title': 'Test Screwdriver',
        'description': 'Phillips head screwdriver',
        'brand': 'Craftsman',
        'uniqueId': 'SCREW-001',
        'currentLocation': 'garage',
        'currentLocationName': 'Гараж',
        'userId': 'user-789',
        'isFavorite': true,
        'isSelected': false,
        'locationHistory': [],
        'createdAt': '2024-01-01T12:00:00.000Z',
        'updatedAt': '2024-01-01T12:00:00.000Z',
      };

      final tool = Tool.fromJson(json);

      expect(tool.id, 'test-789');
      expect(tool.title, 'Test Screwdriver');
      expect(tool.description, 'Phillips head screwdriver');
      expect(tool.brand, 'Craftsman');
      expect(tool.uniqueId, 'SCREW-001');
      expect(tool.currentLocation, 'garage');
      expect(tool.isFavorite, true);
    });

    test('Tool copyWith creates modified copy', () {
      final originalTool = Tool(
        id: 'original-1',
        title: 'Original Tool',
        description: 'Original description',
        brand: 'Original Brand',
        uniqueId: 'ORIG-001',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-1',
        isFavorite: false,
      );

      final modifiedTool = originalTool.copyWith(
        title: 'Modified Tool',
        isFavorite: true,
      );

      expect(modifiedTool.id, originalTool.id);
      expect(modifiedTool.title, 'Modified Tool');
      expect(modifiedTool.description, originalTool.description);
      expect(modifiedTool.isFavorite, true);
      expect(originalTool.isFavorite, false); // Original unchanged
    });

    test('Tool displayImage returns correct image path', () {
      // Test with imageUrl
      final toolWithUrl = Tool(
        id: '1',
        title: 'Tool',
        description: 'Desc',
        brand: 'Brand',
        uniqueId: 'ID-1',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-1',
        imageUrl: 'https://example.com/image.jpg',
      );
      expect(toolWithUrl.displayImage, 'https://example.com/image.jpg');

      // Test with localImagePath
      final toolWithLocal = Tool(
        id: '2',
        title: 'Tool',
        description: 'Desc',
        brand: 'Brand',
        uniqueId: 'ID-2',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-2',
        localImagePath: '/path/to/local/image.jpg',
      );
      expect(toolWithLocal.displayImage, '/path/to/local/image.jpg');

      // Test with no image
      final toolNoImage = Tool(
        id: '3',
        title: 'Tool',
        description: 'Desc',
        brand: 'Brand',
        uniqueId: 'ID-3',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-3',
      );
      expect(toolNoImage.displayImage, isNull);
    });
  });

  group('LocationHistory Model Tests', () {
    test('LocationHistory creates instance correctly', () {
      final history = LocationHistory(
        date: DateTime(2024, 1, 15),
        locationId: 'loc-123',
        locationName: 'Construction Site A',
      );

      expect(history.date, DateTime(2024, 1, 15));
      expect(history.locationId, 'loc-123');
      expect(history.locationName, 'Construction Site A');
    });

    test('LocationHistory serialization to JSON', () {
      final history = LocationHistory(
        date: DateTime(2024, 1, 15, 10, 30),
        locationId: 'loc-456',
        locationName: 'Garage',
      );

      final json = history.toJson();

      expect(json['date'], isA<String>());
      expect(json['locationId'], 'loc-456');
      expect(json['locationName'], 'Garage');
    });

    test('LocationHistory deserialization from JSON', () {
      final json = {
        'date': '2024-01-15T10:30:00.000Z',
        'locationId': 'loc-789',
        'locationName': 'Site B',
      };

      final history = LocationHistory.fromJson(json);

      expect(history.locationId, 'loc-789');
      expect(history.locationName, 'Site B');
      expect(history.date, isA<DateTime>());
    });
  });

  group('ConstructionObject Model Tests', () {
    test('ConstructionObject creates instance correctly', () {
      final constructionObject = ConstructionObject(
        id: 'obj-123',
        name: 'Building A',
        description: 'Main construction site',
        userId: 'user-123',
      );

      expect(constructionObject.id, 'obj-123');
      expect(constructionObject.name, 'Building A');
      expect(constructionObject.description, 'Main construction site');
      expect(constructionObject.userId, 'user-123');
    });

    test('ConstructionObject serialization to JSON', () {
      final constructionObject = ConstructionObject(
        id: 'obj-456',
        name: 'Site B',
        description: 'Secondary site',
        userId: 'user-456',
      );

      final json = constructionObject.toJson();

      expect(json['id'], 'obj-456');
      expect(json['name'], 'Site B');
      expect(json['description'], 'Secondary site');
      expect(json['userId'], 'user-456');
      expect(json['createdAt'], isA<String>());
      expect(json['updatedAt'], isA<String>());
    });

    test('ConstructionObject deserialization from JSON', () {
      final json = {
        'id': 'obj-789',
        'name': 'Site C',
        'description': 'Third construction site',
        'userId': 'user-789',
        'createdAt': '2024-01-01T12:00:00.000Z',
        'updatedAt': '2024-01-01T12:00:00.000Z',
      };

      final constructionObject = ConstructionObject.fromJson(json);

      expect(constructionObject.id, 'obj-789');
      expect(constructionObject.name, 'Site C');
      expect(constructionObject.description, 'Third construction site');
      expect(constructionObject.userId, 'user-789');
    });

    test('ConstructionObject copyWith creates modified copy', () {
      final original = ConstructionObject(
        id: 'obj-1',
        name: 'Original Site',
        description: 'Original description',
        userId: 'user-1',
      );

      final modified = original.copyWith(
        name: 'Modified Site',
        description: 'Modified description',
      );

      expect(modified.id, original.id);
      expect(modified.name, 'Modified Site');
      expect(modified.description, 'Modified description');
      expect(modified.userId, original.userId);
      expect(original.name, 'Original Site'); // Original unchanged
    });
  });

  group('SyncItem Model Tests', () {
    test('SyncItem creates instance correctly', () {
      final syncItem = SyncItem(
        id: 'sync-123',
        action: 'create',
        collection: 'tools',
        data: {'title': 'Test Tool'},
        timestamp: DateTime(2024, 1, 15),
      );

      expect(syncItem.id, 'sync-123');
      expect(syncItem.action, 'create');
      expect(syncItem.collection, 'tools');
      expect(syncItem.data['title'], 'Test Tool');
      expect(syncItem.timestamp, DateTime(2024, 1, 15));
    });

    test('SyncItem serialization to JSON', () {
      final syncItem = SyncItem(
        id: 'sync-456',
        action: 'update',
        collection: 'objects',
        data: {'name': 'Site A'},
        timestamp: DateTime(2024, 1, 15, 10, 30),
      );

      final json = syncItem.toJson();

      expect(json['id'], 'sync-456');
      expect(json['action'], 'update');
      expect(json['collection'], 'objects');
      expect(json['data'], isA<Map>());
      expect(json['timestamp'], isA<String>());
    });

    test('SyncItem with different actions', () {
      final actions = ['create', 'update', 'delete'];

      for (final action in actions) {
        final syncItem = SyncItem(
          id: 'sync-$action',
          action: action,
          collection: 'tools',
          data: {},
          timestamp: DateTime.now(),
        );

        expect(syncItem.action, action);
      }
    });
  });

  group('App Widget Structure Tests', () {
    testWidgets('App uses MaterialApp with correct configuration', 
        (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find MaterialApp
      final materialAppFinder = find.byType(MaterialApp);
      expect(materialAppFinder, findsOneWidget);

      // Get MaterialApp widget
      final MaterialApp materialApp = tester.widget(materialAppFinder);

      // Verify debug banner is disabled
      expect(materialApp.debugShowCheckedModeBanner, false);
      
      // Verify theme is configured
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });
  });

  group('Data Validation Tests', () {
    test('Tool requires non-null essential fields', () {
      expect(
        () => Tool(
          id: 'test-1',
          title: 'Test Tool',
          description: 'Test description',
          brand: 'Test Brand',
          uniqueId: 'TEST-001',
          currentLocation: 'garage',
          currentLocationName: 'Гараж',
          userId: 'user-1',
        ),
        returnsNormally,
      );
    });

    test('Tool handles empty location history', () {
      final tool = Tool(
        id: 'test-2',
        title: 'Test Tool',
        description: 'Test description',
        brand: 'Test Brand',
        uniqueId: 'TEST-002',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-2',
      );

      expect(tool.locationHistory, isEmpty);
      expect(tool.locationHistory, isA<List<LocationHistory>>());
    });

    test('Tool handles location history additions', () {
      final tool = Tool(
        id: 'test-3',
        title: 'Test Tool',
        description: 'Test description',
        brand: 'Test Brand',
        uniqueId: 'TEST-003',
        currentLocation: 'garage',
        currentLocationName: 'Гараж',
        userId: 'user-3',
        locationHistory: [
          LocationHistory(
            date: DateTime(2024, 1, 1),
            locationId: 'garage',
            locationName: 'Гараж',
          ),
          LocationHistory(
            date: DateTime(2024, 1, 15),
            locationId: 'site-1',
            locationName: 'Site A',
          ),
        ],
      );

      expect(tool.locationHistory.length, 2);
      expect(tool.locationHistory[0].locationName, 'Гараж');
      expect(tool.locationHistory[1].locationName, 'Site A');
    });
  });
}
