#################################################################################
# © 2010 SunGard Higher Education.  All Rights Reserved.
#
# CONFIDENTIAL BUSINESS INFORMATION
#
# THIS PROGRAM IS PROPRIETARY INFORMATION OF SUNGARD HIGHER EDUCATION
# AND IS NOT TO BE COPIED, REPRODUCED, LENT, OR DISPOSED OF,
# NOR USED FOR ANY PURPOSE OTHER THAN THAT WHICH IT IS SPECIFICALLY PROVIDED
# WITHOUT THE WRITTEN PERMISSION OF THE SAID COMPANY
#################################################################################


require 'rho/rhocontroller'
require 'date'
require 'time'
require 'helpers/application_helper'
require 'helpers/browser_helper'
require 'Mshell/mapp_helper'

class MultiFeedController < Rho::RhoController
    include BrowserHelper
    include ApplicationHelper
    include MappHelper
    
    #@layout = 'Feed/layout'
    
    def initialize()
	    clear_controls
      app_info "initializing FeedController"
      @serviceUrl = "http://localhost:8080/uagent/rest/feed"
      urlkey = "feed_service_url"
      if Rho::RhoConfig.exists?(urlkey) then
        @serviceUrl = Rho::RhoConfig.send(urlkey)
      end
      app_info "service url:" + @serviceUrl  
    end

    def index
        app_info "Index action"
        redirect :action => :show
    end
    
    def show

          @@feeds = Mshell.mapp_config('feeds', {:parse => true})
      
          if !@@feeds
              app_info "No feeds defined"
              @@feeds = []
          end
      
          app_info "@@feeds: #{@@feeds.inspect}"
      
          redirect :action => :showlist
 
    end
    
    def clear_controls
        Rho::NativeToolbar.remove() unless platform == "blackberry"
        if platform != 'blackberry'
			     NavBar.remove
		    end
    end
    
    def showFeed
          
		    feedId = @params['feed']
		
        app_info "Mshell Index action"
        url = "#{@serviceUrl}"
        url << "/#{feedId}.json" if feedId
        app_info "Requesting feed url: #{url}"
        
        result = Rho::AsyncHttp.get( :url => url)
        app_info "result['status']: #{result['status']}"
        
        if result['status'] == 'ok'
            app_info "result['body']: #{result['body']}"
            # if content-type is application/json then it will already be parsed
            if result['body'] and result['body'].is_a?(String)
                @@feed = Rho::JSON.parse(result['body'])
            else
                @@feed = result['body']
            end
            app_info ("feed is : #{@@feed}")
            version2 = false
            if @@feed['@version'] and @@feed['@version'] == "2.0"
                version2 = true
                app_info "parsing 2.0"
                channel = @@feed['channel']
                @@entries = channel['item']
                app_info "entries : #{@@entries}"
            else
                @@entries = @@feed['entry']
                app_info "entries : #{@@entries}"
            end

            # parse and reformat the dates
            @@entries.each do |entry|
                if version2 == true
                    date = entry['pubDate']
                    app_info "version 2 date: #{date}"
                    entry['content'] = entry['description']
                else
                    date = entry['published']
                    app_info "date: #{date}"
                end
                if platform != 'blackberry'
                    date = Date.parse(date).strftime("%m/%d/%Y")
                end
                app_info "date: #{date}"
                entry['date'] = date
            end

            redirect :action => :showfeed
            
        else
            app_info "Rho error : #{Rho::RhoError.new(result['error_code'].to_i).message}"
            app_info "Http error : #{result['http_error']}"
            app_info "Http response: #{result['body']}"
            redirect :action => :error, :query => {:error_message => "Unable to load profile" }
        end

    end
    
    def get_feeds
        @@feeds
    end

    def get_entries
        @@entries
    end
    
    def get_title
        Mshell.current_mapp != nil && Mshell.current_mapp.title != nil ? Mshell.current_mapp.title : ""
    end
end
