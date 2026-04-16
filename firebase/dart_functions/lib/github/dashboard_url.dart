const _dashboardBaseUrl = 'https://dashboard.openci.org';

String buildDashboardRunUrl(String buildJobId) {
  return '$_dashboardBaseUrl/runs/${Uri.encodeComponent(buildJobId)}';
}
