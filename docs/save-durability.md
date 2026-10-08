# 💾 متانة الحفظ (Save Durability)

> يعالج هذا الملف الملاحظة الدقيقة: **«قراءة `repo` و`notifier` قبل أول `await` لا تضمن اكتمال
> الحفظ بعد مغادرة الشاشة»** — وهي ملاحظة صحيحة تمامًا، وهذا ما تغيّر.

---

## 1) المشكلة الفعلية

في النسخة السابقة كان مسار الحفظ هكذا:

```dart
final repo = ref.read(galleryRepositoryProvider);            // كائن عادي ✅
final notifier = ref.read(progressControllerProvider.notifier); // ⚠️ كائن Riverpod
final bytes = await controller.capture();                    // await
final file  = await repo.saveDesignImage(bytes, ...);        // ✅ لا يعتمد على ref
notifier.attachImage(id, file);                              // ⚠️ قد يكون مُتلَفًا
```

- `GalleryRepository` كائن عادي، فلا مشكلة.
- لكن **`Notifier` نفسه قد يكون قد تُلِف** (`dispose`) — عند إغلاق التطبيق، أو عند تهديم
  `ProviderScope` كاملًا أثناء الكتابة. استدعاء `state = …` على notifier مُتلَف **يرمي استثناء**،
  وكان ذلك يعني ضياع **اسم ملف الصورة** من سجلّ الألبوم (وإن بقي الـ PNG على القرص يتيمًا).

## 2) الحل: طبقة حفظ لا تعرف Riverpod أصلًا

```
lib/data/repositories/design_saver.dart
    DesignSaver.save(designId:, capture:)  →  DesignSaveResult
       1) capture()                       (بايتات PNG)
       2) GalleryRepository.saveDesignImage (كتابة ذرّية: tmp ثم rename)
       3) LocalStorageService.setDesignImage (سجل دائم: designId → اسم الملف)
```

- **لا `ref`، ولا `Notifier`، ولا `BuildContext`** داخل مسار الحفظ.
- الخطوة (3) تُكتب عبر **singleton خامل** (`SharedPreferences`) فلا يهم إن كانت الشاشة قد أُغلقت.
- الكتابة ذرّية: تُكتب في ملف مؤقت ثم `rename` — فلا يمكن أن يبقى PNG نصف مكتوب إذا أُغلق التطبيق.

## 3) كيف يظهر التصميم بعد ذلك؟

عند تحميل التقدّم تُدمج الخريطة الدائمة في الألبوم:

```dart
// ProgressController.build()
storage.loadProgress().withDesignImages(storage.loadDesignImages());
```

- `withDesignImages` دالة **نقية** لا تعدّل أي شيء سوى إضافة الأسماء الناقصة:
  - لا تلمس تصميمًا يعرف اسم ملفه أصلًا.
  - لا تُغيّر أي كائن إذا لم يوجد شيء لتغييره (`identical == true`).
- لذلك: حتى لو كانت الكتابة قد اكتملت **بعد** إغلاق الشاشة، ستظهر الصورة في الألبوم في
  الجلسة التالية — أو في نفس الجلسة إن أُعيد بناء الـ provider.

## 4) الأخطاء لم تعد تمرّ بصمت

| ما يمكن أن يفشل | ما يحدث الآن |
|---|---|
| `capture()` يعيد `null` (الشاشة أُغلقت مبكرًا) | `emptyCapture` → 3 محاولات متدرجة ثم إصلاح ذاتي في الألبوم |
| الكتابة على القرص تفشل (مساحة/صلاحيات) | `writeFailed` → نفس مسار المحاولات |
| `SharedPreferences` يفشل في كتابة السجل | الـ PNG موجود، والألبوم يعيد الالتقاط (الإصلاح الذاتي) |
| `notifier` مُتلَف بعد `await` | الاستدعاء داخل `try/catch` — والمرآة في الذاكرة ليست مصدر الحقيقة |
| `rename` ينقطع (إغلاق التطبيق) | لا يبقى سوى ملف `.tmp` — والملف النهائي يبقى سليمًا |

## 5) المصدر الوحيد للحقيقة

- **القرص هو مصدر الحقيقة للصور** (سجل `sparkle.design.images` + ملفات PNG).
- **الذاكرة مرآة اختيارية** لتحديث الواجهة بسرعة (`attachImage`).
- لهذا لا يهم ترتيب الأحداث: كل مسار فقدان محتمل ينتهي بإصلاح ذاتي في الألبوم.

## 6) ما لم يُختبر بعد (تصريح)

هذا التصميم **لم يُشغَّل على جهاز** (لا Flutter في بيئة التنفيذ). المختبر فعليًا:
منطق الدمج النقي (`test/design_images_test.dart` مكتوب، غير مُنفَّذ)، وفحوص بنيوية
(0 استيراد مكسور، توازن الأقواس، غياب أنماط `enabled`/التأخير القديمة).
السيناريو الحاسم — **الخروج من Reveal قبل انتهاء الاحتفال ثم فتح الألبوم** — يجب تجربته يدويًا
على جهاز (البند 5 في `docs/verification.md`).
