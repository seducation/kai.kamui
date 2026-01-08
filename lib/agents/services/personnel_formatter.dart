import '../specialized/systems/user_context.dart';
import '../specialized/systems/tone_modulator.dart';

/// Handles "Personnel" specific speech stylization (Sir vs Operator) 🎭
///
/// Transforms raw system messages into personality-driven dialogue.
class PersonnelFormatter {
  static final PersonnelFormatter _instance = PersonnelFormatter._internal();
  factory PersonnelFormatter() => _instance;
  PersonnelFormatter._internal();

  String format(String message, SystemTone tone, {PersonnelProfile? profile}) {
    final activeProfile = profile ?? UserContext().personnel;

    if (activeProfile == PersonnelProfile.operator) {
      return _formatOperator(message, tone);
    } else {
      return _formatSir(message, tone);
    }
  }

  String _formatSir(String message, SystemTone tone) {
    // Tony Stark / JARVIS Style: Polite, slightly witty, proactive.
    switch (tone) {
      case SystemTone.urgent:
        return "I'm sorry to interrupt, sir, but $message requires your immediate attention.";
      case SystemTone.celebratory:
        return "I've handled that for you, sir. $message";
      case SystemTone.cautionary:
        return "Sir, I've noticed something you might want to review: $message";
      case SystemTone.routine:
        return "Certainly, sir. $message";
      case SystemTone.concise:
        return "Briefly, sir: $message";
      case SystemTone.empathetic:
        return "I understand, sir. $message";
      default:
        return "Sir, $message";
    }
  }

  String _formatOperator(String message, SystemTone tone) {
    // Military / Operator Style: Precise, formal, zero-chatter.
    final code = _getToneCode(tone);
    return "[$code] $message. STATUS: NOMINAL.";
  }

  String _getToneCode(SystemTone tone) {
    switch (tone) {
      case SystemTone.urgent:
        return 'ALPHA-1';
      case SystemTone.cautionary:
        return 'BRAVO-2';
      case SystemTone.celebratory:
        return 'SIGMA-9';
      case SystemTone.routine:
        return 'DELTA-4';
      case SystemTone.concise:
        return 'MIN-5';
      case SystemTone.empathetic:
        return 'SOFT-7';
      default:
        return 'GEN-0';
    }
  }
}
