import 'package:flutter_test/flutter_test.dart';
import 'package:shop/utils/number_to_words.dart';

void main() {
  group('NumberToWords Converter Tests', () {
    test('Converts round numbers to words', () {
      expect(
        NumberToWords.convert(1000),
        'One Thousand Rupees Only',
      );
      expect(
        NumberToWords.convert(15250),
        'Fifteen Thousand Two Hundred Fifty Rupees Only',
      );
    });

    test('Converts lakhs and crores', () {
      expect(
        NumberToWords.convert(100000),
        'One Lakh Rupees Only',
      );
      expect(
        NumberToWords.convert(1234567),
        'Twelve Lakh Thirty Four Thousand Five Hundred Sixty Seven Rupees Only',
      );
      expect(
        NumberToWords.convert(15000000),
        'One Crore Fifty Lakh Rupees Only',
      );
    });

    test('Converts numbers with decimal paise', () {
      expect(
        NumberToWords.convert(120.50),
        'One Hundred Twenty Rupees and Fifty Paise Only',
      );
      expect(
        NumberToWords.convert(0.75),
        'Seventy Five Paise Only',
      );
    });

    test('Zero returns default wording', () {
      expect(
        NumberToWords.convert(0),
        'Zero Rupees Only',
      );
    });
  });
}
