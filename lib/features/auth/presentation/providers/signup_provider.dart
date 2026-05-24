import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:eunora/core/services/auth_service.dart';

class SignUpState {
  final String email;
  final String password;
  final String confirmPassword;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final String? generalError;
  final bool showErrors;
  final bool isLoading;

  SignUpState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.generalError,
    this.showErrors = false,
    this.isLoading = false,
  });

  bool get isEmailValid => RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  bool get hasMinLength => password.length >= 8;
  bool get hasUppercase => password.contains(RegExp(r'[A-Z]'));
  bool get hasNumber => password.contains(RegExp(r'[0-9]'));
  bool get hasSpecialChar => password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get passwordsMatch => password == confirmPassword && password.isNotEmpty;

  bool get isValid => isEmailValid && hasMinLength && hasUppercase && hasNumber && hasSpecialChar && passwordsMatch;

  SignUpState copyWith({
    String? email,
    String? password,
    String? confirmPassword,
    String? emailError,
    String? passwordError,
    String? confirmPasswordError,
    String? generalError,
    bool? showErrors,
    bool? isLoading,
  }) {
    return SignUpState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      generalError: generalError,
      showErrors: showErrors ?? this.showErrors,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SignUpController extends StateNotifier<SignUpState> {
  final AuthService _authService;

  SignUpController(this._authService) : super(SignUpState());

  void updateEmail(String email) {
    state = state.copyWith(email: email, showErrors: false, generalError: null);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, showErrors: false, generalError: null);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword, showErrors: false, generalError: null);
  }

  bool validate() {
    String? emailError;
    String? passwordError;
    String? confirmPasswordError;

    if (!state.isEmailValid) {
      emailError = 'Please enter a valid email address';
    }

    if (!state.hasMinLength || !state.hasUppercase || !state.hasNumber || !state.hasSpecialChar) {
      passwordError = 'Password does not meet requirements';
    }

    if (!state.passwordsMatch) {
      confirmPasswordError = 'Passwords do not match';
    }

    state = state.copyWith(
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      showErrors: true,
      generalError: null,
    );

    return state.isValid;
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setGeneralError(String? error) {
    state = state.copyWith(generalError: error);
  }

  Future<bool> signUp() async {
    if (!validate()) return false;

    state = state.copyWith(isLoading: true, generalError: null);

    try {
      await _authService.signUpWithEmail(state.email, state.password);
      state = state.copyWith(isLoading: false);
      return true;
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred during registration.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is not valid.';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      state = state.copyWith(isLoading: false, generalError: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, generalError: e.toString());
      return false;
    }
  }
}

final signUpProvider = StateNotifierProvider<SignUpController, SignUpState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return SignUpController(authService);
});
