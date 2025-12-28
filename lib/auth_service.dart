import 'package:appwrite/appwrite.dart';
import 'package:appwrite/enums.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  final String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

class AuthService with ChangeNotifier {
  final Client client;
  late Account account;

  bool _isLoggedIn = false;
  User? _currentUser;

  // Active Persona State
  String? _activeIdentityId;
  String? _activeIdentityType; // 'private' or 'public'

  bool get isLoggedIn => _isLoggedIn;
  User? get currentUser => _currentUser;
  String? get activeIdentityId => _activeIdentityId;
  String? get activeIdentityType => _activeIdentityType;

  AuthService(this.client) {
    account = Account(client);
    init();
  }

  Future<void> init() async {
    try {
      final user = await account.get();
      _isLoggedIn = true;
      _currentUser = User(id: user.$id, name: user.name, email: user.email);
      // Determine default active identity (requires fetching profiles, which we might need AppwriteService for)
      // For now, let's leave it null or set it later when profiles are loaded.
      // Ideally, the UI or a higher-level provider sets this after login.
    } on AppwriteException {
      _isLoggedIn = false;
      _currentUser = null;
      _activeIdentityId = null;
      _activeIdentityType = null;
    }
    notifyListeners();
  }

  void setActiveIdentity(String id, String type) {
    _activeIdentityId = id;
    _activeIdentityType = type;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    await account.createEmailPasswordSession(email: email, password: password);
    final user = await account.get();
    _isLoggedIn = true;
    _currentUser = User(id: user.$id, name: user.name, email: user.email);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('loggedIn', true);
    await prefs.setString('email', email);

    notifyListeners();
  }

  Future<void> signOut() async {
    await account.deleteSession(sessionId: 'current');
    _isLoggedIn = false;
    _currentUser = null;
    _activeIdentityId = null;
    _activeIdentityType = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    notifyListeners();
  }

  /// Starts the signup process by sending an email token (OTP).
  /// A user record is created in Appwrite, but name and password are NOT set yet.
  Future<String> startSignUp(String email) async {
    try {
      final userId = ID.unique();
      await account.createEmailToken(userId: userId, email: email);
      return userId;
    } catch (e) {
      rethrow;
    }
  }

  /// Finalizes the signup process by verifying the OTP and setting name/password.
  Future<void> finalizeSignUp({
    required String userId,
    required String secret,
    required String name,
    required String password,
  }) async {
    try {
      // 1. Verify OTP and create a session
      await account.createSession(userId: userId, secret: secret);

      // 2. Set the name
      await account.updateName(name: name);

      // 3. Set the password (this requires an active session)
      await account.updatePassword(password: password);

      // 4. Update local state
      await init();
    } catch (e) {
      rethrow;
    }
  }

  // --- OTP Flow (for other purposes like MFA or Login) ---

  /// Sends an OTP to the specified email.
  Future<void> sendOTP(String email, {String userId = 'current'}) async {
    await account.createEmailToken(userId: userId, email: email);
  }

  // --- MFA Flow ---

  /// Enables or disables MFA.
  Future<void> setMfa(bool enabled) async {
    await account.updateMFA(mfa: enabled);
  }

  /// Initiates an MFA challenge.
  Future<String> startMFAChallenge() async {
    final challenge = await account.createMFAChallenge(
      factor: AuthenticationFactor.email,
    );
    return challenge.$id;
  }

  /// Completes an MFA challenge.
  Future<void> verifyMFAChallenge(String challengeId, String secret) async {
    await account.updateMFAChallenge(challengeId: challengeId, otp: secret);
    await init(); // Update login state
  }

  Future<User?> getCurrentUser() async {
    return _currentUser;
  }
}
