import "package:flutter/material.dart";
import "package:firebase_core/firebase_core.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/foundation.dart";
import "firebase_options.dart";
import "screens/home_screen.dart";
import "screens/login_screen.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화 시도
  bool firebaseInitialized = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseInitialized = true;
    print('Firebase 초기화 성공');
  } catch (e) {
    print('Firebase 초기화 실패: $e');
    print('더미 모드로 실행됩니다.');
  }

  runApp(MemoApp(firebaseInitialized: firebaseInitialized));
}

class MemoApp extends StatelessWidget {
  const MemoApp({super.key, required this.firebaseInitialized});

  final bool firebaseInitialized;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "메모 앱",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(elevation: 0, centerTitle: true),
        cardTheme: CardThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: firebaseInitialized
          ? const FirebaseAuthWrapper()
          : const WebLoginWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Firebase Auth를 사용하는 래퍼
class FirebaseAuthWrapper extends StatelessWidget {
  const FirebaseAuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        print(
          'FirebaseAuthWrapper - connectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, user: ${snapshot.data?.email}',
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          // 로그인된 경우
          print('FirebaseAuthWrapper - 사용자 로그인됨: ${snapshot.data!.email}');
          return const HomeScreen();
        } else {
          // 로그인되지 않은 경우
          print('FirebaseAuthWrapper - 사용자 로그인되지 않음');
          return const LoginScreen();
        }
      },
    );
  }
}

// 웹용 로그인 래퍼
class WebLoginWrapper extends StatefulWidget {
  const WebLoginWrapper({super.key});

  @override
  State<WebLoginWrapper> createState() => _WebLoginWrapperState();
}

class _WebLoginWrapperState extends State<WebLoginWrapper> {
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    print('WebLoginWrapper 초기화됨 - 로그인 상태: $_isLoggedIn');
  }

  void _login() {
    print('웹 로그인 호출됨');
    setState(() {
      _isLoggedIn = true;
    });
    print('로그인 상태 변경됨: $_isLoggedIn');
  }

  void _logout() {
    print('웹 로그아웃 호출됨');
    setState(() {
      _isLoggedIn = false;
    });
    print('로그아웃 상태 변경됨: $_isLoggedIn');
  }

  @override
  Widget build(BuildContext context) {
    print('WebLoginWrapper build 호출됨 - 로그인 상태: $_isLoggedIn');

    if (_isLoggedIn) {
      print('HomeScreen 표시');
      return HomeScreen(onLogout: _logout);
    } else {
      print('LoginScreen 표시');
      return LoginScreen(onLogin: _login);
    }
  }
}

// 웹 디버깅용 간단한 테스트 화면
class WebDebugScreen extends StatelessWidget {
  final VoidCallback onLogin;

  const WebDebugScreen({super.key, required this.onLogin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('웹 디버그 화면'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '웹에서 로그인 화면이 안 보이는 문제 디버깅',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            ElevatedButton(onPressed: onLogin, child: const Text('테스트 로그인')),
            const SizedBox(height: 20),
            const Text('이 화면이 보인다면 WebLoginWrapper는 정상 작동 중입니다.'),
          ],
        ),
      ),
    );
  }
}
