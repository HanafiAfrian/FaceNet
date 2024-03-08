import 'dart:convert';

class User {
  String nip;

  String user;
  String password;
  List modelData;

  User({
    required this.nip,
    required this.user,
    required this.password,
    required this.modelData,
  });

  static User fromMap(Map<String, dynamic> user) {
    return new User(
      nip: user['nip'],
      user: user['user'],
      password: user['password'],
      modelData: jsonDecode(user['model_data']),
    );
  }

  toMap() {
    return {
      'nip': nip,
      'user': user,
      'password': password,
      'model_data': jsonEncode(modelData),
    };
  }
}
