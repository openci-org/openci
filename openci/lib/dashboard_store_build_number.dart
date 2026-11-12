/// Google Play had already published build 14616 when Dashboard moved to OpenCI.
/// Keep mobile build numbers above that release as the team's run number grows.
int dashboardStoreBuildNumber(int runNumber) => 14616 + runNumber;
