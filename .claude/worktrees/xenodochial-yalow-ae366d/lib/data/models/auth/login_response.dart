import 'package:json_annotation/json_annotation.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  @JsonKey(name: 'flag')
  final bool flag;
  
  @JsonKey(name: 'token')
  final String? token;
  
  @JsonKey(name: 'refreshToken')
  final String? refreshToken;
  
  @JsonKey(name: 'message', includeIfNull: false)
  final String? message;

  LoginResponse({
    required this.flag,
    this.token,
    this.refreshToken,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

