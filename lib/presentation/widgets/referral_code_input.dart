import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/services/affiliate_service.dart';
import '../../data/services/telemetry_service.dart';

/// Widget pour saisir manuellement un code parrain/affilié
/// 
/// Règles V2.2 :
/// - Fallback si le deep link échoue
/// - Validation en temps réel
/// - Format : LETTRES-CHIFFRES (ex: YOUTUBER-123)
/// - Optionnel (peut être laissé vide)
class ReferralCodeInput extends StatefulWidget {
  final AffiliateService affiliateService;
  final void Function(String? code)? onCodeValidated;
  final String? initialCode;
  
  const ReferralCodeInput({
    super.key,
    required this.affiliateService,
    this.onCodeValidated,
    this.initialCode,
  });

  @override
  State<ReferralCodeInput> createState() => _ReferralCodeInputState();
}

class _ReferralCodeInputState extends State<ReferralCodeInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  
  bool _isValidating = false;
  bool? _isValid;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    if (widget.initialCode != null) {
      _controller.text = widget.initialCode!;
      _validateCode(widget.initialCode!);
    }
    
    _controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    final text = _controller.text.trim().toUpperCase();
    
    if (text.isEmpty) {
      setState(() {
        _isValid = null;
        _errorMessage = null;
      });
      widget.onCodeValidated?.call(null);
      return;
    }
    
    // Validation en temps réel (format basique)
    if (text.length >= 3) {
      _validateCode(text);
    }
  }
  
  Future<void> _validateCode(String code) async {
    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });
    
    try {
      // Vérification du format
      if (!_isValidFormat(code)) {
        setState(() {
          _isValid = false;
          _errorMessage = 'Format invalide (ex: YOUTUBER-123)';
          _isValidating = false;
        });
        widget.onCodeValidated?.call(null);
        return;
      }
      
      // Vérification en base de données (optionnel)
      // Pour l'instant, on accepte tous les codes au bon format
      // TODO: Ajouter une requête Supabase pour vérifier si le code existe
      
      setState(() {
        _isValid = true;
        _isValidating = false;
      });
      
      widget.onCodeValidated?.call(code);
      
      TelemetryService.logInfo('Code parrain validé: $code');
    } catch (e) {
      setState(() {
        _isValid = false;
        _errorMessage = 'Erreur de validation';
        _isValidating = false;
      });
      
      widget.onCodeValidated?.call(null);
      
      TelemetryService.logError('Erreur validation code parrain', e);
    }
  }
  
  bool _isValidFormat(String code) {
    // Format attendu : LETTRES-CHIFFRES ou juste LETTRES ou CHIFFRES
    // Exemples valides : YOUTUBER-123, JOHN-456, ABC123, TECH2024
    
    if (code.length < 3 || code.length > 30) return false;
    
    // Autoriser lettres, chiffres et tirets
    final validChars = RegExp(r'^[A-Z0-9\-]+$');
    return validChars.hasMatch(code);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        const Text(
          'Code parrain ou affilié',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Input field
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: 'Ex: YOUTUBER-123 (optionnel)',
            prefixIcon: Icon(
              _isValid == true
                  ? Icons.check_circle
                  : _isValid == false
                      ? Icons.error
                      : Icons.card_giftcard,
              color: _isValid == true
                  ? Colors.green
                  : _isValid == false
                      ? Colors.red
                      : Colors.grey,
            ),
            suffixIcon: _isValidating
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _focusNode.unfocus();
                        },
                      )
                    : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid == true
                    ? Colors.green
                    : _isValid == false
                        ? Colors.red
                        : Colors.grey.shade300,
                width: 2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid == true
                    ? Colors.green
                    : _isValid == false
                        ? Colors.red
                        : Colors.grey.shade300,
                width: 2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: _isValid == true
                    ? Colors.green
                    : _isValid == false
                        ? Colors.red
                        : const Color(0xFF1A237E),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            // Tout en majuscules
            TextInputFormatter.withFunction(
              (oldValue, newValue) => newValue.copyWith(
                text: newValue.text.toUpperCase(),
              ),
            ),
            // Limiter à 30 caractères
            LengthLimitingTextInputFormatter(30),
            // Autoriser seulement lettres, chiffres et tirets
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9\-]')),
          ],
          keyboardType: TextInputType.text,
          textInputAction: TextInputAction.done,
        ),
        
        // Message d'erreur ou d'aide
        if (_errorMessage != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_isValid == true) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Code valide ! Vous bénéficierez des avantages.',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ] else if (_controller.text.isEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.grey.shade600, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Optionnel : Si un ami vous a invité, entrez son code ici.',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
        
        // Bonus : Afficher les avantages si code valide
        if (_isValid == true) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.celebration, color: Colors.green, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    '🎁 Bonus : 3 rapports gratuits !',
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}



