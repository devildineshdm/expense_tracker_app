# नवीन Updates — काय काय बदललं आणि पुढे काय करायचं

## 1. Google Sign-In Fail Fix (सगळ्यात महत्त्वाचं)

**समस्या होती:** प्रत्येक GitHub build ला नवीन random keystore तयार होत होती, त्यामुळे
प्रत्येक APK ची SHA-1 fingerprint बदलत होती — जुनी नोंदवलेली SHA-1 जुळत नव्हती.

**Fix:** आता एक **कायमची (fixed) keystore file** repo मध्ये टाकलीये
(`keystore/debug.keystore`), आणि workflow आता तीच वापरतो. यापुढे SHA-1 कधीच बदलणार
नाही.

### तुम्हाला करायचं काम (एकदाच):

1. Google Cloud Console (https://console.cloud.google.com) वर जा.
2. **"APIs & Services" > "Credentials"** मध्ये जा.
3. जुना Android OAuth Client असेल तर तो उघडा (किंवा नवीन "Create Credentials" >
   "OAuth client ID" > Android निवडा), आणि यात:
   - Package name: `com.example.expense_tracker`
   - SHA-1 fingerprint: **`E2:F8:E2:E7:8F:58:55:F9:7F:E1:78:9F:51:98:16:DA:34:FE:C1:B1`**
   
   ही value टाका (अगदी हुबेहूब, कोलनसकट).
4. Save करा.

### आणखी एक common कारण — Test Users:

Jar तुमचं OAuth consent screen अजून "Testing" mode मध्ये असेल (Publish केलेलं
नसेल), तर **फक्त "Test users" मध्ये add केलेले Gmail account** login करू शकतात.

- **"APIs & Services" > "OAuth consent screen"** मध्ये जा.
- खाली "Test users" section मध्ये तुम्ही sign-in साठी वापरणारा **exact Gmail
  address** add केलाय का ते तपासा.
- नसेल तर "+ Add Users" ने add करा.

**या दोन्ही गोष्टी केल्यावर नवीन APK build करून परत sign-in try करा.** आता जर
परत error आला, तर आता app मध्ये **नेमकं error message दाखवेल** (आधी फक्त "fail
झाला" दिसायचं) — तो screenshot पाठवा, अचूक कारण सांगता येईल.

---

## 2. Excel Export

Top-right च्या ⋮ (तीन टिंब) मेनूमध्ये **"Excel मध्ये Export करा"** option
आहे. यावर दाबलं की सगळा data (.xlsx file) तयार होऊन फोनच्या "Share" मेनूतून
WhatsApp, Gmail, Google Drive, Files — कुठेही पाठवता/save करता येईल. फाईलमध्ये
Date, Type, Category, Amount, Payment Mode, Note आणि शेवटी Total
Income/Expense/Balance ची summary पण असेल.

*(टीप: थेट "Google Sheets" म्हणून cloud वर auto-create करणं जास्त गुंतागुंतीचं
आहे — Excel file export करून ती Google Drive मध्ये save केली की Drive
आपोआप तिला Google Sheets मध्ये उघडायचा option देतो, त्यामुळे प्रॅक्टिकली तेच
काम होतं.)*

---

## 3. Bill/Receipt फोटो (Optional)

नवीन entry टाकताना आता खाली **"Bill चा फोटो जोडा"** बटण आहे — Camera ने काढा
किंवा Gallery मधून निवडा. फोटो phone वर save होतोच, आणि जर Google Drive ला
login केलेलं असेल तर तो आपोआप एका **"ExpenseTracker_Receipts"** नावाच्या
folder मध्ये Drive वर पण upload होतो (हा folder तुमच्या नेहमीच्या Google
Drive मध्ये दिसेल, कारण तो फक्त backup साठीचा hidden folder नाही).

---

## 4. App PIN Lock

Top-right च्या ⋮ मेनूमध्ये **"App PIN Lock सेट करा"** option आहे — 4-digit
PIN सेट करा. एकदा सेट केला की, app परत उघडल्यावर (बंद करून परत उघडलं तरी)
आधी PIN विचारेल, मगच आत जाता येईल. PIN काढून टाकायचा असेल तर त्याच स्क्रीनवर
"PIN Lock बंद करा" बटण आहे.

---

## GitHub वर काय upload करायचं

खाली दिलेले **सगळे बदललेले/नवीन files** तुमच्या repo मध्ये upload करा (जुन्या
files ला overwrite करा):

**नवीन files:**
- `keystore/debug.keystore` (हा एक binary file आहे — नीट upload होतो का बघा)
- `lib/models/category_model.dart`
- `lib/utils/icon_options.dart`
- `lib/utils/app_language.dart`
- `lib/utils/export_service.dart`
- `lib/screens/categories_screen.dart`
- `lib/screens/pin_screens.dart`

**बदललेले files:**
- `pubspec.yaml`
- `.github/workflows/build.yml`
- `lib/main.dart`
- `lib/db/db_helper.dart`
- `lib/models/transaction_model.dart`
- `lib/services/drive_service.dart`
- `lib/utils/app_state.dart`
- `lib/screens/splash_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/add_edit_screen.dart`
- `lib/widgets/transaction_tile.dart`
- `lib/screens/reports_screen.dart`

**सगळ्यात सोपं:** मी दिलेली संपूर्ण नवीन zip file extract करून, त्यातलं संपूर्ण
content (सगळे folders सकट) परत GitHub वर drag-drop करा — जुनी सगळी नावं तशीच
असल्यामुळे आपोआप overwrite होतील. मग "Commit changes" दाबा, Actions आपोआप
नवीन build सुरू करेल.
