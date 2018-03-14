Surefire report scanner script
==========================
Bash script to scan trough all surefire-report folder in path and summarize test results


Dependency
----------
This script uses xmlstarlet to parse xml files
```
brew install xmlstarlet
```

How to use
----------
cd into the folder (usually the root of the repo) what you want to scan and start the script

```
path/to/repo $ report_scan
```

To see just the failing tests and the summary, use the -q flag
```
path/to/repo $ report_scan -q
```
