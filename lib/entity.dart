class Entity {

  Map<String, dynamic> _backingFields;
  Map<String, dynamic> get backingFields {
    if (_backingFields == null) {
      _backingFields = {};
    }
    return _backingFields;
  }

}