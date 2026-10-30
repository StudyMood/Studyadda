import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/pdf_resource.dart';
import '../models/subject.dart';
import '../models/unit.dart';
import '../models/video_lecture.dart';
import '../services/crypto_service.dart';
import '../services/media_resolver_service.dart';
import '../services/storage_service.dart';

class IndexedLecture {
  final VideoLecture video;
  final String subjectName;
  final String unitName;
  final int subjectIndex;
  final int unitIndex;
  final String haystack;

  IndexedLecture({
    required this.video,
    required this.subjectName,
    required this.unitName,
    required this.subjectIndex,
    required this.unitIndex,
    required this.haystack,
  });
}

class CatalogProvider extends ChangeNotifier {
  final CryptoService _cryptoService;
  final StorageService _storageService;

  bool _isUnlocked = false;
  bool _isUnlocking = false;
  String? _errorMessage;
  String _searchQuery = '';

  List<CourseSubject> _subjects = [];
  final List<IndexedLecture> _flatLectures = [];
  final Map<String, VideoLecture> _byKey = {};
  Map<String, dynamic> _apps = {};
  String? _tgEncrypted;
  String? _decryptedTelegramLink;

  SecretKey? _masterKey;
  Uint8List? _salt;
  int _iterations = 600000;
  String? _catalogCiphertext;

  CatalogProvider(this._cryptoService, this._storageService) {
    _loadEncryptedMetadata();
  }

  bool get isUnlocked => _isUnlocked;
  bool get isUnlocking => _isUnlocking;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  List<CourseSubject> get subjects => _subjects;
  List<IndexedLecture> get flatLectures => _flatLectures;
  String? get telegramLink => _decryptedTelegramLink;
  String get accessPassword => _storageService.getAccessPassword();

  List<PdfResource> _pdfResources = [];
  List<PdfResource> get pdfResources => _pdfResources;

  List<IndexedLecture> get searchResults {
    if (_searchQuery.trim().isEmpty) return [];
    final terms = _searchQuery.toLowerCase().split(' ').where((s) => s.isNotEmpty).toList();
    return _flatLectures.where((item) {
      return terms.every((term) => item.haystack.contains(term));
    }).toList();
  }

  Future<void> _loadEncryptedMetadata() async {
    try {
      final jsonString = await rootBundle.loadString('assets/encrypted_catalog.json');
      final data = json.decode(jsonString) as Map<String, dynamic>;
      final sBase64 = data['s'] as String;
      _salt = Uint8List.fromList(base64.decode(sBase64));
      _iterations = (data['i'] as int?) ?? 600000;
      _catalogCiphertext = data['c'] as String;

      _loadPdfResources();

      // Check if Admin has published a custom catalog
      final customCat = _storageService.getCustomCatalog();
      if (customCat != null && customCat.isNotEmpty) {
        _loadCustomCatalogJson(customCat);
      } else {
        // Auto-unlock if password was saved
        final savedPw = _storageService.getSavedPassword();
        if (savedPw != null && savedPw.isNotEmpty) {
          unlock(savedPw, rememberPassword: true);
        }
      }
    } catch (e) {
      debugPrint('Error loading encrypted metadata: $e');
    }
  }

  void _loadCustomCatalogJson(String jsonStr) {
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final rawSubjects = data['subjects'] as List? ?? [];
      _subjects = rawSubjects
          .map((item) => CourseSubject.fromJson(item as Map<String, dynamic>))
          .toList();
      if (data['telegram'] != null) {
        _decryptedTelegramLink = data['telegram'] as String;
      }
      _buildIndex();
      _isUnlocked = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading custom catalog: $e');
    }
  }

  void _loadPdfResources() {
    try {
      final rawList = _storageService.getPdfResourcesRaw();
      if (rawList.isNotEmpty) {
        _pdfResources = rawList
            .map((item) => PdfResource.fromJson(json.decode(item) as Map<String, dynamic>))
            .toList();
      } else {
        _pdfResources = [
          PdfResource(
            id: 'pdf_ds_1',
            title: 'Data Structures Hand-Written Notes (Arrays, Stacks, Queues, Trees)',
            subjectName: 'DATA STRUCTURES (DS)',
            unitName: 'Unit 1: Arrays & Linked Lists',
            url: 'https://t.me/StudyHubOfficialNotes',
            fileSize: '4.8 MB',
          ),
          PdfResource(
            id: 'pdf_py_1',
            title: 'Python 3 Complete CheatSheet & Quick Revision Formula Notes',
            subjectName: 'PYTHON 2.0',
            unitName: 'Unit 1: Python Fundamentals & Data Types',
            url: 'https://t.me/StudyHubOfficialNotes',
            fileSize: '2.3 MB',
          ),
          PdfResource(
            id: 'pdf_m1_1',
            title: 'Math 1.0 Engineering Matrices & Eigenvalues Solved Formula Sheet',
            subjectName: 'MATH 1.0',
            unitName: 'Unit 1: Matrices & Linear Algebra',
            url: 'https://t.me/StudyHubOfficialNotes',
            fileSize: '3.1 MB',
          ),
          PdfResource(
            id: 'pdf_coa_1',
            title: 'COA Von Neumann Architecture & Micro-operations Solved Papers',
            subjectName: 'COA 1.0 (Computer Organization)',
            unitName: 'Unit 1: Basic Computer Organization',
            url: 'https://t.me/StudyHubOfficialNotes',
            fileSize: '5.2 MB',
          ),
        ];
        _savePdfResources();
      }
    } catch (e) {
      debugPrint('Error loading PDF resources: $e');
    }
  }

  Future<bool> unlock(String password, {bool rememberPassword = false}) async {
    final trimmed = password.trim();
    if (trimmed.isEmpty) {
      _errorMessage = 'Please enter an access password.';
      notifyListeners();
      return false;
    }

    _isUnlocking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (_salt == null || _catalogCiphertext == null) {
        await _loadEncryptedMetadata();
      }

      // Check if user entered the short access passcode (default: 1234)
      final configuredPw = _storageService.getAccessPassword();
      if (trimmed == configuredPw || trimmed == '1234') {
        final customCat = _storageService.getCustomCatalog();
        if (customCat != null && customCat.isNotEmpty) {
          _loadCustomCatalogJson(customCat);
        } else if (_subjects.isEmpty) {
          loadSampleData();
        }

        if (rememberPassword) {
          await _storageService.setSavedPassword(trimmed);
        } else {
          await _storageService.setSavedPassword(null);
        }

        _isUnlocked = true;
        _isUnlocking = false;
        _errorMessage = null;
        notifyListeners();
        return true;
      }

      // Cryptographic decryption for original guide format
      final key = await _cryptoService.deriveMasterKey(password, _salt!, _iterations);
      final decryptedJson = await _cryptoService.openBox(
        masterKey: key,
        salt: _salt!,
        info: 'cat',
        aad: 'catalog',
        base64Payload: _catalogCiphertext!,
      );

      final cat = json.decode(decryptedJson) as Map<String, dynamic>;
      _masterKey = key;
      _apps = cat['apps'] as Map<String, dynamic>? ?? {};
      _tgEncrypted = cat['p'] as String?;

      final rawSubjects = cat['subjects'] as List? ?? [];
      _subjects = rawSubjects
          .map((item) => CourseSubject.fromJson(item as Map<String, dynamic>))
          .toList();

      _buildIndex();

      if (rememberPassword) {
        await _storageService.setSavedPassword(password);
      } else {
        await _storageService.setSavedPassword(null);
      }

      _isUnlocked = true;
      _isUnlocking = false;
      _errorMessage = null;

      // Resolve Telegram notes in background
      _resolveTelegramLink();

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Decryption error: $e');
      _errorMessage = 'Incorrect passcode! Passcode is 1234.';
      _isUnlocking = false;
      notifyListeners();
      return false;
    }
  }

  void _buildIndex() {
    _flatLectures.clear();
    _byKey.clear();

    for (int si = 0; si < _subjects.length; si++) {
      final s = _subjects[si];
      for (int ui = 0; ui < s.units.length; ui++) {
        final u = s.units[ui];
        for (final v in u.videos) {
          final haystack = [
            s.name,
            u.name,
            v.title,
            v.lectureNumber != null ? 'l${v.lectureNumber} lec ${v.lectureNumber} lecture ${v.lectureNumber}' : '',
            v.tags ?? '',
          ].join(' ').toLowerCase();

          final item = IndexedLecture(
            video: v,
            subjectName: s.name,
            unitName: u.name,
            subjectIndex: si,
            unitIndex: ui,
            haystack: haystack,
          );
          _flatLectures.add(item);
          _byKey[v.key] = v;
        }
      }
    }
  }

  Future<void> _resolveTelegramLink() async {
    if (_masterKey == null || _salt == null || _tgEncrypted == null) return;
    try {
      _decryptedTelegramLink = await _cryptoService.openBox(
        masterKey: _masterKey!,
        salt: _salt!,
        info: 'tg',
        aad: 'tg',
        base64Payload: _tgEncrypted!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to decrypt telegram link: $e');
    }
  }

  Future<String?> resolveVideoUrl(VideoLecture video) async {
    if (video.resolvedUrl != null && video.resolvedUrl!.isNotEmpty) {
      return video.resolvedUrl;
    }

    if (_masterKey == null || _salt == null || video.encryptedId == null) {
      return null;
    }

    try {
      final id = await _cryptoService.openBox(
        masterKey: _masterKey!,
        salt: _salt!,
        info: 'id|${video.key}',
        aad: video.title,
        base64Payload: video.encryptedId!,
      );

      final app = video.appKey != null ? _apps[video.appKey] : null;
      final mediaUrl = MediaResolverService.resolveMediaUrl(app, id);
      video.resolvedUrl = mediaUrl;
      notifyListeners();
      return mediaUrl;
    } catch (e) {
      debugPrint('Error resolving video url: $e');
      return null;
    }
  }

  void loadSampleData() {
    _subjects = [
      CourseSubject(
        name: 'DATA STRUCTURES (DS)',
        units: [
          CourseUnit(
            name: 'Unit 1: Arrays & Linked Lists',
            videos: [
              VideoLecture(
                key: 'ds_u1_l1',
                title: 'DS UNIT - 1 L-1 Introduction to Data Structures & Space/Time Complexity',
                lectureNumber: 1,
                resolvedUrl: 'https://www.youtube.com/watch?v=RBSGKlAvoiM',
              ),
              VideoLecture(
                key: 'ds_u1_l2',
                title: 'DS UNIT - 1 L-2 Dynamic Arrays & Amortized Analysis',
                lectureNumber: 2,
                resolvedUrl: 'https://www.youtube.com/watch?v=RBSGKlAvoiM',
              ),
              VideoLecture(
                key: 'ds_u1_l3',
                title: 'DS UNIT - 1 L-3 Singly & Doubly Linked List Operations',
                lectureNumber: 3,
                resolvedUrl: 'https://www.youtube.com/watch?v=RBSGKlAvoiM',
              ),
            ],
          ),
          CourseUnit(
            name: 'Unit 2: Stacks & Queues',
            videos: [
              VideoLecture(
                key: 'ds_u2_l1',
                title: 'DS UNIT - 2 L-1 Stack Implementation using Arrays & Lists',
                lectureNumber: 1,
                resolvedUrl: 'https://www.youtube.com/watch?v=RBSGKlAvoiM',
              ),
              VideoLecture(
                key: 'ds_u2_l2',
                title: 'DS UNIT - 2 L-2 Circular Queue & Deque in Action',
                lectureNumber: 2,
                resolvedUrl: 'https://www.youtube.com/watch?v=RBSGKlAvoiM',
              ),
            ],
          ),
        ],
      ),
      CourseSubject(
        name: 'PYTHON 2.0',
        units: [
          CourseUnit(
            name: 'Unit 1: Python Fundamentals & Data Types',
            videos: [
              VideoLecture(
                key: 'py_u1_l1',
                title: 'PYTHON 2.0 UNIT - 1 L-1 Python 3 Setup, Variables & Operators',
                lectureNumber: 1,
                resolvedUrl: 'https://www.youtube.com/watch?v=rfscVS0vtbw',
              ),
              VideoLecture(
                key: 'py_u1_l2',
                title: 'PYTHON 2.0 UNIT - 1 L-2 Control Flow & Functions',
                lectureNumber: 2,
                resolvedUrl: 'https://www.youtube.com/watch?v=rfscVS0vtbw',
              ),
            ],
          ),
          CourseUnit(
            name: 'Unit 2: OOP & Exception Handling',
            videos: [
              VideoLecture(
                key: 'py_u2_l1',
                title: 'PYTHON 2.0 UNIT - 2 L-1 Classes, Objects, Inheritance & Polymorphism',
                lectureNumber: 1,
                resolvedUrl: 'https://www.youtube.com/watch?v=rfscVS0vtbw',
              ),
            ],
          ),
        ],
      ),
      CourseSubject(
        name: 'MATH 1.0',
        units: [
          CourseUnit(
            name: 'Unit 1: Matrices & Linear Algebra',
            videos: [
              VideoLecture(
                key: 'm1_u1_l1',
                title: 'MATH 1.0 UNIT - 1 L-1 Eigenvalues & Eigenvectors',
                lectureNumber: 1,
                resolvedUrl: 'https://www.youtube.com/watch?v=fNk_zzaMoSs',
              ),
              VideoLecture(
                key: 'm1_u1_l2',
                title: 'MATH 1.0 UNIT - 1 L-2 Cayley Hamilton Theorem & Diagonalization',
                lectureNumber: 2,
                resolvedUrl: 'https://www.youtube.com/watch?v=fNk_zzaMoSs',
              ),
            ],
          ),
        ],
      ),
      CourseSubject(
        name: 'COA 1.0 (Computer Organization)',
        units: [
          CourseUnit(
            name: 'Unit 1: Basic Computer Organization',
            videos: [
              VideoLecture(
                key: 'coa_u1_l1',
                title: 'COA 1.0 UNIT - 1 L-1 Von Neumann Architecture & Bus Structures',
                lectureNumber: 1,
                resolvedUrl: 'https://www.youtube.com/watch?v=So9SR3ypgkM',
              ),
            ],
          ),
        ],
      ),
    ];

    _decryptedTelegramLink = 'https://t.me/StudyHubOfficialNotes';
    _buildIndex();
    _isUnlocked = true;
    _isUnlocking = false;
    _errorMessage = null;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  void lock() {
    _isUnlocked = false;
    _masterKey = null;
    _subjects.clear();
    _flatLectures.clear();
    _byKey.clear();
    _storageService.setSavedPassword(null);
    notifyListeners();
  }

  // ==========================================
  // --- ADMIN COURSE & MEDIA MANAGEMENT ---
  // ==========================================

  Future<void> saveCatalogChanges() async {
    final list = _subjects.map((s) => s.toJson()).toList();
    final jsonStr = json.encode({
      'subjects': list,
      'telegram': _decryptedTelegramLink,
    });
    await _storageService.saveCustomCatalog(jsonStr);
    _buildIndex();
    notifyListeners();
  }

  void addSubject(String name) {
    if (name.trim().isEmpty) return;
    _subjects.add(CourseSubject(name: name.trim(), units: []));
    saveCatalogChanges();
  }

  void updateSubject(int index, String newName) {
    if (index < 0 || index >= _subjects.length || newName.trim().isEmpty) return;
    final old = _subjects[index];
    _subjects[index] = CourseSubject(name: newName.trim(), units: old.units);
    saveCatalogChanges();
  }

  void deleteSubject(int index) {
    if (index < 0 || index >= _subjects.length) return;
    _subjects.removeAt(index);
    saveCatalogChanges();
  }

  void addUnit(int subjectIndex, String unitName) {
    if (subjectIndex < 0 || subjectIndex >= _subjects.length || unitName.trim().isEmpty) return;
    final subject = _subjects[subjectIndex];
    subject.units.add(CourseUnit(name: unitName.trim(), videos: []));
    saveCatalogChanges();
  }

  void updateUnit(int subjectIndex, int unitIndex, String newName) {
    if (subjectIndex < 0 || subjectIndex >= _subjects.length) return;
    final subject = _subjects[subjectIndex];
    if (unitIndex < 0 || unitIndex >= subject.units.length || newName.trim().isEmpty) return;
    final oldUnit = subject.units[unitIndex];
    subject.units[unitIndex] = CourseUnit(name: newName.trim(), videos: oldUnit.videos);
    saveCatalogChanges();
  }

  void deleteUnit(int subjectIndex, int unitIndex) {
    if (subjectIndex < 0 || subjectIndex >= _subjects.length) return;
    final subject = _subjects[subjectIndex];
    if (unitIndex < 0 || unitIndex >= subject.units.length) return;
    subject.units.removeAt(unitIndex);
    saveCatalogChanges();
  }

  void addVideo(int subjectIndex, int unitIndex, VideoLecture video) {
    if (subjectIndex < 0 || subjectIndex >= _subjects.length) return;
    final subject = _subjects[subjectIndex];
    if (unitIndex < 0 || unitIndex >= subject.units.length) return;
    subject.units[unitIndex].videos.add(video);
    saveCatalogChanges();
  }

  void updateVideo(int subjectIndex, int unitIndex, int videoIndex, VideoLecture video) {
    if (subjectIndex < 0 || subjectIndex >= _subjects.length) return;
    final subject = _subjects[subjectIndex];
    if (unitIndex < 0 || unitIndex >= subject.units.length) return;
    if (videoIndex < 0 || videoIndex >= subject.units[unitIndex].videos.length) return;
    subject.units[unitIndex].videos[videoIndex] = video;
    saveCatalogChanges();
  }

  void deleteVideo(int subjectIndex, int unitIndex, int videoIndex) {
    if (subjectIndex < 0 || subjectIndex >= _subjects.length) return;
    final subject = _subjects[subjectIndex];
    if (unitIndex < 0 || unitIndex >= subject.units.length) return;
    if (videoIndex < 0 || videoIndex >= subject.units[unitIndex].videos.length) return;
    subject.units[unitIndex].videos.removeAt(videoIndex);
    saveCatalogChanges();
  }

  // --- PDF Resources Management ---
  void addPdfResource(PdfResource resource) {
    _pdfResources.add(resource);
    _savePdfResources();
    notifyListeners();
  }

  void updatePdfResource(int index, PdfResource resource) {
    if (index >= 0 && index < _pdfResources.length) {
      _pdfResources[index] = resource;
      _savePdfResources();
      notifyListeners();
    }
  }

  void deletePdfResource(String id) {
    _pdfResources.removeWhere((item) => item.id == id);
    _savePdfResources();
    notifyListeners();
  }

  Future<void> _savePdfResources() async {
    final list = _pdfResources.map((p) => json.encode(p.toJson())).toList();
    await _storageService.savePdfResourcesRaw(list);
  }

  void updateTelegramLink(String link) {
    _decryptedTelegramLink = link.trim();
    saveCatalogChanges();
  }

  // --- Admin PIN ---
  bool verifyAdminPin(String pin) {
    return _storageService.getAdminPin() == pin.trim();
  }

  Future<void> updateAdminPin(String newPin) async {
    if (newPin.trim().isNotEmpty) {
      await _storageService.setAdminPin(newPin.trim());
      notifyListeners();
    }
  }

  // --- Student Access Password ---
  Future<void> updateAccessPassword(String newPw) async {
    if (newPw.trim().isNotEmpty) {
      await _storageService.setAccessPassword(newPw.trim());
      notifyListeners();
    }
  }

  // --- Export & Import ---
  String exportCatalogJson() {
    final list = _subjects.map((s) => s.toJson()).toList();
    final pdfList = _pdfResources.map((p) => p.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'version': '1.0',
      'telegram': _decryptedTelegramLink ?? 'https://t.me/StudyHubOfficialNotes',
      'subjects': list,
      'pdfResources': pdfList,
    });
  }

  Future<bool> importCatalogJson(String jsonStr) async {
    try {
      final data = json.decode(jsonStr) as Map<String, dynamic>;
      final rawSubjects = data['subjects'] as List? ?? [];
      _subjects = rawSubjects
          .map((item) => CourseSubject.fromJson(item as Map<String, dynamic>))
          .toList();

      if (data['telegram'] != null) {
        _decryptedTelegramLink = data['telegram'] as String;
      }

      if (data['pdfResources'] != null) {
        final rawPdfs = data['pdfResources'] as List? ?? [];
        _pdfResources = rawPdfs
            .map((item) => PdfResource.fromJson(item as Map<String, dynamic>))
            .toList();
        await _savePdfResources();
      }

      await saveCatalogChanges();
      _isUnlocked = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to import catalog: $e');
      return false;
    }
  }

  Future<void> resetToSampleCatalog() async {
    await _storageService.saveCustomCatalog(null);
    loadSampleData();
  }

  void ensureAdminReady() {
    if (_subjects.isEmpty) {
      loadSampleData();
    }
  }
}
