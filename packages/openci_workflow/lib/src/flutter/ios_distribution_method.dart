enum IosDistributionMethod {
  adHoc;

  String toArchiveMethod() => switch (this) {
    IosDistributionMethod.adHoc => 'ad-hoc',
  };
}
