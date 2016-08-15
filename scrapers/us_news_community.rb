#!/usr/bin/env ruby

require 'json'
require 'rubygems'
require 'nokogiri'
require 'open-uri'
require 'json'
require 'uri'
require 'httparty'

library_json = JSON.parse(HTTParty.get('https://raw.githubusercontent.com/Hipo/university-domains-list/master/world_universities_and_domains.json'))

$domains = []
library_json.each do |e|
	$domains.push e['domain']
end

#puts $domains.length



# list = []
states = ['alabama','alaska','arizona','arkansas','california','colorado','connecticut','delaware','florida','georgia','hawaii','idaho','illinois','indiana','iowa','kansas','kentucky','louisiana','maine','maryland','massachusetts','michigan','minnesota','mississippi','missouri','montana','nebraska','nevada','new-hampshire','new-jersey','new-mexico','new-york','north-carolina','north-dakota','ohio','oklahoma','oregon','pennsylvania','rhode-island','south-carolina','south-dakota','tennessee','texas','utah','vermont','virginia','washington','west-virginia','wisconsin','wyoming']

$counter = 0

def process_school(name, detail_url, file)
	begin
		detail_page = Nokogiri::HTML(open("http://www.usnews.com#{detail_url}"))
	
		website = detail_page.css('a:contains(\'College Website\')').attribute('href')
	
		domain = website.to_s.match(/https?:\/\/(?:www\.)?([^\/]*)/).captures[0].downcase

		if not $domains.include? domain
			$counter = $counter + 1
			file.puts "{"
			file.puts "      \"alpha_two_code\": \"US\","
			file.puts "      \"country\": \"United States\","
			file.puts "      \"domain\": \"#{domain}\","
			file.puts "      \"name\": \"#{name}\","
			file.puts "      \"web_page\": \"#{website}\""
			file.puts "},"
		
		end
	rescue Interrupt
		exit 1
	rescue Exception => e
		puts "Error processing #{detail_page}: #{e.message}"
	end

end

File.open('us_community_colleges.json', 'w') { |file|
	states.each do |state|
		page_index = 1
		more_pages = true
		while more_pages do
			begin
				url = "http://www.usnews.com/education/community-colleges/#{state}?page=#{page_index}"
				puts "Processing #{url}"
				page = Nokogiri::HTML(open(url))
				page.css('.school-name > a').each do |school_name_href|
					name = school_name_href.text.strip
					link = school_name_href['href']
					process_school(name, link, file)
				end
				more_pages = (page.css('.pager_link:contains(\'>\')').count > 0)
				page_index = page_index + 1
			rescue Interrupt
				exit 1
			rescue Exception => e
				puts "Error: #{e.message}"
			end
		end
	end
}
puts "Total new schools found: #{$counter}"

