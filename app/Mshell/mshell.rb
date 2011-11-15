#################################################################################
# © 2010 SunGard Higher Education.  All Rights Reserved.
#
# CONFIDENTIAL BUSINESS INFORMATION
#
# THIS PROGRAM IS PROPRIETARY INFORMATION OF SUNGARD HIGHER EDUCATION
# AND IS NOT TO BE COPIED, REPRODUCED, LENT, OR DISPOSED OF,
# NOR USED FOR ANY PURPOSE OTHER THAN THAT WHICH IT IS SPECIFICALLY PROVIDED
# WITHOUT THE WRITTEN PERMISSION OF THE SAID COMPANY 

require 'Mshell/mapp'
require 'Mshell/mapp_impl'
require 'Mshell/mapp_helper'

class Mshell
    include MappHelper

    @@Instance = nil
    @@rholog = RhoLog.new
    
    @@default_mode = "list"

    attr_accessor :mode, :path, :title, :login_first, :mapps, :mapps_by_id, :mapp_impls, :mapp_impls_by_id, :current_user, :current_mapp, :launch_id, :show_url, :inactive_logout_time

    def initialize()
        Mshell.info "Mshell.initialize"
        # default to guest user
        @current_user = User.guest_user
        
        @current_mapp = nil

        # Ordered list of mApps
        @mapps = []
        @mapps_by_id = {}
        
        # list of mapp impls
        @mapp_impls = []
        @mapp_impls_by_id = {}

        @mapps_loaded = false
        
        load_config_
        load_mapps_
    end

    # making this a singleton
    private_class_method :new
    
    def Mshell.instance()
        @@Instance = new unless @@Instance
        @@Instance
    end
    
    def Mshell.inactive_logout_time()
        instance.inactive_logout_time
    end
    
    def Mshell.inactive_logout_time=(inactive_logout_time)
        instance.inactive_logout_time = inactive_logout_time
        Mshell.info "setting inactive_logout_time: #{instance.inactive_logout_time}"
    end

    def Mshell.mode()
        instance.mode ? instance.mode : @@default_mode
    end
    
    def Mshell.mode=(mode)
        instance.mode = mode
        Mshell.info "setting mode: #{instance.mode}"
    end

    def Mshell.path()
        instance.path
    end

    def Mshell.show_url()
        instance.show_url
    end

    def Mshell.title()
        instance.title
    end
    
    def Mshell.title=(title)
        instance.title = title
        Mshell.info "setting title: #{instance.title}"
    end

    def Mshell.login_first?()
        instance.login_first
    end
    
    def Mshell.login_first=(login_first)
        instance.login_first = login_first
        Mshell.info "setting login_first: #{instance.login_first.inspect}"
    end

    def Mshell.current_user()
        instance.current_user
    end
    
    def Mshell.current_user=(user)
        instance.current_user = user
        Mshell.info "setting current_user: #{instance.current_user.inspect}"
    end

    def Mshell.mapp_impls()
        Mshell.info "getting mapp_impls: #{instance.mapp_impls.inspect}"
        instance.mapp_impls
    end
    
    def Mshell.mapp_impls=(mapp_impls)
        Mshell.info "setting mapp_impls: #{instance.mapp_impls.inspect}"
        instance.mapp_impls = mapp_impls
    end
    
    def Mshell.get_mapp_jqm_files( type, ending=".#{type}" )
        files = []
        Mshell.mapp_impls.each do |impl|
            impl_files = []
            if impl.jqm_enabled
                impl_files += [ "#{impl.id.downcase}#{ending}", "#{impl.id.downcase}-custom#{ending}" ]
                if ".#{type}" == ending
                    extra_files_key = "mapp_#{impl.id}_extra_#{type}"
                    if Rho::RhoConfig.exists?(extra_files_key)
                        value = Rho::RhoConfig.send(extra_files_key)
                        if value[0,1] == '[' 
                            impl_files += Rho::JSON.parse(value)
                        else
                            impl_files << value
                        end
                    end
                end
            end
            
            app_path = "/app/#{impl.id}"
            impl_files.each do |file|
                
                if file[0,4] == "http"
                    files << file
                else
                    file = "#{app_path}/#{type}/#{file}"
                    file_path = Rho::RhoApplication::get_app_path(file[1,file.size-1])
                    file_path = file_path[0,file_path.size-1]
                    Mshell.info "file_path #{file_path}"
                    files << file if File.exists? file_path
                end
            end
        end
        

        Mshell.info "files: #{files.inspect}"
        files
    end

    def Mshell.current_mapp()
        instance.current_mapp
    end
    
    def Mshell.current_mapp=(app)
        Mshell.info "setting current_mapp: #{instance.current_mapp.inspect}"
        instance.current_mapp = app
    end
    
    def Mshell.get_mapps_for_launch()
        instance.get_mapps_for_launch_()
    end
    
    def Mshell.mapp_by_id(id)
        instance.mapps_by_id[id]
    end
    
    def Mshell.is_logged_in?
        instance.current_user.is_guest? ? false : true
    end
    
    def Mshell.logout
        instance.current_user = User.guest_user
    end
    
    def Mshell.app_requires_role?(mapp)
        mapp.roles.index("any") == nil
    end
    
    def Mshell.app_role_match?(mapp)
        (instance.current_user.roles & mapp.roles).length > 0
    end
    
    def Mshell.info(message)
        @@rholog.info("Mshell " + self.class.to_s, message)
    end
    
    def Mshell.error(message)
        @@rholog.error("Mshell " + self.class.to_s, message)
    end
    
    def Mshell.mapp_config( key, options = {} )
        options[:mapp] ||= Mshell.current_mapp
        options[:parse] ||= false
        
        mapp = options[:mapp]
        parse = options[:parse]
        
        Mshell.info "mapp_config key: #{key} mapp: #{options[:mapp]} parse: #{options[:parse]}"
        
        full_key = "mapp_instance_#{mapp.id}_#{key}"
        value = nil
        if Rho::RhoConfig.exists?(full_key)
            value = Rho::RhoConfig.send(full_key)
        end
        
        if parse && value && ( value[0,2] == '[{' || value[0,1] == '{' ||  value[0,1] == '[' )
            value = Rho::JSON.parse(value)
        end
        
        Mshell.info "mapp_config full_key: #{full_key} value: #{value.inspect}"
        
        value
    end
    
#   # Private methods
#   private

    def load_config_()
        Mshell.info "Loading config"
        
        @path = Rho::RhoConfig.start_path
        if Rho::RhoConfig.exists?("mshell_path")
            @path = Rho::RhoConfig.mshell_path
        end
            
        @show_url = "#{@path}/show"
        	
        if Rho::RhoConfig.exists?('mshell_mode')
            @mode = Rho::RhoConfig.mshell_mode
            Mshell.info "Mshell mode: #{@mode}"
        end        
        
        @title = Rho::RhoConfig.exists?("mshell_title") ?
            Rho::RhoConfig.mshell_title : "SunGardU"
        Mshell.info "Mshell title: #{@title}"
        # check for localized text
        if @title[0,1] == ':' then
            @title = Locale::Mshell[@title[1,@title.length-1].to_sym]
        end
        Mshell.info "mshell_title: #{@title}"
            
        @login_first = Rho::RhoConfig.exists?("mshell_login_first") &&
            Rho::RhoConfig.mshell_login_first == "true"
        Mshell.info "mshell_login_first: #{@login_first}"

        if Rho::RhoConfig.exists?("mshell_log_system_properties") &&
            Rho::RhoConfig.mshell_log_system_properties == "true" then
            log_system_info
        end

        if Rho::RhoConfig.exists?('mshell_inactive_logout_time')
            @inactive_logout_time = Rho::RhoConfig.mshell_inactive_logout_time.to_i
            Mshell.info "Mshell mode: #{@inactive_logout_time}"
        else
            @inactive_logout_time = 60 # one minute default
        end        
    end
    
    def load_mapps_()
        Mshell.info "Loading mApps"
        
        mapp_ids = Rho::RhoConfig.mapp_instances.gsub(/ /, '').split(',')
        mapp_ids.each do |id|
            impl_base = "mapp"
            key_base = "mapp_instance_#{id}"
            impl_key = "#{key_base}_impl"
            url_key = "#{key_base}_url"
            label_key = "#{key_base}_label"
            title_key = "#{key_base}_title"
            list_icon_key = "#{key_base}_list_icon"
            roles_key = "#{key_base}_roles"
            display_for_guest_key = "#{key_base}_display_for_guest"

            mapp = Mapp.new
            mapp.id = id
            
            # Required properties

            # impl
            mapp_impl = nil
            if Rho::RhoConfig.exists?(impl_key) then
                impl_name = Rho::RhoConfig.send(impl_key)
                Mshell.info "mapp impl: #{impl_name}"
                
                if @mapp_impls_by_id[impl_name]
                    mapp_impl = @mapp_impls_by_id[impl_name]
                    Mshell.info "Found mapp_impl: #{mapp_impl.inspect}"
                else
                    mapp_impl = MappImpl.new
                    @mapp_impls << mapp_impl    
                    @mapp_impls_by_id[impl_name] = mapp_impl
                    mapp_impl.id = impl_name
                    mapp_impl.jqm_enabled = true
                
                    jqm_enabled_key = "#{impl_base}_#{impl_name}_jqm_enabled"
                    if Rho::RhoConfig.exists?(jqm_enabled_key) then
                        enabled = Rho::RhoConfig.send(jqm_enabled_key) == 'true'
                        mapp_impl.jqm_enabled = enabled
                        Mshell.info "mapp_impl: #{impl_name} jqm enabled: #{enabled}"
                    end
                    Mshell.info "mapp_impl: #{impl_name} jqm enabled: #{mapp_impl.jqm_enabled}"
                    
                    Mshell.info "Create new mapp_impl: #{mapp_impl.inspect}"
                end

                mapp.impl = mapp_impl
                mapp.jqm_enabled = mapp_impl.jqm_enabled
            else
                Mshell.error "#{impl_key} is required!"
            end
            Mshell.info "mapp_impl: #{mapp_impl.inspect}"
            
            # Optional properties

            # URL
            if Rho::RhoConfig.exists?(url_key) then
                url = Rho::RhoConfig.send(url_key)
                Mshell.info "mapp url: #{url}"
                decodedurl = Rho::RhoSupport.url_decode(url)
                Mshell.info "app decoded url: #{decodedurl}"
                mapp.url = decodedurl
            end
            
            # LABEL
            if Rho::RhoConfig.exists?(label_key) then
                label = Rho::RhoConfig.send(label_key)
                if label[0,1] == ':' then
                    label = Locale::Mshell[label[1,label.length-1].to_sym]
                end
                mapp.label = label
                Mshell.info "mapp label: #{mapp.label}"
            end

            # TITLE
            if Rho::RhoConfig.exists?(title_key) then
                title = Rho::RhoConfig.send(title_key)
                if title[0,1] == ':' then
                    title = Locale::Mshell[title[1,title.length-1].to_sym]
                end
                mapp.title = title
                Mshell.info "mapp title: #{mapp.title}"
            else
                mapp.title = mapp.label
            end

            # LIST ICON
            # default based on mapp.impl_name
            mapp.list_icon = "/app/#{mapp_impl.id}/images/icon-#{mapp_impl.id.downcase}.png"
            
            if Rho::RhoConfig.exists?(list_icon_key) then
                config_list_icon = Rho::RhoConfig.send(list_icon_key)
            
                if config_list_icon
                    case device_name
                    when "iphone"
                        size = 57
                    when "ipod"
                        size = 57
                    when "ipad"
                        size = 72
                    else
                        size = 57
                    end
                    
                    list_icon_file_name = "#{config_list_icon}#{size}.png"
                    app_path = Rho::RhoApplication::get_app_path("app/#{mapp_impl.id}")
                    list_icon_full_path = "#{app_path}/#{list_icon_file_name}"
                    
                    if File.exists?( list_icon_full_path )
                        Mshell.info "list_icon file exists"
                    else
                        # assume full file name was configured
                        list_icon_file_name = config_list_icon
                    end
                
                    mapp.list_icon = list_icon_file_name
                end
                Mshell.info "mapp.list_icon: #{mapp.list_icon}"
            end

            # ALLOWED ROLES
            if Rho::RhoConfig.exists?(roles_key) then
                mapp.roles = Rho::RhoConfig.send(roles_key).gsub(/ /, '').split(',')
            else
                # default to any
                mapp.roles = ["any"]
            end
            Mshell.info "Roles for #{key_base}: #{mapp.roles}"                

            # DISPLAY FOR GUEST
            if Rho::RhoConfig.exists?(display_for_guest_key) then
                mapp.display_for_guest = Rho::RhoConfig.send(display_for_guest_key) == 'true'
            else
                # default to false
                mapp.display_for_guest = mapp.roles == ["any"] ? true : false
            end
            Mshell.info "Display for guest #{key_base}: #{mapp.display_for_guest}"                

            # add to list and hash
            @mapps << mapp
            @mapps_by_id[id] = mapp
        end
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
        log_system_property("is_emulator")
    end

    def log_system_property(name)
        Mshell.info "#{name}: #{System.get_property(name)}"
    end
    
    
    def get_mapps_for_launch_
        launch_mapps = []
        user_roles = @current_user.roles
        Mshell.info "user_roles: #{user_roles}"
        logged_in = Mshell.is_logged_in?
        @mapps.each do |mapp|
            Mshell.info "mapp.id: #{mapp.id} mapp.roles: #{mapp.roles} - mapp.display_for_guest: #{mapp.display_for_guest}"
            
            # does this one get skipped?
            requires_role = Mshell.app_requires_role?(mapp)
            role_match = Mshell.app_role_match?(mapp)
            display_for_guest = mapp.display_for_guest
            next if ( logged_in && requires_role && !role_match ) ||
                    ( !logged_in && !display_for_guest && requires_role )

            # set login before launch flag
            mapp.login_before_launch = !logged_in && display_for_guest && requires_role            

            # add mapp to lauch list
            launch_mapps << mapp            
            Mshell.info "mapp.id #{mapp.id} was added to launch list - login_before_launch: #{mapp.login_before_launch}"
        end
        
        launch_mapps
    end
end

# Override for AppApplication class
class AppApplication < Rho::RhoApplication
    @@deactive_time = nil

    # Set default menu to include Home and Logout
    def initialize        
        @tabs = nil
        @@tabbar = nil        
        super
        @default_menu = {
            "Home" => :home,
            "Refresh" => :refresh,
            "Close" => :close 
        }     
    end
     
    # log out user and navigate home if needed
    def on_activate_app
        Mshell.info("on_activate_app invoked")
        
        # calculate inactive time
        activate_time = Time.now()
        inactive_time = (activate_time - @@deactive_time).round
        Mshell.info "Inactive time: #{inactive_time} inactive_logout_time: #{Mshell.inactive_logout_time}"
        
        if inactive_time > Mshell.inactive_logout_time && Mshell.is_logged_in?
            # logout the user
            Mshell.logout
            if !Mshell.current_user
                Mshell.info "Refresh the view"
                WebView.refresh
            else
                Mshell.info "Navigate to home because of logout"
                WebView.navigate("/app/Mshell") unless Mshell.current_mapp && !Mshell.app_requires_role?(Mshell.current_mapp)
            end        
        end
    end
    
    def on_deactivate_app
        @@deactive_time = Time.now()
    end
end