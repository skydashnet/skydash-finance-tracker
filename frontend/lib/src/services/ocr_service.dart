import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';

class OcrService {
  final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final _logger = Logger();

  Future<Map<String, dynamic>> scanImage(XFile imageFile) async {
    try {
      final inputImage = InputImage.fromFilePath(imageFile.path);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);

      final String rawText = recognizedText.text;
      _logger.d("--- OCR Raw Text ---\n$rawText\n--------------------");
      final extractedData = _extractData(rawText);
      _logger.i("Extracted Data: $extractedData");
      
      return extractedData;

    } catch (e) {
      _logger.e("Error during OCR processing: $e");
      return {};
    } finally {
    }
  }

  Map<String, dynamic> _extractData(String text) {
    return {
      'amount': _extractTotalAmount(text),
      'description': _extractMerchantName(text),
      'date': _extractDate(text),
    };
  }

  String? _extractMerchantName(String text) {
    final lines = text.split('\n');
    if (lines.isNotEmpty) {
      return lines.firstWhere((line) => line.trim().isNotEmpty, orElse: () => '').trim();
    }
    return null;
  }

  DateTime? _extractDate(String text) {
    final datePatterns = {
      RegExp(r'\b(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})\b'): 'dd/MM/yyyy',
      RegExp(r'\b(\d{1,2})\s(Jan|Feb|Mar|Apr|Mei|Jun|Jul|Ags|Sep|Okt|Nov|Des)\s(\d{2,4})\b', caseSensitive: false): 'd MMM yyyy',
    };
    
    for (var entry in datePatterns.entries) {
      final match = entry.key.firstMatch(text);
      if (match != null) {
        try {
          String dateString = match.group(0)!;
          return DateFormat(entry.value, 'id_ID').parse(dateString);
        } catch (e) {
          _logger.w('Failed to parse date string: ${match.group(0)} with format ${entry.value}');
          continue;
        }
      }
    }
    return null;
  }

  double? _extractTotalAmount(String text) {
    final keywords = [
      'total', 'tagihan', 'total bayar', 'total belanja',
      'jumlah', 'subtotal', 'total amount'
    ];
    final exclusionKeywords = ['tunai', 'cash', 'kembali', 'change'];

    double? bestGuess;
    final lines = text.toLowerCase().split('\n');
    for (final line in lines.reversed) {
      if (exclusionKeywords.any((ex) => line.contains(ex))) {
        continue;
      }

      if (keywords.any((key) => line.contains(key))) {
        final numbers = _findNumbersInLine(line);
        if (numbers.isNotEmpty) {
          final largestNumber = numbers.reduce((a, b) => a > b ? a : b);
          bestGuess = largestNumber;
          _logger.i('Found potential total: $bestGuess on line: "$line"');
          return bestGuess;
        }
      }
    }
    if (bestGuess == null) {
      _logger.w('No keywords found. Falling back to largest number heuristic.');
      final allNumbers = _findNumbersInLine(text.toLowerCase());
      if (allNumbers.isNotEmpty) {
        bestGuess = allNumbers.reduce((a, b) => a > b ? a : b);
      }
    }

    return bestGuess;
  }
  
  List<double> _findNumbersInLine(String line) {
    final regex = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{1,2})?|\d+(?:[.,]\d{1,2})?)');
    final matches = regex.allMatches(line);
    final List<double> numbers = [];

    for (final match in matches) {
      String numberString = match.group(0)!
          .replaceAll(RegExp(r'\.(?=\d{3})'), '')
          .replaceAll(',', '.');
      
      double? amount = double.tryParse(numberString);
      if (amount != null) {
        numbers.add(amount);
      }
    }
    return numbers;
  }
}