# -*- coding: utf-8 -*-
require 'nokogiri'
require 'httpclient'
require 'open-uri'

module Plugin::SupportPixiv
  PIX_REGEX = /^https?:\/\/(?:www\.)?pixiv\.net\/member_illust\.php\?(?:.*)&?illust_id=(\d+)(?:&.*)?$/
    
  class << self
    
    def find_thumb_url(doc)
        elem = doc.at("div.img-container")
        if elem.nil? then
            # R-18イラストの場合、低解像度なデータなら取れる可能性があるので試す
            elem = doc.at("div.sensored")
            if elem.nil? then
                return nil
            end
        else
            elem = elem.at("a")
        end
        return elem.at("img").get_attribute("src")
    end
    
  end
end

Plugin.create(:mikutter_support_pixiv) do

  defimageopener("Pixiv", Plugin::SupportPixiv::PIX_REGEX) do |url|
    connection = HTTPClient.new
    page = connection.get_content(url)
    unless page.empty?
      doc = Nokogiri::HTML(page)
      result = Plugin::SupportPixiv.find_thumb_url(doc)
      open(result, "Referer" => url) unless result.nil?
    end
  end

end
