import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/errors/app_exception.dart';
import 'telemetry_service.dart';

/// Service pour générer et partager des PDF de factures
class PdfService {
  /// Générer un PDF de facture depuis les données d'un job
  Future<Uint8List> generateInvoicePdf({
    required Map<String, dynamic> jobData,
    required Map<String, dynamic> companyData,
    String? invoiceNumber,
  }) async {
    try {
      TelemetryService.logInfo('Generating invoice PDF');
      
      final pdf = pw.Document();
      
      // Charger une police
      final font = await PdfGoogleFonts.robotoRegular();
      final fontBold = await PdfGoogleFonts.robotoBold();
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          theme: pw.ThemeData.withFont(
            base: font,
            bold: fontBold,
          ),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête avec logo et infos entreprise
              _buildHeader(companyData),
              
              pw.SizedBox(height: 30),
              
              // Titre FACTURE
              pw.Center(
                child: pw.Text(
                  'FACTURE',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              
              pw.SizedBox(height: 10),
              
              // Numéro de facture et date
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'N° ${invoiceNumber ?? 'DRAFT-${DateTime.now().millisecondsSinceEpoch}'}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                  pw.Text(
                    'Date: ${_formatDate(DateTime.now())}',
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
              
              pw.SizedBox(height: 30),
              
              // Informations client
              _buildClientInfo(jobData),
              
              pw.SizedBox(height: 30),
              
              // Tableau des produits/services
              _buildProductsTable(jobData),
              
              pw.SizedBox(height: 20),
              
              // Total
              _buildTotalSection(jobData),
              
              pw.Spacer(),
              
              // Notes et conditions
              if (jobData['notes'] != null && (jobData['notes'] as String).isNotEmpty) ...[
                pw.Text(
                  'Notes:',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  jobData['notes'] as String,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 15),
              ],
              
              // Pied de page
              _buildFooter(companyData),
            ],
          ),
        ),
      );
      
      final pdfBytes = await pdf.save();
      TelemetryService.logInfo('Invoice PDF generated (${pdfBytes.length} bytes)');
      
      return pdfBytes;
    } catch (e, stack) {
      TelemetryService.logError('Error generating PDF', e, stack);
      throw AppStorageException(
        message: 'Impossible de générer le PDF: $e',
        code: 'PDF_GENERATION_ERROR',
      );
    }
  }

  /// En-tête du PDF avec logo et infos entreprise
  pw.Widget _buildHeader(Map<String, dynamic> companyData) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo (si disponible)
        pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey400),
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Center(
            child: pw.Text(
              'LOGO',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ),
        
        // Infos entreprise
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              companyData['name'] ?? 'Entreprise',
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 4),
            if (companyData['address'] != null)
              pw.Text(
                companyData['address'] as String,
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (companyData['phone'] != null)
              pw.Text(
                'Tél: ${companyData['phone']}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (companyData['email'] != null)
              pw.Text(
                'Email: ${companyData['email']}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            if (companyData['siret'] != null)
              pw.Text(
                'SIRET: ${companyData['siret']}',
                style: const pw.TextStyle(fontSize: 10),
              ),
          ],
        ),
      ],
    );
  }

  /// Section informations client
  pw.Widget _buildClientInfo(Map<String, dynamic> jobData) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Facturé à:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            jobData['client_name'] ?? 'Client',
            style: const pw.TextStyle(fontSize: 14),
          ),
          if (jobData['address'] != null) ...[
            pw.SizedBox(height: 4),
            pw.Text(
              jobData['address'] as String,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  /// Tableau des produits/services
  pw.Widget _buildProductsTable(Map<String, dynamic> jobData) {
    final products = (jobData['products'] as List?) ?? [];
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
        4: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _tableCell('Désignation', isHeader: true),
            _tableCell('Quantité', isHeader: true),
            _tableCell('Unité', isHeader: true),
            _tableCell('Prix Unit.', isHeader: true),
            _tableCell('Total HT', isHeader: true),
          ],
        ),
        
        // Lignes de produits
        ...products.map((product) {
          final quantity = product['quantite'] as num? ?? 0;
          final unitPrice = product['prix_unitaire'] as num? ?? 0;
          final total = quantity * unitPrice;
          
          return pw.TableRow(
            children: [
              _tableCell(product['nom'] ?? ''),
              _tableCell(quantity.toString()),
              _tableCell(product['unite'] ?? ''),
              _tableCell('${unitPrice.toStringAsFixed(2)} €'),
              _tableCell('${total.toStringAsFixed(2)} €'),
            ],
          );
        }),
      ],
    );
  }

  /// Cellule de tableau
  pw.Widget _tableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  /// Section total avec détails TVA
  pw.Widget _buildTotalSection(Map<String, dynamic> jobData) {
    final products = (jobData['products'] as List?) ?? [];
    final totalHt = products.fold<double>(0.0, (sum, product) {
      final quantity = (product['quantite'] as num?) ?? 0;
      final unitPrice = (product['prix_unitaire'] as num?) ?? 0;
      return sum + (quantity * unitPrice);
    });
    
    final tvaRate = 0.20; // 20% TVA
    final tvAmount = totalHt * tvaRate;
    final totalTtc = totalHt + tvAmount;
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _totalRow('Total HT', '${totalHt.toStringAsFixed(2)} €'),
          pw.Divider(),
          _totalRow('TVA (20%)', '${tvAmount.toStringAsFixed(2)} €'),
          pw.Divider(thickness: 2),
          _totalRow(
            'Total TTC',
            '${totalTtc.toStringAsFixed(2)} €',
            isTotal: true,
          ),
        ],
      ),
    );
  }

  /// Ligne de total
  pw.Widget _totalRow(String label, String value, {bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: isTotal ? 16 : 12,
            fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  /// Pied de page avec conditions de paiement
  pw.Widget _buildFooter(Map<String, dynamic> companyData) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        pw.Text(
          'Conditions de paiement: ${companyData['payment_terms'] ?? 'À réception'}',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Pénalités de retard: 3 fois le taux d\'intérêt légal',
          style: const pw.TextStyle(fontSize: 9),
        ),
        pw.Text(
          'Indemnité forfaitaire pour frais de recouvrement: 40€',
          style: const pw.TextStyle(fontSize: 9),
        ),
      ],
    );
  }

  /// Formater une date
  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  /// Partager le PDF par email, WhatsApp, etc.
  Future<void> sharePdf(Uint8List pdfBytes, String fileName) async {
    try {
      TelemetryService.logInfo('Sharing PDF: $fileName');
      
      // Sauvegarder temporairement
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      // Partager
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Facture SiteVoice AI',
        text: 'Voici votre facture en pièce jointe.',
      );
      
      TelemetryService.logInfo('PDF shared successfully');
    } catch (e, stack) {
      TelemetryService.logError('Error sharing PDF', e, stack);
      throw AppStorageException(
        message: 'Impossible de partager le PDF: $e',
        code: 'PDF_SHARE_ERROR',
      );
    }
  }

  /// Imprimer le PDF
  Future<void> printPdf(Uint8List pdfBytes) async {
    try {
      TelemetryService.logInfo('Printing PDF');
      
      await Printing.layoutPdf(
        onLayout: (format) async => pdfBytes,
      );
      
      TelemetryService.logInfo('PDF printed successfully');
    } catch (e, stack) {
      TelemetryService.logError('Error printing PDF', e, stack);
      throw AppStorageException(
        message: 'Impossible d\'imprimer le PDF: $e',
        code: 'PDF_PRINT_ERROR',
      );
    }
  }

  /// Prévisualiser le PDF
  Future<void> previewPdf(Uint8List pdfBytes, String title) async {
    try {
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '$title.pdf',
      );
    } catch (e, stack) {
      TelemetryService.logError('Error previewing PDF', e, stack);
      rethrow;
    }
  }
}

