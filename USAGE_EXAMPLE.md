# مثال على استخدام ميزة عدم الاتصال

## 1. الاستخدام التلقائي (مفعل بالفعل)

الميزة مفعلة تلقائياً في التطبيق عبر `ConnectivityWrapper` في `main.dart`. لا تحتاج لأي إجراء إضافي.

## 2. الاستخدام في شاشة محددة

إذا أردت التحقق من الاتصال في شاشة محددة:

```dart
import 'package:goal_master_admin/core/components/connectivity_checker.dart';

class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ConnectivityChecker(
      child: Scaffold(
        appBar: AppBar(title: Text('شاشتي')),
        body: Column(
          children: [
            // محتوى الشاشة
            Text('محتوى الشاشة'),
            
            // مثال على التحقق من الاتصال
            ElevatedButton(
              onPressed: () async {
                bool isConnected = await ConnectivityHook.checkConnection();
                if (!isConnected) {
                  // عرض رسالة أو تنفيذ إجراء
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('لا يوجد اتصال بالإنترنت')),
                  );
                }
              },
              child: Text('تحقق من الاتصال'),
            ),
          ],
        ),
      ),
    );
  }
}
```

## 3. الاستخدام بدون عرض شاشة عدم الاتصال

```dart
ConnectivityChecker(
  showNoInternetScreen: false, // لا تعرض شاشة عدم الاتصال
  child: YourWidget(),
)
```

## 4. الاستخدام في Cubit أو Bloc

```dart
import 'package:goal_master_admin/core/components/connectivity_checker.dart';

class MyCubit extends Cubit<MyState> {
  Future<void> performAction() async {
    // التحقق من الاتصال قبل تنفيذ الإجراء
    bool isConnected = await ConnectivityHook.checkConnection();
    
    if (!isConnected) {
      emit(MyState.error('لا يوجد اتصال بالإنترنت'));
      return;
    }
    
    // تنفيذ الإجراء
    try {
      // API call
      emit(MyState.success(data));
    } catch (e) {
      emit(MyState.error(e.toString()));
    }
  }
}
```

## 5. الاستخدام في Repository

```dart
import 'package:goal_master_admin/core/components/connectivity_checker.dart';

class MyRepository {
  Future<Result> fetchData() async {
    // التحقق من الاتصال
    bool isConnected = await ConnectivityHook.checkConnection();
    
    if (!isConnected) {
      return Result.failure('لا يوجد اتصال بالإنترنت');
    }
    
    try {
      // API call
      return Result.success(data);
    } catch (e) {
      return Result.failure(e.toString());
    }
  }
}
```

## 6. إضافة مؤشر الاتصال في AppBar

```dart
AppBar(
  title: Text('العنوان'),
  actions: [
    StreamBuilder<bool>(
      stream: ConnectivityService().connectionStatus,
      builder: (context, snapshot) {
        bool isConnected = snapshot.data ?? true;
        return Icon(
          isConnected ? Icons.wifi : Icons.wifi_off,
          color: isConnected ? Colors.green : Colors.red,
        );
      },
    ),
  ],
)
```

## 7. إضافة رسالة في الشاشة

```dart
StreamBuilder<bool>(
  stream: ConnectivityService().connectionStatus,
  builder: (context, snapshot) {
    bool isConnected = snapshot.data ?? true;
    
    if (!isConnected) {
      return Container(
        padding: EdgeInsets.all(16),
        color: Colors.orange,
        child: Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'لا يوجد اتصال بالإنترنت',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }
    
    return SizedBox.shrink(); // لا تعرض أي شيء إذا كان هناك اتصال
  },
)
```

## 8. تخصيص شاشة عدم الاتصال

يمكنك تخصيص شاشة عدم الاتصال بتعديل `NoInternetView`:

```dart
// في NoInternetView
Text(
  'رسالة مخصصة', // تغيير النص
  style: TextStyle(
    color: Colors.red, // تغيير اللون
    fontSize: 18, // تغيير الحجم
  ),
),
```

## 9. إضافة أزرار إضافية

```dart
// في NoInternetView
Row(
  children: [
    Expanded(
      child: ButtonApp(
        onTap: _checkConnection,
        text: 'إعادة المحاولة',
      ),
    ),
    SizedBox(width: 16),
    Expanded(
      child: ButtonApp(
        onTap: () {
          // إجراء إضافي
        },
        text: 'إعدادات الشبكة',
        backGround: Colors.grey,
      ),
    ),
  ],
),
```

## 10. اختبار الميزة

### في المحاكي:
1. افتح التطبيق
2. اذهب إلى إعدادات المحاكي
3. اقطع الاتصال بالإنترنت
4. عد للتطبيق وستظهر شاشة عدم الاتصال

### في الجهاز الحقيقي:
1. افتح التطبيق
2. اقطع الاتصال بالإنترنت (WiFi/Data)
3. ستظهر شاشة عدم الاتصال تلقائياً
4. أعد الاتصال وستختفي الشاشة 