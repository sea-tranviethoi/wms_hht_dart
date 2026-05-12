// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginRequest _$LoginRequestFromJson(Map<String, dynamic> json) => LoginRequest(
      emailAddress: json['emailAddress'] as String,
      password: json['password'] as String,
      remember: json['remember'] as bool?,
    );

Map<String, dynamic> _$LoginRequestToJson(LoginRequest instance) {
  final val = <String, dynamic>{
    'emailAddress': instance.emailAddress,
    'password': instance.password,
  };

  void writeNotNull(String key, dynamic value) {
    if (value != null) {
      val[key] = value;
    }
  }

  writeNotNull('remember', instance.remember);
  return val;
}
