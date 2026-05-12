// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      flag: json['flag'] as bool,
      token: json['token'] as String?,
      refreshToken: json['refreshToken'] as String?,
      message: json['message'] as String?,
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) {
  final val = <String, dynamic>{
    'flag': instance.flag,
    'token': instance.token,
    'refreshToken': instance.refreshToken,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('message', instance.message);
  return val;
}
