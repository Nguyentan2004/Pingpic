import 'package:flutter/material.dart';
import 'package:pingpic/l10n/app_localizations.dart';

class FirebaseErrorHelper {
  FirebaseErrorHelper._();

  static String getLocalizedError(BuildContext context, String? errorCode) {
    if (errorCode == null || errorCode.isEmpty) {
      return AppLocalizations.of(context)!.errUnknown;
    }

    final l10n = AppLocalizations.of(context)!;
    
    switch (errorCode) {
      case 'permission-denied':
      case 'firebase/permission-denied':
        return l10n.errPermissionDenied;
      case 'auth/username-not-found':
      case 'username-not-found':
        return l10n.errUsernameNotFound;
      case 'auth/email-not-linked':
      case 'email-not-linked':
        return l10n.errEmailNotLinked;
      case 'invalid-credential':
      case 'auth/invalid-credential':
      case 'wrong-password':
      case 'auth/wrong-password':
      case 'user-not-found':
      case 'auth/user-not-found':
        return l10n.errInvalidCredential;
      case 'invalid-email':
      case 'auth/invalid-email':
        return l10n.errInvalidEmail;
      case 'user-disabled':
      case 'auth/user-disabled':
        return l10n.errUserDisabled;
      case 'too-many-requests':
      case 'auth/too-many-requests':
        return l10n.errTooManyRequests;
      case 'auth/username-already-in-use':
      case 'username-already-in-use':
        return l10n.errUsernameAlreadyInUse;
      case 'email-already-in-use':
      case 'auth/email-already-in-use':
        return l10n.errEmailAlreadyInUse;
      case 'weak-password':
      case 'auth/weak-password':
        return l10n.errWeakPassword;
      case 'operation-not-allowed':
      case 'auth/operation-not-allowed':
        return l10n.errOperationNotAllowed;
      case 'auth/network-error':
      case 'network-error':
        return l10n.errNetworkError;
      default:
        final lower = errorCode.toLowerCase();
        if (lower.contains('permission-denied') || lower.contains('permission denied')) {
          return l10n.errPermissionDenied;
        }
        if (lower.contains('network') || lower.contains('connection')) {
          return l10n.errNetworkError;
        }
        return errorCode; // Return message if not a code
    }
  }
}
