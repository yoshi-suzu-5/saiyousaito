#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use LWP::UserAgent;
use POSIX qw(strftime);
use Encode qw(encode decode find_encoding);

binmode STDOUT, ':utf8';
binmode STDERR, ':utf8';

# ============================================================
# ひかり生命保険 採用サイト 自動テストランナー
# 実行方法: perl docs/tests/run_tests.pl [port]
# 例: perl docs/tests/run_tests.pl 3001
# ============================================================

my $port     = $ARGV[0] // 3001;
my $BASE_URL = "http://localhost:$port";
my $ua = LWP::UserAgent->new(timeout => 10);

my @results;   # { id, name, status, detail }
my $pass = 0;
my $fail = 0;
my $warn = 0;

# -------- ヘルパー --------

sub fetch {
    my ($path) = @_;
    my $res = $ua->get("$BASE_URL$path");
    return $res;
}

sub get_html {
    my ($res) = @_;
    my $raw = $res->content;          # バイト列として取得
    my $enc = find_encoding('utf-8');
    my $text = $enc->decode($raw);    # Perlの文字列(フラグ付き)にデコード
    return $text;
}

sub ok_test {
    my ($id, $name, $cond, $detail) = @_;
    my $status = $cond ? 'PASS' : 'FAIL';
    $pass++ if $cond;
    $fail++ unless $cond;
    push @results, { id => $id, name => $name, status => $status, detail => $detail // '' };
    my $mark = $cond ? '[PASS]' : '[FAIL]';
    printf "  %-8s %-10s %s\n", $mark, $id, $name;
    print  "           Detail: $detail\n" if !$cond && $detail;
}

sub warn_test {
    my ($id, $name, $cond, $detail) = @_;
    my $status = $cond ? 'PASS' : 'WARN';
    $pass++ if $cond;
    $warn++ unless $cond;
    push @results, { id => $id, name => $name, status => $status, detail => $detail // '' };
    my $mark = $cond ? '[PASS]' : '[WARN]';
    printf "  %-8s %-10s %s\n", $mark, $id, $name;
    print  "           Detail: $detail\n" if !$cond && $detail;
}

sub count { my ($html, $pat) = @_; my @m = ($html =~ /$pat/g); return scalar @m; }

# ============================================================
print "\n";
print "=" x 60 . "\n";
print " ひかり生命保険 採用サイト 自動テスト\n";
print " 実行時刻: " . strftime("%Y-%m-%d %H:%M:%S", localtime) . "\n";
print " 対象URL : $BASE_URL\n";
print "=" x 60 . "\n\n";

# ============================================================
# TC-001: ページ表示・読み込み
# ============================================================
print "【TC-001】ページ表示・読み込み\n";

my %pages = (
    'index.html'     => '/',
    'sales.html'     => '/sales.html',
    'it.html'        => '/it.html',
    'corporate.html' => '/corporate.html',
    'actuary.html'   => '/actuary.html',
);

my %html_cache;

for my $file (sort keys %pages) {
    my $path = $pages{$file};
    my $res  = fetch($path);
    my $ok   = $res->is_success;
    $html_cache{$file} = get_html($res) if $ok;
    ok_test('TC-001', "[$file] HTTPステータス200", $ok,
        $ok ? '' : "HTTP " . $res->code . ": $path");
}

# ============================================================
# TC-002: ページタイトル
# ============================================================
print "\n【TC-002】ページタイトル\n";

my %title_keywords = (
    'index.html'     => 'ひかり生命',
    'sales.html'     => '営業',
    'it.html'        => 'IT',
    'corporate.html' => '総合',
    'actuary.html'   => 'アクチュアリー',
);

for my $file (sort keys %title_keywords) {
    my $html = $html_cache{$file} // '';
    my $kw   = $title_keywords{$file};
    my ($title) = $html =~ /<title>(.*?)<\/title>/i;
    $title //= '';
    ok_test('TC-002', "[$file] タイトルに\"$kw\"含む",
        $title =~ /\Q$kw/i,
        "実際のタイトル: $title");
}

# ============================================================
# TC-003: メタ情報
# ============================================================
print "\n【TC-003】メタ情報\n";

for my $file (sort keys %html_cache) {
    my $html = $html_cache{$file};
    ok_test('TC-003', "[$file] charset=UTF-8",
        $html =~ /charset.*utf-8/i, '');
    ok_test('TC-003', "[$file] viewport設定あり",
        $html =~ /viewport/, '');
    ok_test('TC-003', "[$file] lang=\"ja\"",
        $html =~ /<html[^>]+lang\s*=\s*["']ja["']/i, '');
}

# ============================================================
# TC-004: CSS / JS 読み込み
# ============================================================
print "\n【TC-004】CSS / JS 参照\n";

for my $file (sort keys %html_cache) {
    my $html = $html_cache{$file};
    ok_test('TC-004', "[$file] style.css参照あり",
        $html =~ /style\.css/, '');
    ok_test('TC-004', "[$file] main.js参照あり",
        $html =~ /main\.js/, '');
}

my $css_res = fetch('/css/style.css');
ok_test('TC-004', "[style.css] 取得成功", $css_res->is_success,
    "HTTP " . $css_res->code);

my $js_res = fetch('/js/main.js');
ok_test('TC-004', "[main.js] 取得成功", $js_res->is_success,
    "HTTP " . $js_res->code);

# ============================================================
# TC-005: ヘッダー・ナビゲーション
# ============================================================
print "\n【TC-005】ヘッダー・ナビゲーション\n";

for my $file (sort keys %html_cache) {
    my $html = $html_cache{$file};
    ok_test('TC-005', "[$file] ヘッダーあり",
        $html =~ /<header/i, '');
    ok_test('TC-005', "[$file] ナビ(nav)あり",
        $html =~ /<nav/i, '');
    ok_test('TC-005', "[$file] ロゴリンクあり",
        $html =~ /logo/i, '');
    ok_test('TC-005', "[$file] ハンバーガーボタンあり",
        $html =~ /hamburger/i, '');
}

# ============================================================
# TC-006: トップページコンテンツ
# ============================================================
print "\n【TC-006】トップページコンテンツ\n";

my $index = $html_cache{'index.html'} // '';

ok_test('TC-006', "ヒーローセクションあり",     $index =~ /class="hero"/i,       '');
ok_test('TC-006', "募集職種セクション(#jobs)",   $index =~ /id="jobs"/i,          '');
ok_test('TC-006', "魅力セクション(#appeal)",     $index =~ /id="appeal"/i,        '');
ok_test('TC-006', "数字セクション(#numbers)",    $index =~ /id="numbers"/i,       '');
ok_test('TC-006', "選考フロー(#flow)",           $index =~ /id="flow"/i,          '');
ok_test('TC-006', "エントリーボタンあり",        $index =~ /エントリー/,          '');
ok_test('TC-006', "営業職員カードあり",          $index =~ /営業/,                '');
ok_test('TC-006', "ITエンジニアカードあり",      $index =~ /IT/i,                 '');
ok_test('TC-006', "総合職カードあり",            $index =~ /総合/,                '');
ok_test('TC-006', "アクチュアリーカードあり",    $index =~ /アクチュアリー/,      '');
warn_test('TC-006', "代表者インタビューあり",    $index =~ /代表|インタビュー/,        'セクション未実装の場合はWARN');
warn_test('TC-006', "社員紹介あり",             $index =~ /社員紹介|働く社員|member/, '社員セクション未実装の場合はWARN');

# ============================================================
# TC-007: 各職種ページの募集要項
# ============================================================
print "\n【TC-007】募集要項（各職種ページ）\n";

my @required_items = ('仕事内容', '応募資格', '給与|報酬', '勤務地', '勤務時間', '休日|休暇', '福利厚生');

for my $file ('sales.html', 'it.html', 'corporate.html', 'actuary.html') {
    my $html = $html_cache{$file} // '';
    for my $item (@required_items) {
        ok_test('TC-007', "[$file] \"$item\"あり", $html =~ /$item/, '');
    }
    ok_test('TC-007', "[$file] エントリーボタンあり", $html =~ /エントリー/, '');
}

# ============================================================
# TC-008: アクセシビリティ
# ============================================================
print "\n【TC-008】アクセシビリティ\n";

for my $file (sort keys %html_cache) {
    my $html = $html_cache{$file};

    # imgタグのalt属性チェック
    my @imgs      = ($html =~ /<img[^>]*>/gi);
    my @imgs_alt  = ($html =~ /<img[^>]+alt\s*=/gi);
    my $img_total = scalar @imgs;
    my $img_alt   = scalar @imgs_alt;
    warn_test('TC-008', "[$file] img alt属性 ($img_alt/$img_total)",
        $img_total == 0 || $img_alt == $img_total,
        "alt未設定: " . ($img_total - $img_alt) . "件");

    ok_test('TC-008', "[$file] aria-labelあり",
        $html =~ /aria-label/i, '');
}

# ============================================================
# TC-009: フッター
# ============================================================
print "\n【TC-009】フッター\n";

for my $file (sort keys %html_cache) {
    my $html = $html_cache{$file};
    ok_test('TC-009', "[$file] フッターあり",
        $html =~ /<footer/i, '');
    ok_test('TC-009', "[$file] コピーライトあり",
        $html =~ /copyright|&copy;|©/i, '');
}

# ============================================================
# TC-010: 内部リンク健全性
# ============================================================
print "\n【TC-010】内部リンク健全性\n";

my %link_check;
for my $file (sort keys %html_cache) {
    my $html = $html_cache{$file};
    my @hrefs = ($html =~ /href\s*=\s*["']([^"'#][^"']*\.html[^"']*)["']/gi);
    for my $href (@hrefs) {
        next if $href =~ /^https?:\/\//;
        $href = "/$href" unless $href =~ /^\//;
        $link_check{$href} = 1;
    }
}

for my $link (sort keys %link_check) {
    my $res = fetch($link);
    ok_test('TC-010', "[$link] リンク有効",
        $res->is_success, "HTTP " . $res->code);
}

# ============================================================
# 結果サマリー
# ============================================================
my $total = $pass + $fail + $warn;
print "\n" . "=" x 60 . "\n";
print " テスト結果サマリー\n";
print "=" x 60 . "\n";
printf " 合計   : %d 件\n", $total;
printf " PASS   : %d 件\n", $pass;
printf " FAIL   : %d 件\n", $fail;
printf " WARN   : %d 件\n", $warn;
printf " 合格率 : %.1f%%\n", $total ? ($pass / $total * 100) : 0;
print "=" x 60 . "\n";

# CSV出力
my $csv_path = 'docs/tests/results.csv';
open my $fh, '>:utf8', $csv_path or die "Cannot write CSV: $!";
print $fh "ID,テスト名,結果,備考\n";
for my $r (@results) {
    (my $name = $r->{name}) =~ s/,/、/g;
    (my $det  = $r->{detail}) =~ s/,/、/g;
    print $fh "$r->{id},$name,$r->{status},$det\n";
}
close $fh;
print " CSV出力 : $csv_path\n";
print "=" x 60 . "\n\n";

exit($fail > 0 ? 1 : 0);
