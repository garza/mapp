require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'Mshell/mapp_helper'
require 'json'

class MapController < Rho::RhoController
    include BrowserHelper
    include MappHelper

    # retrieve the service URL
    @@serviceUrl = "http://localhost:8080/mobileserver/rest/map"
    urlkey = "map_service_url"
    if Rho::RhoConfig.exists?(urlkey) then
        @@serviceUrl = Rho::RhoConfig.send(urlkey)
    end
    Mshell.info "service url: #{@@serviceUrl}"

    def on_activate_app
      #start geolocation
      GeoLocation.set_notification("/app/Settings/geo_callback", "")
    end
    
    def initialize
        app_info "MapController.initialize"
		clear_controls
    end
    
    def clear_controls
        Rho::NativeToolbar.remove() unless platform == "blackberry"
        if platform != 'blackberry'
			NavBar.remove
		end
    end
    
    def index
        app_info "Index action"
        redirect :action => :show
    end

    def get_location
      @@locationsResult
    end
    
    def geo_viewcallback
        app_info "geo_viewcallback : #{@params}"
    
        # WebView.refresh if @params['known_position'].to_i != 0 && @params['status'] =='ok'

        if @params['status'] != 'ok'
            app_info "Rho error : #{Rho::RhoError.new(@params['error_code'].to_i).message}"
            app_info "Http error : #{@params['http_error']}"
            app_info "Http response: #{@params['body']}"
        else
            # if content-type is application/json then it will already be parsed
            if @params['body'] and @params['body'].is_a?(String)
                @@locationsResult = Rho::JSON.parse(@params['body'])
            else
                @@locationsResult = @params['body']
            end
            app_info ("locations result : #{@@locationsResult}")
        end    
    end

    def places
      render :places
    end
        
    def show
        # check for network
        app_info "#{@params}"
        if System.get_property("has_network")
            # grap the maps info
            @maps = Mshell.mapp_config('maps', {:parse => true})
        
            if !@maps
                app_info "No maps_config defined"
                @maps = []
            elsif @maps.is_a? String
                app_info "Single url specified"
                @maps = [{'name' => 'Points', 'title' => 'Test Title' }]
            end
        
            app_info "@maps: #{@maps.inspect}"
        
            render :show
        else
            redirect :controller => :Mshell, :action => :error, :query => { :error_message => Locale::Mc[:message_no_network] }
        end
    end
end