class Company < ActiveRecord::Base
  attr_accessible :link, :name
  has_many :company_infos
  
  def self.clean_data
    
    companies = Hash.new
    
    Company.all.each do |company|
      companies[company] = {"votes" => 0,
                            4 => {17 => false,
                                  18 => false,
                                  19 => false,
                                  20 => false,
                                  21 => false,
                                  22 => false,
                                  23 => false,
                                  24 => false,
                                  25 => false,
                                  26 => false,
                                  27 => false
                                  }
                            }
      company.company_infos.each do |ci|
        companies[company][ci.created_at.month][ci.created_at.day] = ci.votes
        companies[company]["votes"] = ci.votes
      end
    end
    
    return companies.sort_by { |k,v| v["votes"] }.reverse
    
  end
  
  def self.order_by_votes
    votes = Hash.new
    Company.all.each do |c|
      v = c.company_infos
      votes[c] = {"votes" => v.last.votes,
                  "count" => v.count,
                  "all" => v}
    end
    return votes.sort_by { |k,v| v["votes"] }.reverse
  end
  
  # Pitch2Ritch
  def self.get_p2r_details
    
    all_html = ""
    companies = Hash.new
    page = 1
    continue = true

    while continue
      # Load first page
      @payload ={
          "Category" => "Grow",
          "PageNumber" => page
        }.to_json
      
        puts "Getting Page #{page}"
      
        req = Net::HTTP::Post.new("/api/pitch/SearchPitches", initheader = {'Content-Type' =>'application/json'})
        req.body = @payload
        response = Net::HTTP.new("www.virginmediabusiness.co.uk", 80).start {|http| http.request(req) }
      
        all_html = "#{all_html}#{JSON.parse(response.body)["PitchesAsHtml"]}"
      
        if JSON.parse(response.body)["MorePitchesAvailable"]
          page = page + 1
        else
          puts "No more pages left - moving on"
          continue = false
        end
      end
      
      # Nokogiri the response
      html = Nokogiri::HTML(all_html)
      # Get Details
      names     = html.css('.ptr-search-pitch-block-results-item-heading')
      locations = html.css('.ptr-search-pitch-block-results-item-location')
      # Make the companies!
      count = 0
      html.css('.ptr-search-pitch-block-results-link-container').css('a').each do |link|
        
        # Open each page
        puts "Getting details for #{link.attributes["href"].value}"
        doc = Nokogiri::HTML(open("http://www.virginmediabusiness.co.uk/#{link.attributes["href"].value}"))
        
        # Need to filter out youtube links
        unless names[count].text.include?("youtu.be")
          # Create company if needed
          if Company.find_by_name(names[count].text).nil? 
            Company.create!( :name => names[count].text, :link => link.attributes["href"].value)
          end
        
          company = Company.find_by_name(names[count].text)
          company.company_infos.create!(:votes => doc.css(".ptr-pitch-meta-votes-count").text.gsub(",","").to_i)
        end
        
        count = count + 1
      end 

      # Now we need to get the stats for each company
      
      return "Done!"
      
  end
  
end
