# git_commits_stat
Script that calculates statistics of contributers' deposits for a group of projects. The subject is to count only new lines with code. For that some technics is used.
Now the script recoginzes only ruby comments. See (TODO)[#markdown-header-todo]

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

    -l, --limit max new lines
          Since too big commits usually are produced by generators or by copy/paste, or
          by other autmatic tools it is worth to ignore them. This option defines the limit.
          Note, that only new lines are counted. To disable set the limit to 0.

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

    -A
          Abbreviates names: each name is abbreviated to two symbols.

    -a, --aliases LIST
          Sometimes one contributer may use different accouts. LIST is a comma-separated
          list of such contributer's emails that should be colon-separeted.
          For example: -a user1@mail.ru:user1@gmail.com,user2@list.ru:user2@gmail.com
          The first email will be manifested.
```

# TODO
- Allow deeper search
- Add list of projects to participate
- Add list of projects to be ignored
