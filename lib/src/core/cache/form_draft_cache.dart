class FormDraftCache {
  final Map<String, Map<String, String>> _drafts =
      <String, Map<String, String>>{};

  String? getValue(String scope, String key) {
    return _drafts[scope]?[key];
  }

  void setValue(String scope, String key, String value) {
    final Map<String, String> scoped = _drafts.putIfAbsent(
      scope,
      () => <String, String>{},
    );
    scoped[key] = value;
  }

  void clearScope(String scope) {
    _drafts.remove(scope);
  }
}
