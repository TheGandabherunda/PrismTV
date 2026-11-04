class LanguageModel {
  final String id;
  final String title;
  final String nativeTitle;
  final int? jioLanguageId;

  const LanguageModel({
    required this.id,
    required this.title,
    required this.nativeTitle,
    this.jioLanguageId,
  });

  String get displayName => id == 'all' ? title : '$nativeTitle • $title';

  static const List<LanguageModel> defaultLanguages = [
    LanguageModel(id: 'all', title: 'All Languages', nativeTitle: 'All'),
    LanguageModel(id: 'kannada', title: 'Kannada', nativeTitle: 'ಕನ್ನಡ', jioLanguageId: 13),
    LanguageModel(id: 'english', title: 'English', nativeTitle: 'English', jioLanguageId: 6),
    LanguageModel(id: 'hindi', title: 'Hindi', nativeTitle: 'हिन्दी', jioLanguageId: 1),
    LanguageModel(id: 'tamil', title: 'Tamil', nativeTitle: 'தமிழ்', jioLanguageId: 8),
    LanguageModel(id: 'telugu', title: 'Telugu', nativeTitle: 'తెలుగు', jioLanguageId: 11),
    LanguageModel(id: 'malayalam', title: 'Malayalam', nativeTitle: 'മലയാളം', jioLanguageId: 7),
    LanguageModel(id: 'bengali', title: 'Bengali', nativeTitle: 'বাংলা', jioLanguageId: 5),
    LanguageModel(id: 'marathi', title: 'Marathi', nativeTitle: 'मराठी', jioLanguageId: 2),
    LanguageModel(id: 'gujarati', title: 'Gujarati', nativeTitle: 'ગુજરાતી', jioLanguageId: 9),
    LanguageModel(id: 'punjabi', title: 'Punjabi', nativeTitle: 'ਪੰਜਾਬੀ', jioLanguageId: 3),
    LanguageModel(id: 'odia', title: 'Odia', nativeTitle: 'ଓଡ଼ିଆ', jioLanguageId: 10),
    LanguageModel(id: 'urdu', title: 'Urdu', nativeTitle: 'اردو', jioLanguageId: 14),
    LanguageModel(id: 'bhojpuri', title: 'Bhojpuri', nativeTitle: 'भोजपुरी', jioLanguageId: 4),
    LanguageModel(id: 'assamese', title: 'Assamese', nativeTitle: 'অসমীয়া', jioLanguageId: 12),
  ];
}
