PostX
====

## Overview

PostX is a tool that can help you post data to HRForecast easily.

### Key features

* add new service/section/grpah only with sql file
* execute the sql and post data to HRForecast automatically  

## Install & Setup

### Database config

### install

```
make
```

## Usage

### Rule

|Project       | HRForecast | Comments                                        |
|--------------| ---------- | ----------------------------------------------- |
|directory     | service    | ./sql/{directory} is the service of HRForecast  |
|filename      | section    | filename is the section of service              |
|fetch columns | graphs     | fetch columns are the graphs of section         |

* example

```sh
$ tree
sql
└── shopping
    └── mau.sql
```

```sql
datetime | mau_total | mau_new | mau_resurrection | mau_retention
------------------------------------------
2015-02-05 | 900 | 100 | 300 | 500
```

### Run

```
make run
```

### Irregular run 

`vagrant ssh` to login and `cd /vagrant` add your options
```
vagrant@precise32:/vagrant$ carton exec -- perl report.pl --help
Usage: report.pl [options] [args]
       --help                             print this message (also -?)
       --date=<value>                     [undef] (date)
       --not_post                         [0] (boolean)
       --post_only                        [0] (boolean)
       --sql=<value>                      [undef] (string)
```

* `post_only`: post the csv files at `data` directory

*  The time in SQL files is now. If you want to post passed days, you can use the option as fellow:

```
vagrant@precise32:/vagrant$ carton exec -- perl report.pl --date=2015-01-20 --sql=sql/fishing/new_user_active_funnel.sql --not_post=1
```

## Author
Ethan Hu
