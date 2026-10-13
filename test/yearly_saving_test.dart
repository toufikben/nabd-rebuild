import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:nabd/services/monetization_service.dart';

ProductDetails _product(double price, {String currency = 'DZD'}) =>
    ProductDetails(
      id: 'p',
      title: 'p',
      description: '',
      price: '$price',
      rawPrice: price,
      currencyCode: currency,
    );

void main() {
  test('the saving comes from the real prices, rounded down', () {
    // The store prices that showed a hardcoded "Save 50%": really 41.97%.
    expect(
      MonetizationService.savingPercent(_product(675), _product(4700)),
      41,
    );
  });

  test('no claim without two comparable prices', () {
    expect(MonetizationService.savingPercent(null, _product(4700)), isNull);
    expect(
      MonetizationService.savingPercent(
          _product(4.99, currency: 'USD'), _product(4700)),
      isNull,
    );
    expect(MonetizationService.savingPercent(_product(0), _product(10)), isNull);
  });

  test('no claim when the yearly plan barely saves anything', () {
    expect(MonetizationService.savingPercent(_product(10), _product(118)),
        isNull);
  });
}
