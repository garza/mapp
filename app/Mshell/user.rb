#################################################################################
# © 2010 SunGard Higher Education.  All Rights Reserved.
#
# CONFIDENTIAL BUSINESS INFORMATION
#
# THIS PROGRAM IS PROPRIETARY INFORMATION OF SUNGARD HIGHER EDUCATION
# AND IS NOT TO BE COPIED, REPRODUCED, LENT, OR DISPOSED OF,
# NOR USED FOR ANY PURPOSE OTHER THAN THAT WHICH IT IS SPECIFICALLY PROVIDED
# WITHOUT THE WRITTEN PERMISSION OF THE SAID COMPANY 

class User
    @@Guest_user = nil
    
    attr_accessor :id, :password, :login_id, :first_name, :last_name, :email, :roles
    
    def intiialize()
        roles = []
    end
    
    def User.guest_user()
        if !@@Guest_user then
            @@Guest_user = new
            @@Guest_user.id = "Guest"
            @@Guest_user.login_id = ""
            @@Guest_user.first_name = ""
            @@Guest_user.last_name = ""
            @@Guest_user.email = ""
            @@Guest_user.roles = []
        end
        
        @@Guest_user
    end
    
    def is_guest?()
        self == User.guest_user
    end        
end
