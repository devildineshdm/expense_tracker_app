import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

// Ha service Google Drive var data backup/restore karnyasathi ahe
// "appDataFolder" vaparto - ha ek hidden folder asto jo user la
// Drive madhe disat nahi, pan tyach app la access karta yeto.
// Yamule user cha Drive account safe rahto, purna Drive access lagat nahi.
class DriveService {
  static final DriveService _instance = DriveService._internal();
  factory DriveService() => _instance;
  DriveService._internal();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      drive.DriveApi.driveAppdataScope,
      drive.DriveApi.driveFileScope, // Bill/receipt photos upload karnyasathi
    ],
  );

  GoogleSignInAccount? _currentUser;
  static const String _backupFileName = 'expense_tracker_backup.json';

  GoogleSignInAccount? get currentUser => _currentUser;
  bool get isSignedIn => _currentUser != null;

  // Gmail ne login karnyasathi
  Future<GoogleSignInAccount?> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      return _currentUser;
    } catch (e) {
      throw Exception('Google Sign-In fail jhala: $e');
    }
  }

  // Silent login - app parat ughadla ki aadhi login kela asel tar
  // automatically sign in karnyasathi (Splash screen var use hoto)
  Future<GoogleSignInAccount?> trySilentSignIn() async {
    try {
      _currentUser = await _googleSignIn.signInSilently();
      return _currentUser;
    } catch (e) {
      return null;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
  }

  Future<drive.DriveApi> _getDriveApi() async {
    if (_currentUser == null) {
      throw Exception('Aadhi Google ne login kara');
    }
    final authHeaders = await _currentUser!.authHeaders;
    final client = _GoogleAuthClient(authHeaders);
    return drive.DriveApi(client);
  }

  // Data cha JSON banvun Google Drive च्या appDataFolder madhe upload/update karto
  // payload madhye {'transactions': [...], 'categories': [...]} asa combined data ahe
  Future<void> backupData(Map<String, dynamic> payload) async {
    final driveApi = await _getDriveApi();
    final jsonString = jsonEncode(payload);
    final bytes = utf8.encode(jsonString);
    final media = drive.Media(
      Stream.value(bytes),
      bytes.length,
      contentType: 'application/json',
    );

    // Aadhi backup file aahe ka te check karto
    final existingFileId = await _findBackupFileId(driveApi);

    if (existingFileId != null) {
      // Aadhichi file update karto
      await driveApi.files.update(
        drive.File(),
        existingFileId,
        uploadMedia: media,
      );
    } else {
      // Navin backup file banवतो
      final fileMetadata = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];
      await driveApi.files.create(fileMetadata, uploadMedia: media);
    }
  }

  // Drive var backup file shodhnyasathi, tichi id parat karto
  Future<String?> _findBackupFileId(drive.DriveApi driveApi) async {
    final fileList = await driveApi.files.list(
      spaces: 'appDataFolder',
      q: "name = '$_backupFileName'",
    );
    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first.id;
    }
    return null;
  }

  // Google Drive varun backup data parat milvnyasathi (restore)
  // Jar backup nasel tar null परत deto. Result: {'transactions': [...], 'categories': [...]}
  Future<Map<String, dynamic>?> restoreData() async {
    final driveApi = await _getDriveApi();
    final fileId = await _findBackupFileId(driveApi);
    if (fileId == null) return null;

    final media = await driveApi.files.get(
      fileId,
      downloadOptions: drive.DownloadOptions.fullMedia,
    ) as drive.Media;

    final bytes = <int>[];
    await for (final chunk in media.stream) {
      bytes.addAll(chunk);
    }
    final jsonString = utf8.decode(bytes);
    final decoded = jsonDecode(jsonString);

    // Junya backup format sathi backward-compatibility (fakt list hoti tar)
    if (decoded is List) {
      return {
        'transactions': decoded.cast<Map<String, dynamic>>(),
        'categories': <Map<String, dynamic>>[],
      };
    }
    return Map<String, dynamic>.from(decoded);
  }

  // Shevatcha backup kadhi zala te check karnyasathi (Drive file cha modifiedTime)
  Future<DateTime?> getLastBackupTime() async {
    final driveApi = await _getDriveApi();
    final fileId = await _findBackupFileId(driveApi);
    if (fileId == null) return null;
    final file = await driveApi.files.get(
      fileId,
      $fields: 'modifiedTime',
    ) as drive.File;
    return file.modifiedTime;
  }

  // ---------- RECEIPT / BILL PHOTO UPLOAD ----------
  // He photos "appDataFolder" madhe nahi, tar normal (app-created, visible)
  // files mhanun jातात, jyala user "expense_tracker_receipts" folder madhe
  // Drive var baghu shakto (jar directly Drive ughadli tar).
  String? _receiptsFolderId;

  Future<String> _getOrCreateReceiptsFolder(drive.DriveApi driveApi) async {
    if (_receiptsFolderId != null) return _receiptsFolderId!;
    final list = await driveApi.files.list(
      q: "name = 'ExpenseTracker_Receipts' and mimeType = 'application/vnd.google-apps.folder' and trashed = false",
      spaces: 'drive',
    );
    if (list.files != null && list.files!.isNotEmpty) {
      _receiptsFolderId = list.files!.first.id;
      return _receiptsFolderId!;
    }
    final folder = drive.File()
      ..name = 'ExpenseTracker_Receipts'
      ..mimeType = 'application/vnd.google-apps.folder';
    final created = await driveApi.files.create(folder);
    _receiptsFolderId = created.id;
    return _receiptsFolderId!;
  }

  // Receipt cha photo Drive var upload karto, tyachi Drive file id parat deto
  Future<String> uploadReceiptImage(List<int> bytes, String fileName) async {
    final driveApi = await _getDriveApi();
    final folderId = await _getOrCreateReceiptsFolder(driveApi);
    final media = drive.Media(Stream.value(bytes), bytes.length,
        contentType: 'image/jpeg');
    final fileMetadata = drive.File()
      ..name = fileName
      ..parents = [folderId];
    final created =
        await driveApi.files.create(fileMetadata, uploadMedia: media);
    return created.id!;
  }

  Future<void> deleteReceiptImage(String fileId) async {
    try {
      final driveApi = await _getDriveApi();
      await driveApi.files.delete(fileId);
    } catch (e) {
      // fail zala tar ignore karto, receipt aadhich delete zali असेल
    }
  }
}

// google_sign_in cha auth header http.Client sobat jodnyasathi helper class
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
