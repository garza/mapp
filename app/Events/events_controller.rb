require 'rho/rhocontroller'
require 'helpers/browser_helper'
require 'Mshell/mapp_helper'
require 'date'
require 'time'

class EventsController < Rho::RhoController
    include BrowserHelper
    include MappHelper
    @layout = 'Mshell/layout'
    # build the service URL
    @@serviceUrl = "http://localhost:8080/mobileserver/rest/events"
	@@calendarList = nil
	@@title = Locale::Events[:title_events]	
    urlkey = "events_service_url"
    if Rho::RhoConfig.exists?(urlkey) then
        @@serviceUrl = Rho::RhoConfig.send(urlkey)
    end
     Mshell.info "service url: #{@@serviceUrl}"

    def initialize
        app_info "EventsController.initialize"
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
        get_categories_list_result()
		redirect :action => :get_category_events, :query => { :category => "all", :title => Locale::Events[:label_all]}
    end 	
	
	def get_category_events		
		category = @params['category']
		@@title =  @params['title'] + ' ' + Locale::Events[:title_events]	
		startDate = get_formatted_date(get_current_date, format="%Y-%m-%d")
		aWeekAfter = get_formatted_date(get_nth_date(get_current_date,7), format="%Y-%m-%d")
		if category == 'all'
			url = "#{@@serviceUrl}/startDate/#{startDate}/endDate/#{aWeekAfter}"
		else		
			url = "#{@@serviceUrl}/categories/#{Rho::RhoSupport.url_encode(category)}"
		end
        app_info "Retrieving calendar for category #{category} at url: #{url}"
		@@eventsByDate = get_response_from_url(url)
		
		redirect :action => :show_events
	end
	
	def search_for_events
		categories = @params['categories']
		calendars = @params['calendars']
		startDate = @params['startDate']
		endDate = @params['endDate']
		keywords = @params['keywords']
		@@title = Locale::Events[:title_search_results]
		url = @@serviceUrl
		if calendars && calendars.length > 0
			url = "#{url}/calendars/#{Rho::RhoSupport.url_encode(calendars)}"
		end
		if categories && categories.length > 0
			url = "#{url}/categories/#{Rho::RhoSupport.url_encode(categories)}"
		end		
		
		if startDate && startDate.length > 0
			url = "#{url}/startDate/#{Rho::RhoSupport.url_encode(startDate)}"
		end	
		if endDate && endDate.length > 0
			url = "#{url}/endDate/#{Rho::RhoSupport.url_encode(endDate)}"
		end	
		if keywords && keywords.length > 0
			url = "#{url}/desc/#{Rho::RhoSupport.url_encode(keywords)}"
		end			
		
        app_info "Searching events for url: #{url}"
		@@eventsByDate = get_response_from_url(url)
		
		redirect :action => :show_events
	end
	
	def get_calendar_events
		calendar = @params['calendar']
		@@title =  @params['title'] + ' ' + Locale::Events[:title_events]
		startDate = get_formatted_date(get_current_date, format="%Y-%m-%d")
		aWeekAfter = get_formatted_date(get_nth_date(get_current_date,7), format="%Y-%m-%d")
		if calendar == 'all'
			url = "#{@@serviceUrl}/startDate/#{startDate}/endDate/#{aWeekAfter}"
		else		
			url = "#{@@serviceUrl}/calendars/#{Rho::RhoSupport.url_encode(calendar)}/startDate/#{startDate}/endDate/#{aWeekAfter}"
		end
        app_info "Retrieving calendar for calendar #{calendar} at url: #{url}"
		
		@@eventsByDate = get_response_from_url(url)
		
		redirect :action => :show_events
	end	
	
	def get_response_from_url(url)
		authentication_props = ''
        if Mshell.is_logged_in?
            authentication_props = {:type => :basic, :username => Mshell.current_user.login_id, :password => Mshell.current_user.password}
        end
        result = Rho::AsyncHttp.get(
            :url => url,
            :authentication => authentication_props )
            
        app_info "result['status']: #{result['status']}"
        if result['status'] == 'ok'
            app_info "result['body']: #{result['body']}"
            if result['body'] and result['body'].is_a?(String)
                response = Rho::JSON.parse(result['body'])
            else
                response = result['body']
            end  
        end
	end
	
	def show_event	
		# can't pass the selected event as such. so, passing the uid and finding the event with the uid here.		
		uid = @params['uid']
		app_info "UID IS #{uid}"
		found = false
		if @@eventsByDate && @@eventsByDate.length > 0
			    @@eventsByDate.each {|date, events|
					if events && events.length > 0
						events.each {|event|
							if event['uid'] == uid
								@@event_to_show = event
								found = true
								app_info "event found.."
								break # break the events array loop
							end
						}
					end
					if found == true
						break #break the hash loop
					end
				}							  
		end
			app_info "Event is: #{@@event_to_show}"
		redirect :action => :show_event_detail
	end
	
	def get_event_detail
		@@event_to_show
	end	
	
	def get_events_by_date
		@@eventsByDate
	end
	
	def get_categories_list_result
		url = "#{@@serviceUrl}/categories/list"
        app_info "Searching directory url: #{url}"       
		@@categoriesList = get_response_from_url(url)
        @@categoriesList
    end
	
	def get_current_date
		Date.today    
	end
	
	def get_calendar_list
	#enable the if, iff you know the calendars are not going to change much.
		#if !@@calendarList
			url = "#{@@serviceUrl}/calendars/list"
			app_info "Searching directory url: #{url}"       
			@@calendarList = get_response_from_url(url)
		#end
		@@calendarList
	end
  
  def get_day(date)
	day = ""
    if (date.eql?Date.today)
	 day = "Today"
	elsif (date.eql? (Date.today + 1))
	 day = "Tomorrow"
	else 
		if platform == 'blackberry'
		  day = Time.parse(date.to_s).strftime("%A")
		else
		  day = Date::DAYNAMES[Date.parse(date.to_s).wday]   
		end
	end
	day
  end
  
  def get_formatted_date(date, format="%Y-%m-%d")
    if platform == 'blackberry'
      Time.parse(date.to_s).strftime(format)
    else
      Date.parse(date.to_s).strftime(format)   
    end
  end
  
  def get_nth_date(current_date, n)
     if platform == 'blackberry'
      (Time.parse(current_date.to_s) + (86400 * n)).strftime("%Y-%m-%d")
    else
      Date.parse(current_date.to_s) + n   
    end
  end
  
  def get_page_title
	@@title
  end
end