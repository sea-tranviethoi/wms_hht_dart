import 'package:json_annotation/json_annotation.dart';

part 'login_request.g.dart';

@JsonSerializable()
class LoginRequest {
  @JsonKey(name: 'emailAddress')
  final String emailAddress;
  
  @JsonKey(name: 'password')
  final String password;
  
  @JsonKey(name: 'remember', includeIfNull: false)
  final bool? remember;

  LoginRequest({
    required this.emailAddress,
    required this.password,
    this.remember,
  });

  factory LoginRequest.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestFromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestToJson(this);
}

