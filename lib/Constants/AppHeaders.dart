import 'package:mathlab_admin/main.dart';

Map<String, String> get AuthHeader => {
  'Accept': 'application/json',
  "Content-Type": "application/json",
  "Authorization": "Token $token",
};

Map<String, String> get ImageHeader => {
  'Accept': 'application/json',
  "Authorization": "Token $token",
};
