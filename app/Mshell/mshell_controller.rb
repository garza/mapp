#################################################################################
# © 2010 SunGard Higher Education.  All Rights Reserved.
#
# CONFIDENTIAL BUSINESS INFORMATION
#
# THIS PROGRAM IS PROPRIETARY INFORMATION OF SUNGARD HIGHER EDUCATION
# AND IS NOT TO BE COPIED, REPRODUCED, LENT, OR DISPOSED OF,
# NOR USED FOR ANY PURPOSE OTHER THAN THAT WHICH IT IS SPECIFICALLY PROVIDED
# WITHOUT THE WRITTEN PERMISSION OF THE SAID COMPANY 

require 'rho/rhocontroller'
require 'rho/rhosupport'
require 'rho/rhotoolbar'
require 'helpers/application_helper'
require 'helpers/browser_helper'
require 'Mshell/user'
require 'Mshell/mshell'
require 'Mshell/mapp_helper'
require 'json'

class MshellController < Rho::RhoController
    include ApplicationHelper
    include BrowserHelper
    include MappHelper
    
    @layout = 'Mshell/layout'
    @errCode = 0
    @show_login = false

    # TODO - remove?
    @login_failed = false

    # TODO - remove?
    @@login_background = false
    
    @@securityServiceUrl = "http://localhost:8001/mobileserver/rest/security"
    urlkey = "security_service_url"
    if Rho::RhoConfig.exists?(urlkey) then
        @@securityServiceUrl = Rho::RhoConfig.send(urlkey)
    end
    Mshell.info "security service url: #{@@securityServiceUrl}"

    def initialize()
    	set_mshell_controls
    end

    def index
        app_info "Mshell Index action"
        
        render :action => :index
    end
    
    def set_mshell_controls
        if platform != "blackberry"
            Rho::NativeToolbar.remove()
            NavBar.remove
        end 
        
        if platform == "android" || platform = "blackberry"
            @menu = {
                Locale::Mc[:label_close] => :close
            }
        end
    end
    
    def set_app_controls
        if platform == "apple"
            toolbar = [
                {:action => :back,},
                {:action => :separator},
                {:action => :home,}
            ]
            Rho::NativeToolbar.create( :buttons => toolbar )
        end

        if platform == "android" || platform = "blackberry"
            @menu = {           
                Locale::Mc[:label_close] => :close
            }
        end
        
        if platform != 'blackberry'
            NavBar.create :title => Mshell.current_mapp.title
        end
    end

    def show      
        #log_system_info
        app_info "Show mapps. Mshell's current user is #{Mshell.current_user}"
        
        @@login_background = true
        Mshell.current_mapp = nil

        # set the tool bar
        set_mshell_controls
        
        launch_id = Mshell.instance.launch_id
        if (launch_id != nil)
            Mshell.instance.launch_id = nil
            redirect :action => :launch_mapp, :query => { :id => launch_id }
        else
            # if current user is guest and login first flag is set, trigger a login
            if !Mshell.is_logged_in? && Mshell.login_first?
                @show_login = true
                redirect :action => :login
            else
                action = "#{Mshell.mode}_show"
                app_info("Rendering action: #{action}")
                render :action => action.to_sym
            end
        end
    end
    
    def show_login
        app_info "Show Login"

        @launch_mapp_id = @params['launch_mapp_id']
        @mapp_jqm_enabled = @params['mapp_jqm_enabled']
        success_url = @params['success_url']
        
        @login_url = url_for(:action => :async_login)
        
        @login_success_url = success_url
        if @launch_mapp_id && @launch_mapp_id != ""
            @login_success_url = url_for( :action => :launch_mapp, :query => { :id => @launch_mapp_id } ) 
        end
        
        app_info("@login_success_url: #{@login_success_url}")
        
        @login_not_authorized_url = url_for ({ :action => :error, :query => {:error_message => Locale::Mc[:message_unauthorized_access] } })
        
        @cached_login_id = Rho::RhoConfig.cached_login_id
        app_info("cached_login_id: #{@cached_login_id}")
        
        @login_failed = false
        
        render :action => :show_login
    end

    def logout
        app_info "Logout request received. Logging user out.."
        @destination_url = @params['destination_url']
        
        Mshell.current_user = User.guest_user
        redirect @destination_url 
    end

    def set_mode
        mode = @params['mode']
        app_info "Set Mode: #{mode}"
        
        Mshell.mode = mode
        
        @response['headers']['Content-Type']='application/json;charset=utf-8'
        render :string => { :result => "success" }.to_json, :layout => false
    end
   
    def get_jquery_mobile_locale_strings
        app_info "Getting JQuery Mobile local strings"
        
        result = {}
        
        result['loadingMessage'] = Locale::Mc[:jqm_loading_message]
        result['errorLoadingMessage'] = Locale::Mc[:jqm_error_loading_message]
        
        @response['headers']['Content-Type']='application/json;charset=utf-8'
        render :string => result.to_json, :layout => false
        
    end
    
    def async_login
        app_info "Async Login"
        userid = @params['userid']
        password = @params['password']
        remember_id = @params['remember-id']
        launch_mapp_id = @params['launch-mapp-id']

        @response['headers']['Content-Type']='application/json;charset=utf-8'
          
        user = User.new
        user.login_id = userid
        user.password = password

        if ( remember_id == "on" )
            Rho::RhoConfig.cached_login_id = userid
            app_info "Saved #{userid} to cache"
        else
            Rho::RhoConfig.cached_login_id = ""
            app_info "Removed user id from cache"
        end
    
        # Authentication via Basic Auth and request User Info
        url = "#{@@securityServiceUrl}/getUserInfo"
        app_info "authenticate to: #{url}"
        result = Rho::AsyncHttp.get( :url => url,
            :authentication => {:type => :basic, :username => userid, :password => password})
            
        app_info "result['status']: #{result['status']}"
        app_info "result['body']: #{result['body']}"

        if result['body'] == ['failure'] || result['status'] != 'ok'
            # Login failed
            render :string => { :result => "failed" }.to_json, :layout => false
        else
            # Login Succeeded
            @userInfo = result['body']
            app_info @userInfo['status']        
            user.id = @userInfo['userId']
            user.roles = @userInfo['roles']
            if user.roles 
                user.roles.collect! {|role| role.downcase}
            else
                user.roles = []
            end
            Mshell.current_user = user
            
            answer = { :result => "success" }
            
            # check of un-authorized mapp after login
            if launch_mapp_id && launch_mapp_id != ""
                mapp = Mshell.mapp_by_id(launch_mapp_id)
                authorized = Mshell.app_role_match?(mapp)
                
                answer[:authorized] = authorized
            end
            
            render :string => answer.to_json, :layout => false
        end
    end

    def async_logout
        app_info "Async Logout"
        Mshell.current_user = User.guest_user
        
        @response['headers']['Content-Type']='application/json;charset=utf-8'
        render :string => { :result => "success" }.to_json, :layout => false
    end

    def launch_mapp
        mapp_id = @params['id']
        app_info "Launching app id: #{mapp_id}"

        mapp = Mshell.mapp_by_id(mapp_id)
        Mshell.current_mapp = mapp
        
        app_info "Current m-App: #{Mshell.current_mapp.inspect}"

        set_app_controls

        if mapp.url
            app_info "url: #{mapp.url}"
            redirect mapp.url
        else
            #use m-App name to dispatch
            @response["headers"]["Wait-Page"] = "true"
            url = url_for ({ :controller => mapp.impl.id.to_sym, :action => :index })
            app_info "redirecting to url: #{url}"
            redirect url
        end
    end    
    
    def set_mapp
        app_info "Set mApp"
        mapp_id = @params['id']
        app_info "Setting app id: #{mapp_id}"

        mapp = Mshell.mapp_by_id(mapp_id)
        Mshell.current_mapp = mapp
        
        @response['headers']['Content-Type']='application/json;charset=utf-8'
        render :string => { :result => "success" }.to_json, :layout => false
    end    
    
    def is_logged_in
        app_info "is_logged_in"

        @response['headers']['Content-Type']='application/json;charset=utf-8'
        render :string => { :logged_in => Mshell.is_logged_in? }.to_json, :layout => false
    end    

    def cancelLogin
        Rho::RhoConfig.cached_login_id = ""
        Mshell.instance.launch_id = nil
        Mshell.current_user = User.guest_user
        redirect :action => :show_mapps 
    end
        
    def get_login_background
        @@login_background
    end
    
    def log_system_info
        log_system_property("platform")
        log_system_property("screen_width")
        log_system_property("screen_height")
        log_system_property("ppi_x")
        log_system_property("ppi_y")
        log_system_property("has_network")
        log_system_property("full_browser")
        log_system_property("phone_number")
        log_system_property("device_name")
        log_system_property("os_version")
        log_system_property("locale")
        log_system_property("country")
    end

    def log_system_property(name)
        app_info "#{name}: #{System.get_property(name)}"
    end
end
