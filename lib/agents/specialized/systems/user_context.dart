/// User Mood / Sentiment
enum UserMood {
  relaxed, // Conversational, detailed feedback
  focused, // Objective, concise updates
  busy, // Brief, high-level summaries only
  frustrated, // High safety, verbose logs, cautious
}

/// User Interaction Style
enum InteractionStyle {
  cinematic, // Full "JARVIS" flair
  minimalist, // System-only, no flair
  didactic, // Explanatory, educational
}

/// JARVIS Personnel Interface Styles
enum PersonnelProfile {
  sir, // Stark style: Polite, slightly witty, proactive
  operator, // Military style: Direct, formal, zero-chatter
}

/// User Context 🧑‍💻
///
/// Tracks the current state of the human operator to adapt system behavior.
class UserContext {
  static final UserContext _instance = UserContext._internal();
  factory UserContext() => _instance;
  UserContext._internal();

  UserMood mood = UserMood.relaxed;
  InteractionStyle style = InteractionStyle.cinematic;
  PersonnelProfile personnel = PersonnelProfile.sir; // Default to Stark
  String? lastActivity;
  DateTime lastInteraction = DateTime.now();

  /// Update context based on observation
  void update({
    UserMood? newMood,
    InteractionStyle? newStyle,
    PersonnelProfile? newPersonnel,
    String? activity,
  }) {
    if (newMood != null) mood = newMood;
    if (newStyle != null) style = newStyle;
    if (newPersonnel != null) personnel = newPersonnel;
    if (activity != null) lastActivity = activity;
    lastInteraction = DateTime.now();
  }

  /// Reset to default
  void reset() {
    mood = UserMood.relaxed;
    style = InteractionStyle.cinematic;
    personnel = PersonnelProfile.sir;
  }
}

final userContext = UserContext();
