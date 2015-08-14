# -*- coding: utf-8 -*-
require 'cgi'
require 'open-uri'
require 'rss'

# ※リファクタ前のソース

# HTMLからデータ変換
## 日付、タイトル、URLリンクを抽出
def html_parse(html)
  # 年月日を取得
  date = html.scan(%r!(\d+)年 ?(\d+)月 ?(\d+)日<br />!)
  # タイトルとURLリンクを取得
  title_link = html.scan(%r!^<a href="(.+?)">(.+?)</a><br />!)

  if date.size != title_link.size
    raise "日付とタイトルリンク数が不一致"
  end
  # タイトル、URL、年月日を同時に処理
  return title_link.zip(date).map { |(aurl, atitle), ymd|
    [CGI.unescapeHTML(aurl), CGI.unescapeHTML(atitle), Time.local(*ymd)] }
end

# テキストフォーマット
def format_text(title, url, url_title_time_ary)
  s = "Title: #{title}\nURL: #{url}\n\n"
  url_title_time_ary.each{|url, title, time|
    s << "*(#{time})#{title}\n"
    s << "   #{url}\n"
  }
  return s
end

# RSSフォーマット
def format_rss(title, url, url_title_time_ary)
  RSS::Maker.make("2.0") {|maker|
    # タイトル、説明、リンクURL、
    maker.channel.title = title
    maker.channel.description = "A longer description of my feed."
    maker.channel.link = url
    # 更新時刻
    maker.channel.updated = Time.now.to_s
    url_title_time_ary.each { |url, title, date|
      maker.items.new_item {|item|
        item.link = url
        item.title = title
        item.updated = date
        item.description = title
      }
    }
  }
end

#url_title_time = html_parse(open('samplepage.html', &:read))
url_title_time = html_parse(
    open("http://crawler.sbcr.jp/samplepage.html", "r:UTF-8", &:read)
)


#puts format_text('aaa', 'bbb', url_title_time)
#puts format_rss('Exsample RSS', 'http://example.com', url_title_time)

# 引数場合分け
formatter = case ARGV.first
              when "rss"
                :format_rss
              when "text"
                :format_text
            end

# 実行引数に応じてメソッド実行
## rss: format_rss, text: format_text
puts self.send(formatter, "SBCRサンプル","http://crawler.sbcr.jp/samplepage.html", url_title_time)

SampleSite.new(``)


