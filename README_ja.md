# Earned Value Management (EVM) Calculation Plugin

[![Rate at redmine.org](http://img.shields.io/badge/rate%20at-redmine.org-blue.svg?style=flat)](http://www.redmine.org/plugins/redmine_issue_evm)

チケットの開始日、期日、予定工数、作業時間を利用してEVM値の計算とチャートを表示する機能を提供しています。期日が入力されず、ヴァージョンの期日がある場合は、期日としてヴァージョンの期日を利用します。

## バージョン
4.5.3

## 動作環境
Redmine 4.0.0 以上

> *redmine3.4.xをお使いの方へ*
>
> Redmine3.4.xの対応版は、ブランチ"Redmine3-4-3"を取得してください。
> https://github.com/momibun926/redmine_issue_evm/tree/redmine3-4-3

## 主な機能
* EVM値の計算
* プロジェクトの基礎情報の表示（期間、計算対象となっているチケットの件数、バージョン別、担当者別、トラッカー別のチケット件数）
* EVM(PV,EV,AC)のチャート表示
* ベースラインの設定、履歴管理

## ベースライン
このプラグインでは、プロジェクトのある時点でのPVを記憶する機能となっています。
ベースラインを設定しておくことで、プロジェクトのある時点を基準に、タスクが増加(チケットが増加)していくと、チャートに乖離していく様子が表示され、どれくらい乖離しているかが認識しやすくなります。つまり、予定作業を超えた作業が増えている状態が可視化されます。ベースラインが設定されている場合は、ベースラインをもとにPVが計算されますので、注意してください。ただし、オプションの設定で、ベースラインを利用しないでEVM値を計算することもできます。この場合はベースライン設定後に変更・登録されたチケットも含めてEVM値が計算されます。（プロジェクトの実情に合わせて計算されることになります）

## オプション
* EVM値の説明を表示
* EVM値を計算する基準日の変更
* パフォーマンス(SPI,CPI,CR)のチャート表示
* プロジェクト完了予測
* ベースラインもしくは、すべてのチケットをもとにしたEVMの計算
* 担当者別、バージョン別、親チケット別、トラッカー別でEVMを表示（画面サンプル参照）
* EVMの計算に含まれていないチケットの一覧を表示
* 基準日を元に未完了であるチケットを表示

## 稼働日について
1. 週末、休日は除外します。（ただしEVM設定で除外しない選択もできます）
2. もしチケットの期間が、週末、休日のみの場合は、すべて稼働日とします
3. holidays gem を使っています。地域は共通設定ページで行います。

例)

日本では2017年は　5/3,5/4,5/5　は祝日です。チケットの期間によって以下のように計算します。

* チケットの期日に週末、祝日が含まれている場合

|開始日              |期日         　　　　   |見積もり時間 　　　|稼働日数　|1日あたりの見積もり時間|
|--------------------|--------------------|---------------|---------|------------------|
|May 1, 2017 (Monday)|May 8, 2017 (Monday)|12 hours       |3 days   |4 hours           |

* チケットの期日に週末、祝日が含まれている場合(期日が週末)

|開始日              |期日         　　　　   |見積もり時間 　　　|稼働日数　|1日あたりの見積もり時間|
|--------------------|--------------------|---------------|---------|------------------|
|May 1, 2017 (Monday)|May 7, 2017 (Sunday)|10 hours       |2 days   |5 hours           |

* チケットの期日が祝日、休日のみの場合

|開始日              |期日         　　　　   |見積もり時間 　　　|稼働日数　|1日あたりの見積もり時間|
|--------------------|--------------------|---------------|-----------|----------------|
|May 3, 2017 (Wed)   |May 7, 2017 (Sunday)|20 hours       |5 days     |4 hours         |

# EVM値の計算
各チケット毎に以下の情報を使ってEVM値を計算して集計しています。EVMを表示するプロジェクト(子孫プロジェクト含む)内の、以下のすべての項目に入力があるチケットが計算対象です。

* 開始日
* 期日
* 予定工数(0でも構いませんがPV,EVが計算できないため意味がありません)
* 作業時間

Redmine3.1から親チケットの予定工数が入力可能になったので、チケットの親子関係に関係なくチケット毎にPV,EVを算出しています。

* PV : 開始日、期日、予定工数を利用して、PVを計算します。日毎の工数を計算しています。
* EV : チケットをCLOSEした日に、予定工数をEVとして計算しています。進捗率が設定されている場合は、進捗理とをセットした日に予定工数に進捗率をかけて計算しています。
* AC : PVの計算に使われているチケットの作業時間を使って、ACを計算しています。


**EVMの計算例**
開始日:2015/08/01,期日:2015/08/03,予定工数:24.0時間のチケットを作成。この時点では、PVのみが有効。PVは日毎のPVから累積値を計算しています。チケットが完了していないので、EVは計算されません。

* PV -> 8/1:8.0時間 8/2:8.0時間 8/3:8.0時間　(24時間を3日で割って日毎のPVを計算)
* EV -> 0
* AC -> 0

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 0   |
| AC  | 0   | 0   | 0   |

チケットの作業時間を8/1,8/2,8/3に10.0時間、6.0時間、7.0時間入力する。日毎のPVに対して、ACの累積値が計算されます。
* PV -> 8/1:8.0時間 8/2:8.0時間 8/3:8.0時間
* EV -> 0
* AC -> 8/1:10.0時間 8/2:6.0時間 8/3:8.0時間

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 0   |
| AC  | 10  | 16  | 24  |

チケットを8/3にCLOSEする。チケットのクローズした日がEVの計上日になります。
* PV -> 8/1:8.0時間 8/2:8.0時間 8/3:8.0時間
* EV -> 8/3:24.0時間
* AC -> 8/1:10.0時間 8/2:6.0時間 8/3:8.0時間

| EVM | 8/1 | 8/2 | 8/3 |
| --- | --- | --- | --- |
| PV  | 8   | 16  | 24  |
| EV  | 0   | 0   | 24  |
| AC  | 10  | 16  | 24  |

上記のEVM値をもとに、チャート、EVM指標を計算しています。

# チャートの表示
計算されたEVM値を元に以下のチャートを表示します。
チャートの表示には、HigthChartを利用しています。ライセンスについては以下参照。
商用目的では利用のできないライセンスです。
https://creativecommons.org/licenses/by-nc/3.0/

**メインチャート**

PV,EV,ACを累積値で時系列に表示します。ベースラインが設定されている場合は、ベースラインも表示します。

**パフォーマンスチャート**

PV,EV,ACが計算されている日だけ、SPI,CPI,CRを計算して表示します。

# インストール
(1) ソースの取得

**ZIPファイルの場合**

* ZIPファイルをダウンロードします
* [redmine_root]/plugins/へ移動して、redmine_issue_evmフォルダを作成してください
* 成したフォルダにZIPファイルを解凍します

**クローンでソースを取得**
```
git clone git://github.com/momibun926/redmine_issue_evm [redmine_root]/plugins/redmine_issue_evm

```
(2) bundle install
```
bundle install
```

(3) マイグレーション。次のコマンドをタイプしてください。
```
rake redmine:plugins:migrate NAME=redmine_issue_evm RAILS_ENV=production
```

(4) Redmineを再起動します (e.g. mongrel, thin, mod_rails).

(5) ログインして、パーミッションとプラグイン設定をします。

# アンインストール
```
rake redmine:plugins:migrate NAME=redmine_issue_evm VERSION=0
```

# 画面サンプル
**全体**
![evm sample screenshot](./images/screenshot_main.png "overview")

**担当別**
![evm sample screenshot](./images/screenshot_assignee.png "assgnees")

**親チケット別**
![evm sample screenshot](./images/screenshot_parent_issue.png "assgnees")

**トラッカー別**
![evm sample screenshot](./images/screenshot_tracker.png "assgnees")

**ベースラインの作成**
![evm sample screenshot](./images/screenshot_new_baseline.png "New baseline")

**ベースラインの履歴**
![evm sample screenshot](./images/screenshot_history_baseline.png "History")

**プラグイン全体の設定**
![evm sample screenshot](./images/screenshot_common_setting.png "plugin　setting")

# 開発環境
*  Redmine version                4.0.4.stable
*  Ruby version                   2.5.5-p157 (2019-03-15) [x64-mingw32]
*  Rails version                  5.2.3
*  Environment                    production
*  Database adapter               Mysql2
*  Mailer queue                   ActiveJob::QueueAdapters::AsyncAdapter
*  Mailer delivery                smtp
