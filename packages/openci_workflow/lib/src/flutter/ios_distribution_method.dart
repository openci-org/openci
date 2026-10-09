enum IosDistributionMethod {
  adHoc,
  appStore;

  String toArchiveMethod() => switch (this) {
    IosDistributionMethod.adHoc => 'ad-hoc',
    IosDistributionMethod.appStore => 'app-store',
  };
}
