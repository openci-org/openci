// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'security_and_analysis.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SecurityAndAnalysis {

/// Use the `status` property to enable or disable GitHub Advanced Security for this repository.
/// For more information, see "[About GitHub Advanced.
/// Security](/github/getting-started-with-github/learning-about-github/about-github-advanced-security).".
///
/// For standalone Code Scanning or Secret Protection products, this parameter cannot be used.
@JsonKey(name: 'advanced_security') AdvancedSecurity? get advancedSecurity;/// Use the `status` property to enable or disable GitHub Code Security for this repository.
@JsonKey(name: 'code_security') CodeSecurity? get codeSecurity;/// Use the `status` property to enable or disable secret scanning for this repository. For more information, see "[About secret scanning](/code-security/secret-security/about-secret-scanning)."
@JsonKey(name: 'secret_scanning') SecretScanning? get secretScanning;/// Use the `status` property to enable or disable secret scanning push protection for this repository. For more information, see "[Protecting pushes with secret scanning](/code-security/secret-scanning/protecting-pushes-with-secret-scanning)."
@JsonKey(name: 'secret_scanning_push_protection') SecretScanningPushProtection? get secretScanningPushProtection;/// Use the `status` property to enable or disable secret scanning AI detection for this repository. For more information, see "[Responsible detection of generic secrets with AI](https://docs.github.com/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/generic-secret-detection/responsible-ai-generic-secrets)."
@JsonKey(name: 'secret_scanning_ai_detection') SecretScanningAiDetection? get secretScanningAiDetection;/// Use the `status` property to enable or disable secret scanning non-provider patterns for this repository. For more information, see "[Supported secret scanning patterns](/code-security/secret-scanning/introduction/supported-secret-scanning-patterns#supported-secrets)."
@JsonKey(name: 'secret_scanning_non_provider_patterns') SecretScanningNonProviderPatterns? get secretScanningNonProviderPatterns;/// Use the `status` property to enable or disable secret scanning delegated alert dismissal for this repository.
@JsonKey(name: 'secret_scanning_delegated_alert_dismissal') SecretScanningDelegatedAlertDismissal? get secretScanningDelegatedAlertDismissal;/// Use the `status` property to enable or disable secret scanning delegated bypass for this repository.
@JsonKey(name: 'secret_scanning_delegated_bypass') SecretScanningDelegatedBypass? get secretScanningDelegatedBypass;/// Feature options for secret scanning delegated bypass.
/// This object is only honored when `security_and_analysis.secret_scanning_delegated_bypass.status` is set to `enabled`.
/// You can send this object in the same request as `secret_scanning_delegated_bypass`, or update just the options in a separate request.
@JsonKey(name: 'secret_scanning_delegated_bypass_options') SecretScanningDelegatedBypassOptions? get secretScanningDelegatedBypassOptions;
/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SecurityAndAnalysisCopyWith<SecurityAndAnalysis> get copyWith => _$SecurityAndAnalysisCopyWithImpl<SecurityAndAnalysis>(this as SecurityAndAnalysis, _$identity);

  /// Serializes this SecurityAndAnalysis to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SecurityAndAnalysis&&(identical(other.advancedSecurity, advancedSecurity) || other.advancedSecurity == advancedSecurity)&&(identical(other.codeSecurity, codeSecurity) || other.codeSecurity == codeSecurity)&&(identical(other.secretScanning, secretScanning) || other.secretScanning == secretScanning)&&(identical(other.secretScanningPushProtection, secretScanningPushProtection) || other.secretScanningPushProtection == secretScanningPushProtection)&&(identical(other.secretScanningAiDetection, secretScanningAiDetection) || other.secretScanningAiDetection == secretScanningAiDetection)&&(identical(other.secretScanningNonProviderPatterns, secretScanningNonProviderPatterns) || other.secretScanningNonProviderPatterns == secretScanningNonProviderPatterns)&&(identical(other.secretScanningDelegatedAlertDismissal, secretScanningDelegatedAlertDismissal) || other.secretScanningDelegatedAlertDismissal == secretScanningDelegatedAlertDismissal)&&(identical(other.secretScanningDelegatedBypass, secretScanningDelegatedBypass) || other.secretScanningDelegatedBypass == secretScanningDelegatedBypass)&&(identical(other.secretScanningDelegatedBypassOptions, secretScanningDelegatedBypassOptions) || other.secretScanningDelegatedBypassOptions == secretScanningDelegatedBypassOptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,advancedSecurity,codeSecurity,secretScanning,secretScanningPushProtection,secretScanningAiDetection,secretScanningNonProviderPatterns,secretScanningDelegatedAlertDismissal,secretScanningDelegatedBypass,secretScanningDelegatedBypassOptions);

@override
String toString() {
  return 'SecurityAndAnalysis(advancedSecurity: $advancedSecurity, codeSecurity: $codeSecurity, secretScanning: $secretScanning, secretScanningPushProtection: $secretScanningPushProtection, secretScanningAiDetection: $secretScanningAiDetection, secretScanningNonProviderPatterns: $secretScanningNonProviderPatterns, secretScanningDelegatedAlertDismissal: $secretScanningDelegatedAlertDismissal, secretScanningDelegatedBypass: $secretScanningDelegatedBypass, secretScanningDelegatedBypassOptions: $secretScanningDelegatedBypassOptions)';
}


}

/// @nodoc
abstract mixin class $SecurityAndAnalysisCopyWith<$Res>  {
  factory $SecurityAndAnalysisCopyWith(SecurityAndAnalysis value, $Res Function(SecurityAndAnalysis) _then) = _$SecurityAndAnalysisCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'advanced_security') AdvancedSecurity? advancedSecurity,@JsonKey(name: 'code_security') CodeSecurity? codeSecurity,@JsonKey(name: 'secret_scanning') SecretScanning? secretScanning,@JsonKey(name: 'secret_scanning_push_protection') SecretScanningPushProtection? secretScanningPushProtection,@JsonKey(name: 'secret_scanning_ai_detection') SecretScanningAiDetection? secretScanningAiDetection,@JsonKey(name: 'secret_scanning_non_provider_patterns') SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns,@JsonKey(name: 'secret_scanning_delegated_alert_dismissal') SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal,@JsonKey(name: 'secret_scanning_delegated_bypass') SecretScanningDelegatedBypass? secretScanningDelegatedBypass,@JsonKey(name: 'secret_scanning_delegated_bypass_options') SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions
});


$AdvancedSecurityCopyWith<$Res>? get advancedSecurity;$CodeSecurityCopyWith<$Res>? get codeSecurity;$SecretScanningCopyWith<$Res>? get secretScanning;$SecretScanningPushProtectionCopyWith<$Res>? get secretScanningPushProtection;$SecretScanningAiDetectionCopyWith<$Res>? get secretScanningAiDetection;$SecretScanningNonProviderPatternsCopyWith<$Res>? get secretScanningNonProviderPatterns;$SecretScanningDelegatedAlertDismissalCopyWith<$Res>? get secretScanningDelegatedAlertDismissal;$SecretScanningDelegatedBypassCopyWith<$Res>? get secretScanningDelegatedBypass;$SecretScanningDelegatedBypassOptionsCopyWith<$Res>? get secretScanningDelegatedBypassOptions;

}
/// @nodoc
class _$SecurityAndAnalysisCopyWithImpl<$Res>
    implements $SecurityAndAnalysisCopyWith<$Res> {
  _$SecurityAndAnalysisCopyWithImpl(this._self, this._then);

  final SecurityAndAnalysis _self;
  final $Res Function(SecurityAndAnalysis) _then;

/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? advancedSecurity = freezed,Object? codeSecurity = freezed,Object? secretScanning = freezed,Object? secretScanningPushProtection = freezed,Object? secretScanningAiDetection = freezed,Object? secretScanningNonProviderPatterns = freezed,Object? secretScanningDelegatedAlertDismissal = freezed,Object? secretScanningDelegatedBypass = freezed,Object? secretScanningDelegatedBypassOptions = freezed,}) {
  return _then(_self.copyWith(
advancedSecurity: freezed == advancedSecurity ? _self.advancedSecurity : advancedSecurity // ignore: cast_nullable_to_non_nullable
as AdvancedSecurity?,codeSecurity: freezed == codeSecurity ? _self.codeSecurity : codeSecurity // ignore: cast_nullable_to_non_nullable
as CodeSecurity?,secretScanning: freezed == secretScanning ? _self.secretScanning : secretScanning // ignore: cast_nullable_to_non_nullable
as SecretScanning?,secretScanningPushProtection: freezed == secretScanningPushProtection ? _self.secretScanningPushProtection : secretScanningPushProtection // ignore: cast_nullable_to_non_nullable
as SecretScanningPushProtection?,secretScanningAiDetection: freezed == secretScanningAiDetection ? _self.secretScanningAiDetection : secretScanningAiDetection // ignore: cast_nullable_to_non_nullable
as SecretScanningAiDetection?,secretScanningNonProviderPatterns: freezed == secretScanningNonProviderPatterns ? _self.secretScanningNonProviderPatterns : secretScanningNonProviderPatterns // ignore: cast_nullable_to_non_nullable
as SecretScanningNonProviderPatterns?,secretScanningDelegatedAlertDismissal: freezed == secretScanningDelegatedAlertDismissal ? _self.secretScanningDelegatedAlertDismissal : secretScanningDelegatedAlertDismissal // ignore: cast_nullable_to_non_nullable
as SecretScanningDelegatedAlertDismissal?,secretScanningDelegatedBypass: freezed == secretScanningDelegatedBypass ? _self.secretScanningDelegatedBypass : secretScanningDelegatedBypass // ignore: cast_nullable_to_non_nullable
as SecretScanningDelegatedBypass?,secretScanningDelegatedBypassOptions: freezed == secretScanningDelegatedBypassOptions ? _self.secretScanningDelegatedBypassOptions : secretScanningDelegatedBypassOptions // ignore: cast_nullable_to_non_nullable
as SecretScanningDelegatedBypassOptions?,
  ));
}
/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdvancedSecurityCopyWith<$Res>? get advancedSecurity {
    if (_self.advancedSecurity == null) {
    return null;
  }

  return $AdvancedSecurityCopyWith<$Res>(_self.advancedSecurity!, (value) {
    return _then(_self.copyWith(advancedSecurity: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CodeSecurityCopyWith<$Res>? get codeSecurity {
    if (_self.codeSecurity == null) {
    return null;
  }

  return $CodeSecurityCopyWith<$Res>(_self.codeSecurity!, (value) {
    return _then(_self.copyWith(codeSecurity: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningCopyWith<$Res>? get secretScanning {
    if (_self.secretScanning == null) {
    return null;
  }

  return $SecretScanningCopyWith<$Res>(_self.secretScanning!, (value) {
    return _then(_self.copyWith(secretScanning: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningPushProtectionCopyWith<$Res>? get secretScanningPushProtection {
    if (_self.secretScanningPushProtection == null) {
    return null;
  }

  return $SecretScanningPushProtectionCopyWith<$Res>(_self.secretScanningPushProtection!, (value) {
    return _then(_self.copyWith(secretScanningPushProtection: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningAiDetectionCopyWith<$Res>? get secretScanningAiDetection {
    if (_self.secretScanningAiDetection == null) {
    return null;
  }

  return $SecretScanningAiDetectionCopyWith<$Res>(_self.secretScanningAiDetection!, (value) {
    return _then(_self.copyWith(secretScanningAiDetection: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningNonProviderPatternsCopyWith<$Res>? get secretScanningNonProviderPatterns {
    if (_self.secretScanningNonProviderPatterns == null) {
    return null;
  }

  return $SecretScanningNonProviderPatternsCopyWith<$Res>(_self.secretScanningNonProviderPatterns!, (value) {
    return _then(_self.copyWith(secretScanningNonProviderPatterns: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningDelegatedAlertDismissalCopyWith<$Res>? get secretScanningDelegatedAlertDismissal {
    if (_self.secretScanningDelegatedAlertDismissal == null) {
    return null;
  }

  return $SecretScanningDelegatedAlertDismissalCopyWith<$Res>(_self.secretScanningDelegatedAlertDismissal!, (value) {
    return _then(_self.copyWith(secretScanningDelegatedAlertDismissal: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningDelegatedBypassCopyWith<$Res>? get secretScanningDelegatedBypass {
    if (_self.secretScanningDelegatedBypass == null) {
    return null;
  }

  return $SecretScanningDelegatedBypassCopyWith<$Res>(_self.secretScanningDelegatedBypass!, (value) {
    return _then(_self.copyWith(secretScanningDelegatedBypass: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningDelegatedBypassOptionsCopyWith<$Res>? get secretScanningDelegatedBypassOptions {
    if (_self.secretScanningDelegatedBypassOptions == null) {
    return null;
  }

  return $SecretScanningDelegatedBypassOptionsCopyWith<$Res>(_self.secretScanningDelegatedBypassOptions!, (value) {
    return _then(_self.copyWith(secretScanningDelegatedBypassOptions: value));
  });
}
}


/// Adds pattern-matching-related methods to [SecurityAndAnalysis].
extension SecurityAndAnalysisPatterns on SecurityAndAnalysis {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SecurityAndAnalysis value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SecurityAndAnalysis() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SecurityAndAnalysis value)  $default,){
final _that = this;
switch (_that) {
case _SecurityAndAnalysis():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SecurityAndAnalysis value)?  $default,){
final _that = this;
switch (_that) {
case _SecurityAndAnalysis() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'advanced_security')  AdvancedSecurity? advancedSecurity, @JsonKey(name: 'code_security')  CodeSecurity? codeSecurity, @JsonKey(name: 'secret_scanning')  SecretScanning? secretScanning, @JsonKey(name: 'secret_scanning_push_protection')  SecretScanningPushProtection? secretScanningPushProtection, @JsonKey(name: 'secret_scanning_ai_detection')  SecretScanningAiDetection? secretScanningAiDetection, @JsonKey(name: 'secret_scanning_non_provider_patterns')  SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns, @JsonKey(name: 'secret_scanning_delegated_alert_dismissal')  SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal, @JsonKey(name: 'secret_scanning_delegated_bypass')  SecretScanningDelegatedBypass? secretScanningDelegatedBypass, @JsonKey(name: 'secret_scanning_delegated_bypass_options')  SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SecurityAndAnalysis() when $default != null:
return $default(_that.advancedSecurity,_that.codeSecurity,_that.secretScanning,_that.secretScanningPushProtection,_that.secretScanningAiDetection,_that.secretScanningNonProviderPatterns,_that.secretScanningDelegatedAlertDismissal,_that.secretScanningDelegatedBypass,_that.secretScanningDelegatedBypassOptions);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'advanced_security')  AdvancedSecurity? advancedSecurity, @JsonKey(name: 'code_security')  CodeSecurity? codeSecurity, @JsonKey(name: 'secret_scanning')  SecretScanning? secretScanning, @JsonKey(name: 'secret_scanning_push_protection')  SecretScanningPushProtection? secretScanningPushProtection, @JsonKey(name: 'secret_scanning_ai_detection')  SecretScanningAiDetection? secretScanningAiDetection, @JsonKey(name: 'secret_scanning_non_provider_patterns')  SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns, @JsonKey(name: 'secret_scanning_delegated_alert_dismissal')  SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal, @JsonKey(name: 'secret_scanning_delegated_bypass')  SecretScanningDelegatedBypass? secretScanningDelegatedBypass, @JsonKey(name: 'secret_scanning_delegated_bypass_options')  SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions)  $default,) {final _that = this;
switch (_that) {
case _SecurityAndAnalysis():
return $default(_that.advancedSecurity,_that.codeSecurity,_that.secretScanning,_that.secretScanningPushProtection,_that.secretScanningAiDetection,_that.secretScanningNonProviderPatterns,_that.secretScanningDelegatedAlertDismissal,_that.secretScanningDelegatedBypass,_that.secretScanningDelegatedBypassOptions);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'advanced_security')  AdvancedSecurity? advancedSecurity, @JsonKey(name: 'code_security')  CodeSecurity? codeSecurity, @JsonKey(name: 'secret_scanning')  SecretScanning? secretScanning, @JsonKey(name: 'secret_scanning_push_protection')  SecretScanningPushProtection? secretScanningPushProtection, @JsonKey(name: 'secret_scanning_ai_detection')  SecretScanningAiDetection? secretScanningAiDetection, @JsonKey(name: 'secret_scanning_non_provider_patterns')  SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns, @JsonKey(name: 'secret_scanning_delegated_alert_dismissal')  SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal, @JsonKey(name: 'secret_scanning_delegated_bypass')  SecretScanningDelegatedBypass? secretScanningDelegatedBypass, @JsonKey(name: 'secret_scanning_delegated_bypass_options')  SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions)?  $default,) {final _that = this;
switch (_that) {
case _SecurityAndAnalysis() when $default != null:
return $default(_that.advancedSecurity,_that.codeSecurity,_that.secretScanning,_that.secretScanningPushProtection,_that.secretScanningAiDetection,_that.secretScanningNonProviderPatterns,_that.secretScanningDelegatedAlertDismissal,_that.secretScanningDelegatedBypass,_that.secretScanningDelegatedBypassOptions);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SecurityAndAnalysis implements SecurityAndAnalysis {
  const _SecurityAndAnalysis({@JsonKey(name: 'advanced_security') this.advancedSecurity, @JsonKey(name: 'code_security') this.codeSecurity, @JsonKey(name: 'secret_scanning') this.secretScanning, @JsonKey(name: 'secret_scanning_push_protection') this.secretScanningPushProtection, @JsonKey(name: 'secret_scanning_ai_detection') this.secretScanningAiDetection, @JsonKey(name: 'secret_scanning_non_provider_patterns') this.secretScanningNonProviderPatterns, @JsonKey(name: 'secret_scanning_delegated_alert_dismissal') this.secretScanningDelegatedAlertDismissal, @JsonKey(name: 'secret_scanning_delegated_bypass') this.secretScanningDelegatedBypass, @JsonKey(name: 'secret_scanning_delegated_bypass_options') this.secretScanningDelegatedBypassOptions});
  factory _SecurityAndAnalysis.fromJson(Map<String, dynamic> json) => _$SecurityAndAnalysisFromJson(json);

/// Use the `status` property to enable or disable GitHub Advanced Security for this repository.
/// For more information, see "[About GitHub Advanced.
/// Security](/github/getting-started-with-github/learning-about-github/about-github-advanced-security).".
///
/// For standalone Code Scanning or Secret Protection products, this parameter cannot be used.
@override@JsonKey(name: 'advanced_security') final  AdvancedSecurity? advancedSecurity;
/// Use the `status` property to enable or disable GitHub Code Security for this repository.
@override@JsonKey(name: 'code_security') final  CodeSecurity? codeSecurity;
/// Use the `status` property to enable or disable secret scanning for this repository. For more information, see "[About secret scanning](/code-security/secret-security/about-secret-scanning)."
@override@JsonKey(name: 'secret_scanning') final  SecretScanning? secretScanning;
/// Use the `status` property to enable or disable secret scanning push protection for this repository. For more information, see "[Protecting pushes with secret scanning](/code-security/secret-scanning/protecting-pushes-with-secret-scanning)."
@override@JsonKey(name: 'secret_scanning_push_protection') final  SecretScanningPushProtection? secretScanningPushProtection;
/// Use the `status` property to enable or disable secret scanning AI detection for this repository. For more information, see "[Responsible detection of generic secrets with AI](https://docs.github.com/code-security/secret-scanning/using-advanced-secret-scanning-and-push-protection-features/generic-secret-detection/responsible-ai-generic-secrets)."
@override@JsonKey(name: 'secret_scanning_ai_detection') final  SecretScanningAiDetection? secretScanningAiDetection;
/// Use the `status` property to enable or disable secret scanning non-provider patterns for this repository. For more information, see "[Supported secret scanning patterns](/code-security/secret-scanning/introduction/supported-secret-scanning-patterns#supported-secrets)."
@override@JsonKey(name: 'secret_scanning_non_provider_patterns') final  SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns;
/// Use the `status` property to enable or disable secret scanning delegated alert dismissal for this repository.
@override@JsonKey(name: 'secret_scanning_delegated_alert_dismissal') final  SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal;
/// Use the `status` property to enable or disable secret scanning delegated bypass for this repository.
@override@JsonKey(name: 'secret_scanning_delegated_bypass') final  SecretScanningDelegatedBypass? secretScanningDelegatedBypass;
/// Feature options for secret scanning delegated bypass.
/// This object is only honored when `security_and_analysis.secret_scanning_delegated_bypass.status` is set to `enabled`.
/// You can send this object in the same request as `secret_scanning_delegated_bypass`, or update just the options in a separate request.
@override@JsonKey(name: 'secret_scanning_delegated_bypass_options') final  SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions;

/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SecurityAndAnalysisCopyWith<_SecurityAndAnalysis> get copyWith => __$SecurityAndAnalysisCopyWithImpl<_SecurityAndAnalysis>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SecurityAndAnalysisToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SecurityAndAnalysis&&(identical(other.advancedSecurity, advancedSecurity) || other.advancedSecurity == advancedSecurity)&&(identical(other.codeSecurity, codeSecurity) || other.codeSecurity == codeSecurity)&&(identical(other.secretScanning, secretScanning) || other.secretScanning == secretScanning)&&(identical(other.secretScanningPushProtection, secretScanningPushProtection) || other.secretScanningPushProtection == secretScanningPushProtection)&&(identical(other.secretScanningAiDetection, secretScanningAiDetection) || other.secretScanningAiDetection == secretScanningAiDetection)&&(identical(other.secretScanningNonProviderPatterns, secretScanningNonProviderPatterns) || other.secretScanningNonProviderPatterns == secretScanningNonProviderPatterns)&&(identical(other.secretScanningDelegatedAlertDismissal, secretScanningDelegatedAlertDismissal) || other.secretScanningDelegatedAlertDismissal == secretScanningDelegatedAlertDismissal)&&(identical(other.secretScanningDelegatedBypass, secretScanningDelegatedBypass) || other.secretScanningDelegatedBypass == secretScanningDelegatedBypass)&&(identical(other.secretScanningDelegatedBypassOptions, secretScanningDelegatedBypassOptions) || other.secretScanningDelegatedBypassOptions == secretScanningDelegatedBypassOptions));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,advancedSecurity,codeSecurity,secretScanning,secretScanningPushProtection,secretScanningAiDetection,secretScanningNonProviderPatterns,secretScanningDelegatedAlertDismissal,secretScanningDelegatedBypass,secretScanningDelegatedBypassOptions);

@override
String toString() {
  return 'SecurityAndAnalysis(advancedSecurity: $advancedSecurity, codeSecurity: $codeSecurity, secretScanning: $secretScanning, secretScanningPushProtection: $secretScanningPushProtection, secretScanningAiDetection: $secretScanningAiDetection, secretScanningNonProviderPatterns: $secretScanningNonProviderPatterns, secretScanningDelegatedAlertDismissal: $secretScanningDelegatedAlertDismissal, secretScanningDelegatedBypass: $secretScanningDelegatedBypass, secretScanningDelegatedBypassOptions: $secretScanningDelegatedBypassOptions)';
}


}

/// @nodoc
abstract mixin class _$SecurityAndAnalysisCopyWith<$Res> implements $SecurityAndAnalysisCopyWith<$Res> {
  factory _$SecurityAndAnalysisCopyWith(_SecurityAndAnalysis value, $Res Function(_SecurityAndAnalysis) _then) = __$SecurityAndAnalysisCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'advanced_security') AdvancedSecurity? advancedSecurity,@JsonKey(name: 'code_security') CodeSecurity? codeSecurity,@JsonKey(name: 'secret_scanning') SecretScanning? secretScanning,@JsonKey(name: 'secret_scanning_push_protection') SecretScanningPushProtection? secretScanningPushProtection,@JsonKey(name: 'secret_scanning_ai_detection') SecretScanningAiDetection? secretScanningAiDetection,@JsonKey(name: 'secret_scanning_non_provider_patterns') SecretScanningNonProviderPatterns? secretScanningNonProviderPatterns,@JsonKey(name: 'secret_scanning_delegated_alert_dismissal') SecretScanningDelegatedAlertDismissal? secretScanningDelegatedAlertDismissal,@JsonKey(name: 'secret_scanning_delegated_bypass') SecretScanningDelegatedBypass? secretScanningDelegatedBypass,@JsonKey(name: 'secret_scanning_delegated_bypass_options') SecretScanningDelegatedBypassOptions? secretScanningDelegatedBypassOptions
});


@override $AdvancedSecurityCopyWith<$Res>? get advancedSecurity;@override $CodeSecurityCopyWith<$Res>? get codeSecurity;@override $SecretScanningCopyWith<$Res>? get secretScanning;@override $SecretScanningPushProtectionCopyWith<$Res>? get secretScanningPushProtection;@override $SecretScanningAiDetectionCopyWith<$Res>? get secretScanningAiDetection;@override $SecretScanningNonProviderPatternsCopyWith<$Res>? get secretScanningNonProviderPatterns;@override $SecretScanningDelegatedAlertDismissalCopyWith<$Res>? get secretScanningDelegatedAlertDismissal;@override $SecretScanningDelegatedBypassCopyWith<$Res>? get secretScanningDelegatedBypass;@override $SecretScanningDelegatedBypassOptionsCopyWith<$Res>? get secretScanningDelegatedBypassOptions;

}
/// @nodoc
class __$SecurityAndAnalysisCopyWithImpl<$Res>
    implements _$SecurityAndAnalysisCopyWith<$Res> {
  __$SecurityAndAnalysisCopyWithImpl(this._self, this._then);

  final _SecurityAndAnalysis _self;
  final $Res Function(_SecurityAndAnalysis) _then;

/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? advancedSecurity = freezed,Object? codeSecurity = freezed,Object? secretScanning = freezed,Object? secretScanningPushProtection = freezed,Object? secretScanningAiDetection = freezed,Object? secretScanningNonProviderPatterns = freezed,Object? secretScanningDelegatedAlertDismissal = freezed,Object? secretScanningDelegatedBypass = freezed,Object? secretScanningDelegatedBypassOptions = freezed,}) {
  return _then(_SecurityAndAnalysis(
advancedSecurity: freezed == advancedSecurity ? _self.advancedSecurity : advancedSecurity // ignore: cast_nullable_to_non_nullable
as AdvancedSecurity?,codeSecurity: freezed == codeSecurity ? _self.codeSecurity : codeSecurity // ignore: cast_nullable_to_non_nullable
as CodeSecurity?,secretScanning: freezed == secretScanning ? _self.secretScanning : secretScanning // ignore: cast_nullable_to_non_nullable
as SecretScanning?,secretScanningPushProtection: freezed == secretScanningPushProtection ? _self.secretScanningPushProtection : secretScanningPushProtection // ignore: cast_nullable_to_non_nullable
as SecretScanningPushProtection?,secretScanningAiDetection: freezed == secretScanningAiDetection ? _self.secretScanningAiDetection : secretScanningAiDetection // ignore: cast_nullable_to_non_nullable
as SecretScanningAiDetection?,secretScanningNonProviderPatterns: freezed == secretScanningNonProviderPatterns ? _self.secretScanningNonProviderPatterns : secretScanningNonProviderPatterns // ignore: cast_nullable_to_non_nullable
as SecretScanningNonProviderPatterns?,secretScanningDelegatedAlertDismissal: freezed == secretScanningDelegatedAlertDismissal ? _self.secretScanningDelegatedAlertDismissal : secretScanningDelegatedAlertDismissal // ignore: cast_nullable_to_non_nullable
as SecretScanningDelegatedAlertDismissal?,secretScanningDelegatedBypass: freezed == secretScanningDelegatedBypass ? _self.secretScanningDelegatedBypass : secretScanningDelegatedBypass // ignore: cast_nullable_to_non_nullable
as SecretScanningDelegatedBypass?,secretScanningDelegatedBypassOptions: freezed == secretScanningDelegatedBypassOptions ? _self.secretScanningDelegatedBypassOptions : secretScanningDelegatedBypassOptions // ignore: cast_nullable_to_non_nullable
as SecretScanningDelegatedBypassOptions?,
  ));
}

/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AdvancedSecurityCopyWith<$Res>? get advancedSecurity {
    if (_self.advancedSecurity == null) {
    return null;
  }

  return $AdvancedSecurityCopyWith<$Res>(_self.advancedSecurity!, (value) {
    return _then(_self.copyWith(advancedSecurity: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CodeSecurityCopyWith<$Res>? get codeSecurity {
    if (_self.codeSecurity == null) {
    return null;
  }

  return $CodeSecurityCopyWith<$Res>(_self.codeSecurity!, (value) {
    return _then(_self.copyWith(codeSecurity: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningCopyWith<$Res>? get secretScanning {
    if (_self.secretScanning == null) {
    return null;
  }

  return $SecretScanningCopyWith<$Res>(_self.secretScanning!, (value) {
    return _then(_self.copyWith(secretScanning: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningPushProtectionCopyWith<$Res>? get secretScanningPushProtection {
    if (_self.secretScanningPushProtection == null) {
    return null;
  }

  return $SecretScanningPushProtectionCopyWith<$Res>(_self.secretScanningPushProtection!, (value) {
    return _then(_self.copyWith(secretScanningPushProtection: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningAiDetectionCopyWith<$Res>? get secretScanningAiDetection {
    if (_self.secretScanningAiDetection == null) {
    return null;
  }

  return $SecretScanningAiDetectionCopyWith<$Res>(_self.secretScanningAiDetection!, (value) {
    return _then(_self.copyWith(secretScanningAiDetection: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningNonProviderPatternsCopyWith<$Res>? get secretScanningNonProviderPatterns {
    if (_self.secretScanningNonProviderPatterns == null) {
    return null;
  }

  return $SecretScanningNonProviderPatternsCopyWith<$Res>(_self.secretScanningNonProviderPatterns!, (value) {
    return _then(_self.copyWith(secretScanningNonProviderPatterns: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningDelegatedAlertDismissalCopyWith<$Res>? get secretScanningDelegatedAlertDismissal {
    if (_self.secretScanningDelegatedAlertDismissal == null) {
    return null;
  }

  return $SecretScanningDelegatedAlertDismissalCopyWith<$Res>(_self.secretScanningDelegatedAlertDismissal!, (value) {
    return _then(_self.copyWith(secretScanningDelegatedAlertDismissal: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningDelegatedBypassCopyWith<$Res>? get secretScanningDelegatedBypass {
    if (_self.secretScanningDelegatedBypass == null) {
    return null;
  }

  return $SecretScanningDelegatedBypassCopyWith<$Res>(_self.secretScanningDelegatedBypass!, (value) {
    return _then(_self.copyWith(secretScanningDelegatedBypass: value));
  });
}/// Create a copy of SecurityAndAnalysis
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SecretScanningDelegatedBypassOptionsCopyWith<$Res>? get secretScanningDelegatedBypassOptions {
    if (_self.secretScanningDelegatedBypassOptions == null) {
    return null;
  }

  return $SecretScanningDelegatedBypassOptionsCopyWith<$Res>(_self.secretScanningDelegatedBypassOptions!, (value) {
    return _then(_self.copyWith(secretScanningDelegatedBypassOptions: value));
  });
}
}

// dart format on
