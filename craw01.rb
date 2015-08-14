require 'cgi'
require 'open-uri'
require 'rss'

# Siteクラス
## クロール対象となるHTMLページ単位の親クラス
class Site
  # title:タイトル、url:クローラ対象
  def initialize(url: "", title: "")
    @title = title
    @url = url
  end

  attr_accessor :url, :title

  # HTMLソースを読み込み
  def open_source
    @page_source ||= open(@url, "r:UTF-8", &:read)
  end

  # 指定したフォーマットで出力
  def output(formatter_kclass)
    formatter_kclass.new(self).format(parse)
  end

  # データサイズのチェック
  def is_size_titleurl_date
    return (@date.size == @title_url.size)
  end
end

# サンプルページ用Siteクラス
## サンプルページ用にパースするメソッドを用意
class SampleSite < Site

  def parse
    # 年月日を取得
    date = open_source.scan(%r!(\d+)年 ?(\d+)月 ?(\d+)日<br />!)
    # タイトルとURLリンクを取得
    title_url = open_source.scan(%r!^<a href="(.+?)">(.+?)</a><br />!)
    # タイトル、URL、年月日を同時に処理
    return title_url.zip(date).map { |(aurl, atitle), ymd|
      [CGI.unescapeHTML(aurl), CGI.unescapeHTML(atitle), Time.local(*ymd)] }
  end
end

# Formatterクラス
## 出力するときの表示の親クラス
class Formatter
  def initialize(site)
    @url = site.url
    @title = site.title
  end

  attr_accessor :url, :title
end

# テキストベースのフォーマット
class TextFormatter < Formatter
  def format(url_title_time_ary)
    s = "Title: #{@title}\nURL: #{@url}\n\n"
    url_title_time_ary.each { |aurl, atitle, atime|
      s << "*(#{atime})#{atitle}\n"
      s << "   #{aurl}\n"
    }
    return s
  end
end

# RSSベースのフォーマット
class RSSFormatter < Formatter
  def format(url_title_time_ary)
    RSS::Maker.make("2.0") { |maker|
      # タイトル、説明、リンクURL、
      maker.channel.title = @title
      maker.channel.description = "A longer description of my feed."
      maker.channel.link = @url
      # 更新時刻
      maker.channel.updated = Time.now.to_s
      url_title_time_ary.each { |url, title, date|
        maker.items.new_item { |item|
          item.link = url
          item.title = title
          item.updated = date
          item.description = title
        }
      }
    }
  end
end

# 実行
site = SampleSite.new(url: "http://crawler.sbcr.jp/samplepage.html", title: "SBCRサンプル")
puts site.output(TextFormatter)
