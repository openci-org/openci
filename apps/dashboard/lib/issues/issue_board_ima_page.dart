import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:dashboard/build_logs/build_logs_page.dart';
import 'package:dashboard/build_logs/synced_spinner.dart';
import 'package:dashboard/firebase/callable_function_names.dart';
import 'package:dashboard/firebase/firestore.dart'
    show
        BuildJobStatus,
        buildJobStatusFromFirestore,
        buildJobsCollection,
        dateTimeFromFirestore,
        workerInstancesCollection;
import 'package:dashboard/firebase/functions.dart';
import 'package:dashboard/firebase_options.dart';
import 'package:dashboard/settings/settings_page.dart';
import 'package:dashboard/store_release/store_release_page.dart';
import 'package:dashboard/utilities/snack_bar_extension.dart';
import 'package:dashboard/variables/variables_page.dart';
import 'package:dashboard/workers/worker_status_page.dart';
import 'package:dashboard/workflow/list/workflows_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:re_highlight/languages/bash.dart';
import 'package:re_highlight/languages/c.dart';
import 'package:re_highlight/languages/cpp.dart';
import 'package:re_highlight/languages/csharp.dart';
import 'package:re_highlight/languages/css.dart';
import 'package:re_highlight/languages/dart.dart';
import 'package:re_highlight/languages/dockerfile.dart';
import 'package:re_highlight/languages/go.dart';
import 'package:re_highlight/languages/java.dart';
import 'package:re_highlight/languages/javascript.dart';
import 'package:re_highlight/languages/json.dart';
import 'package:re_highlight/languages/kotlin.dart';
import 'package:re_highlight/languages/markdown.dart';
import 'package:re_highlight/languages/php.dart';
import 'package:re_highlight/languages/python.dart';
import 'package:re_highlight/languages/ruby.dart';
import 'package:re_highlight/languages/rust.dart';
import 'package:re_highlight/languages/scss.dart';
import 'package:re_highlight/languages/shell.dart';
import 'package:re_highlight/languages/sql.dart';
import 'package:re_highlight/languages/swift.dart';
import 'package:re_highlight/languages/typescript.dart';
import 'package:re_highlight/languages/xml.dart';
import 'package:re_highlight/languages/yaml.dart';
import 'package:re_highlight/re_highlight.dart';
import 'package:re_highlight/styles/github.dart';
import 'package:url_launcher/url_launcher.dart';

part 'issue_board_ima_app_shell.dart';
part 'issue_board_ima_board_page.dart';
part 'issue_board_ima_navigation.dart';
part 'issue_board_ima_overview.dart';
part 'issue_board_ima_toolbar_search.dart';
part 'issue_board_ima_issue_editor.dart';
part 'issue_board_ima_board_columns.dart';
part 'issue_board_ima_issue_cards.dart';
part 'issue_board_ima_models.dart';
part 'issue_board_ima_utils.dart';
