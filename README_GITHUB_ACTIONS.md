# APK बनवण्याचा सोपा मार्ग — GitHub Actions (Android Studio शिवाय)

तुमच्या laptop वर काहीही install न करता, **GitHub च्या स्वतःच्या servers वर**
आपोआप APK build होईल. फक्त एक free GitHub account लागेल.

---

## टप्पा 1: GitHub वर Repository बनवा

1. https://github.com वर जाऊन free account बनवा (आधीच असेल तर login करा).
2. वरती उजवीकडे **"+"** > **"New repository"** दाबा.
3. नाव द्या: `expense-tracker` (Public किंवा Private, दोन्ही चालेल) > **Create repository**.

---

## टप्पा 2: Files Upload करा

1. नवीन बनलेल्या repository page वर **"uploading an existing file"** या link वर
   क्लिक करा (किंवा "Add file" > "Upload files").
2. मी दिलेल्या zip मधलं **सगळं content** (म्हणजे `lib` folder, `pubspec.yaml`,
   `.github` folder, `README` files — सगळं) तिथे drag-and-drop करा.
   - **लक्षात ठेवा:** `.github` हा folder पण नक्की upload करा (तो दिसायला कदाचित
     hidden वाटेल, पण तो असणं आवश्यक आहे — त्याशिवाय automatic build चालणार नाही).
3. खाली "Commit changes" दाबा.

---

## टप्पा 3: Build आपोआप सुरू होईल

1. Repository च्या वरती **"Actions"** tab वर क्लिक करा.
2. "Build Android APK" नावाचं workflow आपोआप सुरू झालेलं दिसेल (पिवळं वर्तुळ
   फिरत असेल = चालू आहे). जर सुरू झालं नसेल, तर डावीकडून workflow निवडून
   **"Run workflow"** दाबा.
3. साधारण **5-10 मिनिटं** थांबा.
4. हिरवं ✓ (टिक) दिसलं की build यशस्वी झाला!

---

## टप्पा 4: APK Download करा

1. यशस्वी झालेल्या run वर क्लिक करा.
2. खाली स्क्रोल करून **"Artifacts"** section मध्ये **"expense-tracker-apk"**
   दिसेल — त्यावर क्लिक करून download करा (हा एक zip असेल).
3. तो zip extract करा — आतमध्ये **`app-release.apk`** ही फाईल मिळेल.
4. ही फाईल फोनवर पाठवा (Google Drive, WhatsApp, USB — कुठल्याही मार्गाने) आणि
   फोनवर उघडून install करा (पहिल्यांदा "install unknown apps" permission
   द्यावी लागेल — फोन तसं विचारेल).

---

## Google Sign-In / Drive Backup साठी (एकदाच)

1. वरच्याच Actions run मध्ये, **"Debug keystore chi SHA-1 fingerprint dakhva"**
   या step वर क्लिक करून तो log उघडा. त्यात **`SHA1:`** असं लिहिलेली एक ओळ
   दिसेल — ती value copy करा.
2. मुख्य `README_MARATHI.md` मधल्या **टप्पा 3** प्रमाणे Google Cloud Console वर
   जा — तिथे फक्त keytool चालवायची पायरी वगळा, त्याऐवजी वरून copy केलेली SHA-1
   value वापरा. बाकी सगळे steps तसेच.
3. Package name म्हणून `com.example.expense_tracker` वापरा.

एवढं झालं की तुमचं app पूर्ण तयार — Income/Expense tracking + Google Drive
backup दोन्ही काम करेल!

---

## पुढच्या वेळी update करायचं असेल तर

Code मध्ये काही बदल केला (उदा. मी तुम्हाला नवीन feature दिली), तर तो नुसता
GitHub वर परत upload करा ("Add file" > "Upload files") — Actions आपोआप परत
चालून नवीन APK बनवेल.
