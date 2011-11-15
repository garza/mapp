#################################################################################
# © 2010 SunGard Higher Education.  All Rights Reserved.
#
# CONFIDENTIAL BUSINESS INFORMATION
#
# THIS PROGRAM IS PROPRIETARY INFORMATION OF SUNGARD HIGHER EDUCATION
# AND IS NOT TO BE COPIED, REPRODUCED, LENT, OR DISPOSED OF,
# NOR USED FOR ANY PURPOSE OTHER THAN THAT WHICH IT IS SPECIFICALLY PROVIDED
# WITHOUT THE WRITTEN PERMISSION OF THE SAID COMPANY -

module MappHelper

    def platform_name
        System::get_property('platform').downcase
    end

    def platform_css
        "#{platform_name}.css"
    end
    
    def platform_version
        System::get_property('os_version')
    end

    def platform_major_version
        platform_version[0,1]
    end

    def platform_id
        "#{platform_name}-#{platform_major_version}"
    end

    def platform_id_css
        "#{platform_id}.css"
    end
    
    def device_name
        # Android has a bug if you access 'device_name'
        # need to recheck after update to Rhodes 2.2>
        if platform_name == "android"
            device = 'android'
        else
            device_name = System::get_property('device_name').downcase
            if device_name =~ /iphone/
                device = 'iphone'
            elsif device_name =~ /ipad/
                device = 'ipad'
            elsif device_name =~ /ipod/
                # treat ipod as iphone
                device = 'iphone'
            else
                device = device_name
            end
        end
        
        device
    end

    def device_css
        "#{device_name}.css"
    end
    
    def device_id
        "#{device_name}-#{platform_major_version}"
    end
    
    def device_id_css
        "#{device_id}.css"
    end

    def webkit?
        platform_name == 'apple' || platform_name == 'android' || platform_id == 'blackberry-6'
    end
    
    def include_css
        css_string = ""
        
        if webkit?
            css_string << "
  			<link href='/public/css/webkit.css' type='text/css' rel='stylesheet'/>
            "
        end		
		
		if(platform_id =='blackberry-5')
		
			css_string << "
			<!-- System CSS -->
			<link href='/public/css/#{platform_css}' type='text/css' rel='stylesheet'/>
			
			<!-- Application CSS -->
			<link href='css/#{platform_id_css}' type='text/css' rel='stylesheet'/>	
			"
		else
			
	        css_string << "
			<!-- System CSS -->
			<link href='/public/css/#{platform_css}' type='text/css' rel='stylesheet'/>
			<link href='/public/css/#{platform_id_css}' type='text/css' rel='stylesheet'/>
			<link href='/public/css/#{device_css}' type='text/css' rel='stylesheet'/>
			<link href='/public/css/#{device_id_css}' type='text/css' rel='stylesheet'/>
			
			<!-- Application CSS -->
			"
		
	        if webkit?
	            css_string << "
	  			<link href='css/webkit.css' type='text/css' rel='stylesheet'/>
	            "
	        end		
			
	        css_string << "
			<link href='css/#{platform_css}' type='text/css' rel='stylesheet'/>
			<link href='css/#{platform_id_css}' type='text/css' rel='stylesheet'/>
			<link href='css/#{device_css}' type='text/css' rel='stylesheet'/>
			<link href='css/#{device_id_css}' type='text/css' rel='stylesheet'/>
			"
		end
    end
end
