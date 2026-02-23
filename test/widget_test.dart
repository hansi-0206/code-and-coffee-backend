import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:code_and_coffee/main.dart';
import 'package:code_and_coffee/providers/cart_provider.dart';
import 'package:code_and_coffee/models/menu_item.dart';

void main() {
  /// -------------------------------
  /// LOGIN SCREEN UI TESTS
  /// -------------------------------
  testWidgets('Login screen displays correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Main texts
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to continue'), findsOneWidget);

    // Role cards
    expect(find.text('Student'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
    expect(find.text('Kitchen'), findsOneWidget);

    // Input labels
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // Button
    expect(find.text('Sign In'), findsOneWidget);
  });

  testWidgets('Role selection works', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    final studentCard = find.text('Student');
    expect(studentCard, findsOneWidget);

    await tester.tap(studentCard);
    await tester.pump();
  });

  /// -------------------------------
  /// CART PROVIDER TESTS
  /// -------------------------------
  test('CartProvider adds items correctly', () {
    final cartProvider = CartProvider();
    final menuItem = MenuItem(
      id: '1',
      name: 'Cappuccino',
      category: 'Beverages',
      price: 149,
    );

    expect(cartProvider.items.length, 0);

    cartProvider.addItem(menuItem);
    expect(cartProvider.items.length, 1);
    expect(cartProvider.itemCount, 1);

    cartProvider.addItem(menuItem);
    expect(cartProvider.items.length, 1);
    expect(cartProvider.itemCount, 2);
  });

  test('CartProvider calculates totals correctly', () {
    final cartProvider = CartProvider();
    final menuItem1 = MenuItem(
      id: '1',
      name: 'Cappuccino',
      category: 'Beverages',
      price: 149,
    );
    final menuItem2 = MenuItem(
      id: '2',
      name: 'Latte',
      category: 'Beverages',
      price: 169,
    );

    cartProvider.addItem(menuItem1);
    cartProvider.addItem(menuItem2);

    expect(cartProvider.subtotal, 318);
    expect(cartProvider.tax, 31.8);
    expect(cartProvider.total, 349.8);
  });

  test('CartProvider removes items correctly', () {
    final cartProvider = CartProvider();
    final menuItem = MenuItem(
      id: '1',
      name: 'Cappuccino',
      category: 'Beverages',
      price: 149,
    );

    cartProvider.addItem(menuItem);
    cartProvider.addItem(menuItem);
    expect(cartProvider.itemCount, 2);

    cartProvider.removeItem(menuItem);
    expect(cartProvider.itemCount, 1);

    cartProvider.removeItem(menuItem);
    expect(cartProvider.itemCount, 0);
    expect(cartProvider.items.length, 0);
  });

  test('CartProvider clears cart', () {
    final cartProvider = CartProvider();
    final menuItem = MenuItem(
      id: '1',
      name: 'Cappuccino',
      category: 'Beverages',
      price: 149,
    );

    cartProvider.addItem(menuItem);
    cartProvider.addItem(menuItem);
    expect(cartProvider.items.length, 1);

    cartProvider.clear();
    expect(cartProvider.items.length, 0);
    expect(cartProvider.itemCount, 0);
  });

  /// -------------------------------
  /// MODEL TESTS
  /// -------------------------------
  test('MenuItem model converts from JSON correctly', () {
    final json = {
      '_id': '1',
      'name': 'Cappuccino',
      'category': 'Beverages',
      'price': 149,
      'description': 'Rich espresso',
      'available': true,
    };

    final menuItem = MenuItem.fromJson(json);

    expect(menuItem.id, '1');
    expect(menuItem.name, 'Cappuccino');
    expect(menuItem.category, 'Beverages');
    expect(menuItem.price, 149);
    expect(menuItem.description, 'Rich espresso');
    expect(menuItem.available, true);
  });
}
