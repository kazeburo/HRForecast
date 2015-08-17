Name
====

## Description
ある規則にのっとってsqlファイルを追加すると
PureDataからデータを取得して、HRForcastにpostしてグラフを描画してくれます。

## 実行方法

（注意）初回実行すると$HOMEに以下のような.Rprofileを作り、このIDとPASSWORDを使ってPureDataに接続します
```
% cat ~/.Rprofile
PUREDATA_ID <- 'puredata_id'
PUREDATA_PASSWORD <- 'puredata_pwd'
```
また、初回実行中はカレントディレクトリに.Rprofile.pitというファイルができますが実行後に削除されます

* 初回実行時
```
make
```
* 2回目以降（setupが必要ないためrunだけで良い）
```
make run
```

### イレギュラー処理

`vagrant ssh` でログインして `cd /vagrant` 後にオプションを指定して実行する
```
vagrant@precise32:/vagrant$ carton exec -- perl report.pl --help
Usage: report.pl [options] [args]
       --help                             print this message (also -?)
       --date=<value>                     [undef] (date)
       --not_post                         [0] (boolean)
       --post_only                        [0] (boolean)
       --sql=<value>                      [undef] (string)
```
`post_only` は `data` 配下に置いてあるCSVファイルをHRForecastにpostしたいだけのときに使う

例：SQLのNOW()の所を「2014-10-04」に書き換えて実行し、ただし、SQLファイルは `sql/shopping/purchase_mau.sql` のみ実行し、HRForecastには飛ばさず、CSVファイルのみを作りたい
```
vagrant@precise32:/vagrant$ carton exec -- perl report.pl --date=2014-10-04 --sql=sql/shopping/purchase_mau.sql --not_post=1
```

ある特定のSQLをある日付を一気に実行する方法
```
vagrant@precise32:/vagrant$ for dt in `ruby -rdate -e '(Date.parse("2014-09-29")..Date.parse("2014-10-19")).each{|i| puts i.strftime("%Y-%m-%d")}'`; do echo $dt; carton exec -- perl report.pl --sql=purchase_mau.sql --date=$dt; done
```

## ルール
sqlを指定のディレクトリにいれると実行すると下記のようになります。

#### プロジェクトの規則とHRForcastの対応について

PROJECT | HRForcast | コメント |
--- | --- | ---
directory| service | ./sql/{directory}/の部分は、HRForcastのservice部分になります。
filename | section | セクション名が設定されます
fetch_columns | graph | 描画されるグラフ(DT以外のカラム名がgraphに、valueがグラフにプロットされる値.

directoryとfilenameとfetch_keysの対応は、上の図と、下記のサンプルの対応をみてください。

```sh
$tree
sql
└── shopping
    └── purchase_mau.sql
```

```sql
dt | wau_new | retention | resurrection | total | all
-----------------------------------------------------
2014-10-13 | 1012 | 2023 | 3034 | 6069 | 1020304
```

## Usage
```
perl report.pl
```

## Install & Setup
Puredata.pmにPureDataの各自のIDとPWを追加してください(いずれ共通環境で動かしたい)

