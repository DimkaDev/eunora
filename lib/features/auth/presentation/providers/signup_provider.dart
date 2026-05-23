import 'package:flutter_riverpod/flutter_riverpod.dart';

class SignUpState {
  final String email;
  final String password;
  final String confirmPassword;
  final String? emailError;
  final String? passwordError;
  final String? confirmPasswordError;
  final bool showErrors;

  SignUpState({
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.emailError,
    this.passwordError,
    this.confirmPasswordError,
    this.showErrors = false,
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
    bool? showErrors,
  }) {
    return SignUpState(
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      emailError: emailError,
      passwordError: passwordError,
      confirmPasswordError: confirmPasswordError,
      showErrors: showErrors ?? this.showErrors,
    );
  }
}

class SignUpController extends StateNotifier<SignUpState> {
  SignUpController() : super(SignUpState());

  void updateEmail(String email) {
    // state = state.copyWith(email: email, showErrors: false);
  }

  void updatePassword(String password) {
    state = state.copyWith(password: password, showErrors: false);
  }

  void updateConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword, showErrors: false);
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
    );

    return state.isValid;
  }
}

final signUpProvider = StateNotifierProvider<SignUpController, SignUpState>((ref) {
  return SignUpController();
});
