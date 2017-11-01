# git_commits_stat
Script that calculates statistics of contributers' deposits for a group of projects

## Assumption
All the projects to analyze must reside in one directory.

## Synopsis
```
Usage: git_commits_stat.rb options
```

## Options
```
    -f, --from date
          Date to start from. Default is beginning of the current month.

    -t, --to date
          Date to finish after. Default is end of the current month.

    -m, --month n
          Show n-th month ago. Default is 0. Options -f and -t have higher priority.

    -r, --root dir
          Look up the projects in the dir. Default is ./

    -F
          Without this options the current state of the found repositories are used.
          This options executes git fetch in each repository.

    -v
          Prints the project name before fetch if requested.

    -p
          Show projects statistics.

    -c
          Include commit data to projects statistics.

    -x, --exclude list
          Comma separated list of the commits to be skipped in calculation.
          This is usefull for the case, when a commit is a copy-paste of generated code.

    -a
          Alias names: each name is abbreviated to two symbols.
```

# TODO
- Allow deeper search
- Add list of projects to participate
- Add list of projects to be ignored
