ChaOne in C
                                                              2005.03.27
                                                              Studio ARC
------------------------------------------------------------------------

C言語で書かれたChaOneです。

=============
1. 準備
=============

ChaOne本体の変換ロジックはすべてXSLTで書かれています。このため、
ChaOne in Cのコンパイル及び実行には、Gnomeプロジェクトで開発された
XSLT Cライブラリであるlibxsltが必要です。
最近のLinuxディストリビューションには、はじめから含まれていることが
多いようです。
xsltlibの配布元は、http://xmlsoft.org/XSLT/です。

=============
2. 設定
=============

2.1 文字コードの決定

まず、システムで用いるデフォルトの文字コードを決めます。
これは実行時に変更可能です。

2.2 スタイルシートの場所

続いて、プログラム実行時に使用されるファイル群を置く場所を決めます。

=============
3. コンパイル
=============

3.1 configure

./configureを実行します。
オプションは以下のとおりです。
指定しない場合は[ ]内のデフォルト値が使われます。

  --with-xml
    libxml2のインストール場所 [/usr, /usr/local]
  --with-xslt
    libxsltのインストール場所 [/usr, /usr/local]
  --with-kanjicode
    文字コード [EUC-JP]
  --with-xsltfile-dir
    スタイルシートの場所 [.]

スタイルシートの場所は絶対パスで指定しても、相対パスでも構いませんが、
内部で絶対パスに変換されますので、たとえ相対パスで指定しても、後から
置き場所を変えることはできません。

3.2 make

続いてmakeを実行します。

=============
4. 使用法
=============

4.1 ヘルプの表示

  chaone {-h | --help}

4.2 バージョンの表示

  chaone {-v | --version}

4.3 通常の使用法

  chaone [options] [file]

  入力ファイルを指定しなければ、標準入力から読み込む。
  出力は常に標準出力が用いられる。

  設定可能なオプション

  {-e | --encoding}

    入出力の文字コードを、ISO-2022-JP、EUC-JP、Shift_JIS、UTF-8のうちから指定する。

  {-s | --mode}

    prep: 前処理モード
      前処理のみを行う。
    chunker:チャンカモード
      チャンカ処理のみを行う。
    chaone:音韻交替モード
      音韻交替処理のみを行う。
    accent: アクセント結合モード
      アクセント結合のみを行う。

    モードを指定しなければ、すべての処理が行われます。

  {-d | --debug}

    stderrに中間結果を出力する。
    出力文字コードはUTF-8固定です。

===============
5. ファイル構成
===============

00readme.txt: このファイル
Makefile.in: Makefileのスケルトン
configure: Makefile生成スクリプト
configure.in: configureのスケルトン

chaone.c: chaoneプログラムソースファイル

chaone_t_EUC-JP.xsl: EUC-JP出力用ローダ
chaone_t_ISO-2022-JP.xsl: ISO-2022-JP出力用ローダ
chaone_t_Shift_JIS.xsl: Shift_JIS出力用ローダ
chaone_t_UTF-8.xsl: UTF-8出力用ローダ
chaone_t_main.xsl: XSLTメインファイル
prep.xsl: 前処理用XSLTファイル
chunker.xsl: チャンカ用XSLTファイル
phonetic.xsl: 音韻交替用XSLTファイル
accent.xsl: アクセント結合用XSLTファイル

ea_symbol_table.xml: 英字変換テーブル
grammar.xml: IPAdic-UniDic文法対応テーブル
pa_word.xml: 音韻交替対象語テーブル

chunk_rules.xml: チャンカ用規則
FPAForm.xml: FPAFormテーブル
IPAForm.xml: IPAFormテーブル

kannjiyomi.xml: 単漢字発音テーブル
ap_rule.xml: アクセント句構成規則
accent_rule.xml: アクセント結合規則



以上
