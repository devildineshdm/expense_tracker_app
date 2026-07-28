# Expense Tracker App — Build करण्यासाठी संपूर्ण मार्गदर्शन

नमस्कार भाऊ! हा तुमच्या Personal Income/Expense Tracker app चा संपूर्ण source code आहे,
ज्यामध्ये **Google Drive backup/restore** पण आहे — म्हणजे app uninstall करून परत त्याच
Gmail ने login केलं की तुमचा सगळा data परत येईल.

खाली दिलेले steps एकदाच, क्रमाने करा.

---

## टप्पा 1: आवश्यक Software Install करा

1. **Flutter SDK** install करा: https://docs.flutter.dev/get-started/install
   (तुमच्या OS नुसार — Windows/Mac/Linux — instructions दिलेले आहेत)
2. **Android Studio** install करा: https://developer.android.com/studio
3. Install झाल्यावर terminal/command prompt मध्ये टाइप करा:
   ```
   flutter doctor
   ```
   हे command सगळं व्यवस्थित install झालंय का ते check करतं. काही "✗" (cross) दिसलं
   तर ते fix करा (उदा. Android licenses साठी `flutter doctor --android-licenses`)

---

## टप्पा 2: Project तयार करा

1. Terminal मध्ये एक folder बनवा जिथे तुम्हाला project ठेवायचंय, आणि तिथे जा:
   ```
   flutter create expense_tracker
   cd expense_tracker
   ```
   हे command Flutter चा standard project structure (android/, ios/ फोल्डर्ससकट) बनवेल.

2. आता मी दिलेल्या files copy करा:
   - मी दिलेला **`pubspec.yaml`** फाईल घ्या आणि project मधल्या `pubspec.yaml` ला
     **replace** करा (पूर्ण overwrite करा).
   - मी दिलेला संपूर्ण **`lib/`** folder घ्या आणि project मधल्या `lib/` folder ला
     **replace** करा (जुना content काढून नवीन टाका).

3. Terminal मध्ये project folder मध्ये जाऊन dependencies install करा:
   ```
   flutter pub get
   ```

---

## टप्पा 3: Google Drive Backup साठी Setup (एकदाच करायचं)

Google Drive backup काम करण्यासाठी तुम्हाला स्वतःचा एक छोटासा Google Cloud project
बनवावा लागेल. काळजी करू नका, हे मोफत आहे आणि 10-15 मिनिटं लागतील.

1. https://console.cloud.google.com वर जा, नवीन Project बनवा (उदा. नाव: "MyExpenseTracker")

2. डाव्या मेनूतून **"APIs & Services" > "Library"** मध्ये जा, **"Google Drive API"**
   शोधून **Enable** करा.

3. **"APIs & Services" > "OAuth consent screen"** मध्ये जा:
   - User Type: **External** निवडा
   - App name, तुमचा email भरा, Save करा
   - "Test users" मध्ये तुमचा स्वतःचा Gmail add करा (जो तुम्ही app मध्ये login
     करण्यासाठी वापरणार आहात)

4. तुमच्या keystore ची **SHA-1 fingerprint** काढा (हे Android ला ओळखण्यासाठी लागतं):
   ```
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```
   (Windows वर path वेगळा असू शकतो: `%USERPROFILE%\.android\debug.keystore`)
   यातून येणारा **SHA1** value copy करा.

5. **"APIs & Services" > "Credentials"** मध्ये जा > **"Create Credentials" >
   "OAuth client ID"**:
   - Application type: **Android**
   - Package name: `com.example.expense_tracker` (किंवा तुम्ही
     `android/app/build.gradle` मध्ये बदललेलं असेल तर तेच नाव टाका)
   - SHA-1 fingerprint: वरून copy केलेला टाका
   - Create करा

एवढं झालं की Google Sign-In आणि Drive backup काम करायला लागेल.

---

## टप्पा 4: APK Build करा

1. Terminal मध्ये project folder मध्ये जाऊन:
   ```
   flutter build apk --release
   ```
2. काही मिनिटांनी APK इथे तयार होईल:
   ```
   build/app/outputs/flutter-apk/app-release.apk
   ```
3. ही file तुमच्या फोनवर पाठवा (WhatsApp, USB cable, किंवा Google Drive मार्फत),
   आणि फोनवर उघडून install करा. (पहिल्यांदा "Install from unknown sources"
   permission द्यावी लागेल — फोन तसं विचारेल.)

---

## App कसं वापरायचं

- **+ नोंद करा** बटणाने income/expense entry टाका — amount, category, payment
  mode, date, note.
- वरती **cloud icon** दाबून Google ने sign-in करा — मग तुमचा data आपोआप Drive
  वर backup होत राहील (प्रत्येक नवीन entry नंतर).
- **Reports** (bar chart icon) मध्ये महिन्यानुसार आणि category नुसार charts
  दिसतील.
- App uninstall करून परत install केलं, आणि त्याच Gmail ने sign-in केलं, की
  तुमचा जुना data आपोआप परत येईल.

---

## काही अडचण आली तर

- `flutter doctor` चालवून बघा काय missing आहे.
- Google Sign-In error आला तर टप्पा 3 मधली SHA-1 fingerprint आणि package
  name नीट जुळतायत का ते तपासा.
- कुठलाही error message copy करून मला (Claude ला) परत विचारा — मी debug
  करायला मदत करेन.

शुभेच्छा! 🎉
