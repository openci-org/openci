import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

extension AsyncValueCombine3<T1, T2, T3>
    on (AsyncValue<T1>, AsyncValue<T2>, AsyncValue<T3>) {
  Widget when({
    required Widget Function(T1, T2, T3) data,
    required Widget Function() loading,
    required Widget Function(Object error, StackTrace stackTrace) error,
  }) {
    if ($1.isLoading || $2.isLoading || $3.isLoading) return loading();
    if ($1.hasError) return error($1.error!, $1.stackTrace!);
    if ($2.hasError) return error($2.error!, $2.stackTrace!);
    if ($3.hasError) return error($3.error!, $3.stackTrace!);
    return data($1.requireValue, $2.requireValue, $3.requireValue);
  }
}
