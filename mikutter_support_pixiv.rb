# -*- coding: utf-8 -*-
require 'mechanize'
require 'webrick'

# PixivのイラストIDを受け取ってサムネDLして返すサーバ
class PixivServer
    PIX_REGEX = /^http:\/\/(?:www\.)?pixiv\.net\/member_illust\.php\?(?:.*)&?illust_id=(\d+)(?:&.*)?$/

    def initialize()
        @agent = Mechanize.new
        @agent.user_agent_alias = 'Windows IE 9'

        @server = WEBrick::HTTPServer.new({
                :BindAddress => "127.0.0.1",
                :Port => 39339
            })
        @server.mount_proc("/") do |req, res|
            res.body = get_thumb(req.path.scan(/(\d+)/)[0][0])
        end
    end

    # 開始と終了の処理これでいいのかわからない...
    def start()
        @thread = Thread.new do 
            @server.start
        end
    end

    def shutdown() 
        @thread.kill
        @server.shutdown
    end

    def get_thumb_url(url)
        return "http://127.0.0.1:39339/#{url.scan(PIX_REGEX)[0][0]}"
    end

    private

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

    def get_thumb(id)
        page_url = "http://www.pixiv.net/member_illust.php?illust_id=#{id}&mode=medium"
        begin
            @agent.get(page_url)

            illust_url = find_thumb_url(@agent.page)

            unless illust_url.nil? then
                return @agent.get(illust_url, [], page_url).body
            else 
                return nil
            end
        rescue => e
            p e
            return nil
        end
    end
end

Plugin.create(:mikutter_support_pixiv) do

    Plugin[:openimg].addsupport(PixivServer::PIX_REGEX, nil) do |url, cancel|
        @server.get_thumb_url(url)
    end

    @server = PixivServer.new
    @server.start

    at_exit {
        @server.shutdown
    }
end
