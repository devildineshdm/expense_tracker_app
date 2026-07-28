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
    scopes: [drive.DriveApi.driveAppdataScope],
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
  Future<void> backupData(List<Map<String, dynamic>> allTransactions) async {
    final driveApi = await _getDriveApi();
    final jsonString = jsonEncode(allTransactions);
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
  // Jar backup nasel tar null परत deto
  Future<List<Map<String, dynamic>>?> restoreData() async {
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
    final List<dynamic> decoded = jsonDecode(jsonString);
    return decoded.cast<Map<String, dynamic>>();
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
