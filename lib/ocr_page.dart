import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

import 'transaction_parser.dart';
import 'data/expense_store.dart';
import 'models/expense.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});

  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> {
  final ImagePicker _picker = ImagePicker();

  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  File? selectedImage;
  String extractedText = '';
  bool isProcessing = false;

  TransactionDetails? transactionDetails;

  bool transactionConfirmed = false;

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
    );

    if (image == null) {
      return;
    }

    setState(() {
      selectedImage = File(image.path);
      extractedText = '';
      transactionDetails = null;
      transactionConfirmed = false;
      isProcessing = true;
    });

    await processImage(image.path);
  }

  // ============================================================
  // PROCESS IMAGE WITH ML KIT
  // ============================================================

  Future<void> processImage(String imagePath) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);

      final RecognizedText recognizedText =
          await _textRecognizer.processImage(inputImage);

      final details = parseTransactionText(recognizedText.text);

      if (!mounted) return;

      setState(() {
        extractedText = recognizedText.text;
        transactionDetails = details;
        isProcessing = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        extractedText = 'Unable to process this image.';
        transactionDetails = null;
        isProcessing = false;
      });
    }
  }

  // ============================================================
  // EDIT TRANSACTION
  // ============================================================

  void _editTransaction() {
    if (transactionDetails == null) return;

    final amountController = TextEditingController(
      text: transactionDetails!.amount,
    );

    final merchantController = TextEditingController(
      text: transactionDetails!.merchant,
    );

    final dateController = TextEditingController(
      text: transactionDetails!.date,
    );

    final timeController = TextEditingController(
      text: transactionDetails!.time,
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text(
            'Edit Transaction',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF17131F),
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '₹ ',
                    labelStyle: const TextStyle(
                      color: Color(0xFF77727F),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C3EF4),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: merchantController,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: 'Merchant',
                    labelStyle: const TextStyle(
                      color: Color(0xFF77727F),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C3EF4),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: dateController,
                  decoration: InputDecoration(
                    labelText: 'Date',
                    labelStyle: const TextStyle(
                      color: Color(0xFF77727F),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C3EF4),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                TextField(
                  controller: timeController,
                  decoration: InputDecoration(
                    labelText: 'Time',
                    labelStyle: const TextStyle(
                      color: Color(0xFF77727F),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF6C3EF4),
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(
            16,
            0,
            16,
            16,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Color(0xFF77727F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                setState(() {
                  transactionDetails = TransactionDetails(
                    amount: amountController.text.trim(),
                    merchant: merchantController.text.trim(),
                    date: dateController.text.trim(),
                    time: timeController.text.trim(),
                    paymentMethod:
                        transactionDetails!.paymentMethod,
                  );
                });

                Navigator.pop(dialogContext);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C3EF4),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Changes',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // CONFIRM TRANSACTION
  // ============================================================

  void _confirmTransaction() {
    if (transactionDetails == null) return;

    final amountText = transactionDetails!.amount
        .replaceAll(',', '')
        .replaceAll('₹', '')
        .trim();

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not detect a valid transaction amount.'),
        ),
      );
      return;
    }

    final merchant = transactionDetails!.merchant.trim();

    expenseStore.addExpense(
      Expense(
        amount: amount,
        description: merchant.isEmpty ? 'UPI Transaction' : merchant,
        category: 'Other',
        date: DateTime.now(),
      ),
    );

    setState(() {
      transactionConfirmed = true;
    });
  }

  // ============================================================
  // START NEW SCAN
  // ============================================================

  void _startNewScan() {
    setState(() {
      selectedImage = null;
      extractedText = '';
      transactionDetails = null;
      transactionConfirmed = false;
      isProcessing = false;
    });
  }

  // ============================================================
  // DETAIL ROW
  // ============================================================

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF77727F),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF17131F),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUCCESS SCREEN
  // ============================================================

  Widget _buildSuccessScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: const BoxDecoration(
                color: Color(0xFFF0EAFF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                size: 55,
                color: Color(0xFF6C3EF4),
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Transaction Saved!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Color(0xFF17131F),
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Your transaction has been confirmed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF77727F),
              ),
            ),

            const SizedBox(height: 30),

            if (transactionDetails != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F3FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      transactionDetails!.amount.isEmpty
                          ? 'Amount not detected'
                          : '₹${transactionDetails!.amount}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6C3EF4),
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      transactionDetails!.merchant.isEmpty
                          ? 'Merchant not detected'
                          : transactionDetails!.merchant,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF17131F),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: _startNewScan,
                icon: const Icon(Icons.document_scanner_outlined),
                label: const Text(
                  'Scan Another Transaction',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C3EF4),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _textRecognizer.close();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF17131F),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),

        title: const Text(
          'Scan UPI Screenshot',
          style: TextStyle(
            color: Color(0xFF17131F),
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: SafeArea(
        child: transactionConfirmed
            ? _buildSuccessScreen()
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,

                  children: [
                    const SizedBox(height: 20),

                    // ==================================================
                    // INITIAL STATE
                    // ==================================================

                    if (selectedImage == null) ...[
                      Container(
                        width: 280,
                        height: 280,

                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F0FF),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: const Color(0xFFE4D9FF),
                          ),
                        ),

                        child: const Center(
                          child: Icon(
                            Icons.document_scanner_outlined,
                            size: 80,
                            color: Color(0xFF6C3EF4),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      const Text(
                        'Scan your UPI screenshot',
                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF17131F),
                        ),
                      ),

                      const SizedBox(height: 12),

                      const Text(
                        'Upload a payment screenshot and we’ll '
                        'automatically extract the transaction details.',

                        textAlign: TextAlign.center,

                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF77727F),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],

                    // ==================================================
                    // IMAGE + OCR RESULT
                    // ==================================================

                    if (selectedImage != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),

                        child: Image.file(
                          selectedImage!,
                          width: double.infinity,
                          height: 300,
                          fit: BoxFit.contain,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // =================================================
                      // PROCESSING
                      // =================================================

                      if (isProcessing) ...[
                        const CircularProgressIndicator(
                          color: Color(0xFF6C3EF4),
                        ),

                        const SizedBox(height: 16),

                        const Text(
                          'Reading your screenshot...',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF77727F),
                          ),
                        ),
                      ],

                      // =================================================
                      // TRANSACTION RESULT
                      // =================================================

                      if (!isProcessing &&
                          transactionDetails != null) ...[
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,

                              decoration: const BoxDecoration(
                                color: Color(0xFFF0EAFF),
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.check_rounded,
                                color: Color(0xFF6C3EF4),
                                size: 25,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Transaction Extracted!',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF17131F),
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  Text(
                                    'Please confirm the details before saving.',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF77727F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ==============================================
                        // DETAILS CARD
                        // ==============================================

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),

                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),

                            border: Border.all(
                              color: const Color(0xFFE8E1F5),
                            ),

                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: 0.04,
                                ),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),

                          child: Column(
                            children: [
                              _detailRow(
                                'Amount',
                                transactionDetails!.amount.isEmpty
                                    ? 'Not detected'
                                    : '₹${transactionDetails!.amount}',
                              ),

                              const Divider(
                                color: Color(0xFFEDE8F5),
                              ),

                              _detailRow(
                                'Merchant',
                                transactionDetails!.merchant.isEmpty
                                    ? 'Not detected'
                                    : transactionDetails!.merchant,
                              ),

                              const Divider(
                                color: Color(0xFFEDE8F5),
                              ),

                              _detailRow(
                                'Date',
                                transactionDetails!.date.isEmpty
                                    ? 'Not detected'
                                    : transactionDetails!.date,
                              ),

                              const Divider(
                                color: Color(0xFFEDE8F5),
                              ),

                              _detailRow(
                                'Time',
                                transactionDetails!.time.isEmpty
                                    ? 'Not detected'
                                    : transactionDetails!.time,
                              ),

                              const Divider(
                                color: Color(0xFFEDE8F5),
                              ),

                              _detailRow(
                                'Payment Method',
                                transactionDetails!.paymentMethod,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ==============================================
                        // EDIT DETAILS
                        // ==============================================

                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: OutlinedButton(
                            onPressed: _editTransaction,

                            style: OutlinedButton.styleFrom(
                              foregroundColor:
                                  const Color(0xFF6C3EF4),

                              side: const BorderSide(
                                color: Color(0xFF6C3EF4),
                              ),

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),

                            child: const Text(
                              'Edit Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // ==============================================
                        // CONFIRM
                        // ==============================================

                        SizedBox(
                          width: double.infinity,
                          height: 54,

                          child: ElevatedButton(
                            onPressed: _confirmTransaction,

                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF6C3EF4),

                              foregroundColor: Colors.white,

                              elevation: 0,

                              shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(15),
                              ),
                            ),

                            child: const Text(
                              'Confirm Transaction',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                      ],
                    ],

                    // ==================================================
                    // UPLOAD / CHOOSE ANOTHER IMAGE
                    // ==================================================

                    SizedBox(
                      width: double.infinity,
                      height: 54,

                      child: ElevatedButton.icon(
                        onPressed: pickImage,

                        icon: const Icon(
                          Icons.upload_rounded,
                        ),

                        label: Text(
                          selectedImage == null
                              ? 'Upload UPI Screenshot'
                              : 'Choose Another Image',

                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color(0xFF6C3EF4),

                          foregroundColor: Colors.white,

                          elevation: 0,

                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }
}