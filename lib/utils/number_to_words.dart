class NumberToWords {
  static const List<String> _ones = [
    "", "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten",
    "Eleven", "Twelve", "Thirteen", "Fourteen", "Fifteen", "Sixteen", "Seventeen", "Eighteen", "Nineteen"
  ];

  static const List<String> _tens = [
    "", "", "Twenty", "Thirty", "Forty", "Fifty", "Sixty", "Seventy", "Eighty", "Ninety"
  ];

  /// Converts a double value representation of money into Indian numbering system words format.
  /// Example: 15230.50 -> "Fifteen Thousand Two Hundred Thirty Rupees and Fifty Paise Only"
  static String convert(double number) {
    if (number <= 0) return "Zero Rupees Only";
    
    // Split into rupees and paise
    int amount = number.floor();
    int paise = ((number - amount) * 100).round();
    
    String rupeeWords = _convertInteger(amount);
    String paiseWords = paise > 0 ? " and ${_convertInteger(paise)} Paise" : "";
    
    if (rupeeWords.isEmpty) {
      if (paiseWords.isNotEmpty) {
        // e.g. "Fifty Paise Only"
        return "${paiseWords.replaceFirst(" and ", "")} Only";
      }
      return "Zero Rupees Only";
    }
    
    return "$rupeeWords Rupees$paiseWords Only";
  }

  static String _convertInteger(int number) {
    if (number == 0) return "";
    
    if (number < 20) {
      return _ones[number];
    }
    
    if (number < 100) {
      return "${_tens[number ~/ 10]} ${_ones[number % 10]}".trim();
    }
    
    if (number < 1000) {
      String sub = _convertInteger(number % 100);
      String separator = sub.isNotEmpty ? " " : "";
      return "${_ones[number ~/ 100]} Hundred$separator$sub".trim();
    }
    
    if (number < 100000) { // Under 1 Lakh (1,00,000)
      String sub = _convertInteger(number % 1000);
      String separator = sub.isNotEmpty ? " " : "";
      return "${_convertInteger(number ~/ 1000)} Thousand$separator$sub".trim();
    }
    
    if (number < 10000000) { // Under 1 Crore (1,00,000,00)
      String sub = _convertInteger(number % 100000);
      String separator = sub.isNotEmpty ? " " : "";
      return "${_convertInteger(number ~/ 100000)} Lakh$separator$sub".trim();
    }
    
    // Above or equal 1 Crore
    String sub = _convertInteger(number % 10000000);
    String separator = sub.isNotEmpty ? " " : "";
    return "${_convertInteger(number ~/ 10000000)} Crore$separator$sub".trim();
  }
}
