Surefire report scanner script
==========================
Bash script to scan trough all surefire-report folder in path and summarize test results


Dependency
----------
This script uses **xmlstarlet** to parse xml files
```
brew install xmlstarlet
```

How to use
----------
*(Optional)* You can create an alias in your startup script
```
alias report_scan /Users/bkondrat/dev/surefire_report_scan/report_scan.sh
```

cd into the folder (usually the root of the repo) what you want to scan and start the script
```
path/to/repo $ report_scan
```

#### To see just the failing tests and the summary, use the **-q** (quiet) flag
```
path/to/repo $ report_scan -q
```

#### Print mvn command to rerun the failed tests, use **-r** (rerun) flag
Export environment variable *REPORT_SCAN_MVN* to generate custom command
The script will replace the *{tests}* variable with the appropriate tests
```
path/to/repo $ export REPORT_SCAN_MVN="mvn clean install -Dtest='{tests}' -Pitests,hadoop-2 -Dmaven.surefire.plugin.version=2.20.1"
path/to/repo $ report_scan -r
```

This will produce:
```
mvn clean install -Dtest='TestMetaStoreMetrics#testMetaDataCounts,TestJdbcWithMiniLlap#testLlapInputFormatEndToEnd,TestHBaseCliDriver,TestMiniTezCliDriver' -Pitests,hadoop-2 -Dmaven.surefire.plugin.version=2.20.1
```

If you miss to export *REPORT_SCAN_MVN* the script just print the tests out
```
TestMetaStoreMetrics#testMetaDataCounts,TestJdbcWithMiniLlap#testLlapInputFormatEndToEnd,TestHBaseCliDriver,TestMiniTezCliDriver
```

#### You can use **-d** (detail) flag to print the path to report xml file in case of failed tests
```
path/to/repo $ report_scan -d
```
