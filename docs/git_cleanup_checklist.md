# Git Cleanup Checklist (Quran Project)

استخدم القائمة دي قبل أي `commit` أو قبل نسخ المشروع على فلاشة.

## 1) راجع حالة الجيت
```powershell
git status --short
```

## 2) نظف الملفات المولدة (Tracked generated files)
```powershell
git restore -- `
  linux/flutter/generated_plugin_registrant.cc `
  linux/flutter/generated_plugins.cmake `
  macos/Flutter/GeneratedPluginRegistrant.swift `
  windows/flutter/generated_plugin_registrant.cc `
  windows/flutter/generated_plugins.cmake
```

## 3) امسح الكاش والبيلد
```powershell
flutter clean
```

## 4) اعرف إيه هيتحذف قبل الحذف
```powershell
git clean -nd
git clean -ndX
```

## 5) حذف فعلي (بحذر)
- حذف الملفات غير المتتبعة فقط:
```powershell
git clean -fd
```
- حذف الملفات المتجاهلة (`.dart_tool`, `build`, ...):
```powershell
git clean -fdX
```

## 6) نسخة آمنة (مستحسن)
لو مش متأكد، نفّذ الخطوتين 4 فقط وابعت الناتج قبل الحذف النهائي.

## ملاحظات مهمة
- `git clean -fd` و `git clean -fdX` أوامر حذف نهائي.
- ما تستخدمش `git reset --hard` إلا لو متأكد جدًا.
- أي ملف أدوات محلي (مثل `tool/ayah_box_tool/`) ما تحذفهش إلا لو ناوي فعلاً تستغنى عنه.
