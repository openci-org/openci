String quoteShellArgument(String value) =>
    "'${value.replaceAll("'", r"'\''")}'";
