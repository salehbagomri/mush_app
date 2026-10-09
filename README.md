# دليل الشحر المكلا (Mush App)

دليل خدمي وسياحي شامل لمدينتي الشحر والمكلا، محافظة حضرموت، الجمهورية اليمنية.

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Platform](https://img.shields.io/badge/platform-Android-green)
![Framework](https://img.shields.io/badge/framework-Flutter%203-02569B?logo=flutter)
![Backend](https://img.shields.io/badge/backend-Supabase-3ECF8E?logo=supabase)
![State Management](https://img.shields.io/badge/state%20management-Riverpod-blue)
![License](https://img.shields.io/badge/license-All%20Rights%20Reserved-red)

---

## نظرة عامة (Overview)

**دليل الشحر المكلا** هو تطبيق جوال خدمي وسياحي متكامل تم تطويره لخدمة المجتمع المحلي وزوار مدينتي **الشحر** و**المكلا**. يتيح التطبيق للمواطنين والزوار استكشاف كافة الخدمات الحكومية والخاصة، والتعرف على متطلبات المعاملات والرسوم ومواقع الدوام، مع إمكانية التواصل الفوري والمباشر (اتصال هاتف، واتساب، موقع جغرافي، والموقع الإلكتروني).

يعتمد التطبيق على بنية تحتية سحابية عبر **Supabase** (PostgreSQL + Auth + Storage + Row-Level Security) مع تخزين محلي سريع وإدارة حالة تفاعلية عبر **Riverpod**.

> **" إذهب للمجتمع ولاتدع المجتمع ياتي إليك "**

---

## المميزات الرئيسية (Features)

### 👥 المستخدم العام والزائر (Public & Tourists)
- **استكشاف متقدم:** تصفح الخدمات حسب المدينة (الشحر / المكلا)، الأقسام الرئيسية، والتصنيفات (صحية، تعليمية، أمنية، سياحية، تجارية، وغيرها).
- **تفاصيل متكاملة للخدمة:** عرض متطلبات وإجراءات المعاملة، الرسوم المقررة، أوقات العمل الرسمية، والعنوان الجغرافي.
- **تواصل بنقرة واحدة:**
  - 📞 اتصال هاتفي مباشر.
  - 💬 محادثة واتساب فورية مع تصفية أرقام الهواتف اليمنية تلقائياً.
  - 📍 فتح الموقع في خرائط Google.
  - 🌐 زيارة الموقع الإلكتروني الرسمي للمنشأة.
- **إعلانات تفاعلية:** شريط إعلانات متحرك في الواجهة الرئيسية للأنشطة والفعاليات.
- **شاشة ترحيبية وتثقيفية (Onboarding):** تجربة مستخدم انسيابية تبرز هوية المشروع ومميزاته عند أول تثبيت.

### 🏢 مزودو الخدمات (Service Providers)
- لوحة تحكم مخصصة لإدارة الخدمات والمنشآت.
- إضافة خدمات جديدة مع رفع صور عالية الجودة إلى Supabase Storage.
- تحديد تفاصيل المتطلبات، الأوراق الثبوتية، الرسوم، والفئات المستهدفة.
- تعديل وتحديث بيانات المنشأة ومواعيد العمل وأرقام التواصل.

### 🛡️ إدارة النظام (System Administration)
- **إحصائيات تفاعلية:** نظرة شاملة على عدد الخدمات، المزودين، التصنيفات، والإعلانات النشطة.
- **إدارة مزودي الخدمات:** إنشاء وتعديل الحسابات (الاسم، البريد، كلمة المرور، ونوع المزود حكومي/خاص)، مع إمكانية التفعيل والإيقاف.
- **إدارة التصنيفات:** إضافة وتعديل التصنيفات وربطها بالأقسام الرئيسية والمدن.
- **إدارة الإعلانات الترويجية:** رفع وتحديث صور الإعلانات، التحكم في حالتها (نشط / متوقف)، وحذفها.
- **الرقابة على كافة الخدمات:** فحص وتعديل أو تعليق أي خدمة مخالفة.

---

## التقنيات المستخدمة (Technology Stack)

| المكون (Component) | التقنية (Technology) |
|---|---|
| **إطار العمل (Framework)** | Flutter 3 / Dart |
| **قاعدة البيانات والسحابة (Backend)** | Supabase (PostgreSQL + Auth + Storage + RLS) |
| **إدارة الحالة (State Management)** | Flutter Riverpod 2 (`flutter_riverpod`) |
| **التوجيه والتنقل (Routing)** | GoRouter (`go_router`) |
| **الوسائط والتخزين (Media & Storage)** | Image Picker + Supabase Storage Bucket |
| **التخزين المحلي (Local Cache)** | SharedPreferences |
| **الواجهات والحركات (UI & Animation)** | Flutter Animate, Smooth Page Indicator, Shimmer |
| **الخطوط والرموز (Typography & Icons)** | خط Cairo العربي + Material Icons |
| **التوافق الشبكي (Networking)** | URL Launcher (`url_launcher`) مع دعم كامل لـ Android 11+ Queries |

---

## الهيكلية البرمجية (Architecture)

يعتمد المشروع على نمط **Layered Architecture** المتوافق مع أفضل الممارسات:

```text
lib/
├── core/                  # الثوابت، الألوان، السمات، والتوجيه والمساعدات العامة
│   ├── constants/         # AppColors, AppStrings
│   ├── errors/            # Exceptions & Failure Handlers
│   ├── router/            # GoRouter configuration & route guards
│   ├── theme/             # AppTheme (Light & Dark palettes)
│   ├── utils/             # Helpers (Phone sanitizers, URL launchers, dialogs)
│   └── widgets/           # Shared reusable UI components
├── data/                  # طبقة البيانات والتعامل مع الخادم
│   ├── models/            # ServiceModel, CategoryModel, UserModel, AdvertisementModel
│   └── repositories/      # AuthRepository, ServicesRepository, AdminRepository
├── presentation/          # طبقة العرض والواجهات ومزودات الحالة
│   ├── providers/         # Riverpod providers (Auth, Services, Admin, Router)
│   └── screens/           # الشاشات مقسمة حسب الأدوار والأقسام:
│       ├── about/         # شاشة "من نحن" وفريق التخرج
│       ├── admin/         # لوحة تحكم الإدارة (مزودين، تصنيفات، إعلانات، خدمات)
│       ├── auth/          # تسجيل الدخول وإنشاء الحساب
│       ├── categories/    # تصفح التصنيفات
│       ├── home/          # الواجهة الرئيسية وشريط البحث والإعلانات
│       ├── onboarding/    # شاشات الترحيب والتعريف بالمشروع
│       ├── profile/       # الملف الشخصي وتحديث البيانات
│       ├── provider/      # لوحة المزود وإضافة وتعديل الخدمات
│       ├── search/        # البحث المتقدم والفلترة
│       └── services/      # قوائم الخدمات وتفاصيل كل خدمة
└── main.dart              # نقطة الانطلاق وتهيئة Supabase والاتجاه RTL
```

---

## التشغيل والإعداد (Getting Started)

### المتطلبات الأساسية (Prerequisites)
- Flutter SDK (الإصدار 3.24 فما فوق)
- Dart SDK
- حساب ومشروع نشط على **Supabase**

### تهيئة الاتصال بـ Supabase
يتم ضبط إعدادات الاتصال في `lib/core/constants/app_strings.dart` أو عبر تمريرها:

```dart
static const String supabaseUrl = 'https://YOUR_PROJECT.supabase.co';
static const String supabaseAnonKey = 'YOUR_ANON_KEY';
```

تأكد من تطبيق مخطط قاعدة البيانات في `supabase/schema.sql` وإنشاء مجلدات التخزين (Storage Buckets):
- `service-images` (عام Public)
- `advertisements` (عام Public)

---

## البناء والتطوير (Building)

```bash
# تثبيت الحزم والمكتبات
flutter pub get

# فحص سلامة الأكواد
dart analyze lib/

# تشغيل الاختبارات
flutter test

# تشغيل التطبيق في وضع التطوير
flutter run

# بناء حزمة الإنتاج (Release APK)
flutter build apk --release

# بناء حزمة متجر جوجل بلاي (App Bundle)
flutter build appbundle --release
```

---

## معلومات المشروع (Project Information)

| الخاصية | القيمة |
|---|---|
| **اسم التطبيق** | دليل الشحر المكلا (Mush App) |
| **معرّف الحزمة (Package ID)** | `com.mush.mush_app` |
| **الإصدار (Version)** | 1.0.0 |
| **الحد الأدنى للأندرويد (Min SDK)** | Android 5.0 (API 21) |
| **الإصدار المستهدف (Target SDK)** | Android 14 (API 34) |
| **اللغة والاتجاه** | العربية (RTL) |
| **المنصات المدعومة** | Android / iOS |

---

## فريق مشروع التخرج (Graduation Project Team)

تم تطوير وتصميم وبرمجة هذا المشروع كمشروع تخرج نوعي لخدمة المجتمع:

* **مشرف المشروع:**
  - **دكتور.مهندس / إبراهيم إسكندر فاضل**

* **أعضاء فريق العمل:**
  - **م. صالح أحمد باقمري** (`s.bagomri@gmail.com`)
  - **م. سالم علي الموزعي** (`salemali71261@gmail.com`)
  - **م. أحمد سالم شيخان** (`alnino77g@gmail.com`)
  - **م. عبدالعزيز محمد بن محمود** (`abdulazizbinmahmoud12@gmail.com`)
  - **م. محمد عبدالله العطاس** (`mohammedalatas1@gmail.com`)

---

## الحقوق والترخيص (License)

جميع الحقوق محفوظة © 2026 لفريق عمل مشروع تخرج **دليل الشحر المكلا**.
الكود المصدري متاح للمعاينة والتقييم الأكاديمي.
