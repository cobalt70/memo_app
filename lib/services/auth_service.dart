import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // PlatformException 추가

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 현재 사용자 상태 스트림
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // 현재 사용자
  User? get currentUser => _auth.currentUser;

  // Google 로그인
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // 웹에서는 Firebase Auth의 GoogleAuthProvider 직접 사용
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        
        // 웹용 Google 로그인
        final result = await _auth.signInWithPopup(googleProvider);
        print('웹 Google 로그인 성공: ${result.user?.email}');
        return result;
      } else {
        // 모바일용 Google 로그인
        print('모바일 Google 로그인 시작...');
        
        // Google Sign In 7.x에서는 authenticate() 메서드 사용
        final GoogleSignInAccount? googleUser = await GoogleSignIn.instance
            .authenticate();

        if (googleUser == null) {
          print('Google 로그인 취소됨 또는 실패');
          return null; // 사용자가 로그인을 취소한 경우
        }

        print('Google 로그인 성공: ${googleUser.email}');

        // Google 인증 정보 가져오기
        final GoogleSignInAuthentication googleAuth = googleUser.authentication;
        print('Google 인증 토큰 획득: idToken=${googleAuth.idToken != null ? "있음" : "없음"}');

        // Firebase 인증 정보 생성 (accessToken은 더 이상 사용할 수 없음)
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        print('Firebase 인증 정보 생성 완료');

        // Firebase에 로그인
        final userCredential = await _auth.signInWithCredential(credential);
        print('Firebase 로그인 성공: ${userCredential.user?.email}');
        return userCredential;
      }
    } catch (e) {
      print('Google 로그인 오류: $e');
      print('오류 타입: ${e.runtimeType}');
      if (e is PlatformException) {
        print('PlatformException 코드: ${e.code}');
        print('PlatformException 메시지: ${e.message}');
        print('PlatformException 세부사항: ${e.details}');
      }
      return null;
    }
  }

  // 로그아웃
  Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
      await _auth.signOut();
    } catch (e) {
      print('로그아웃 오류: $e');
    }
  }

  // 사용자 정보 가져오기
  String? get userDisplayName => currentUser?.displayName ?? "사용자";
  String? get userEmail => currentUser?.email ?? "user@example.com";
  String? get userPhotoURL => currentUser?.photoURL;
}
