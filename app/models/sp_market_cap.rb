class SpMarketCap < ActiveRecord::Base
  def self.get_mkt_caps
    require 'open-uri'
    require 'csv'
    
    def get_csv_data(date)
      i = 0
      as_of = ""
      
      while i < 10 && as_of.blank?
        # loop back through dates until date includes data
        base_url = "https://www.blackrock.com/us/individual/products/239726/ishares-core-sp-500-etf/1464253357814.ajax?fileType=csv&fileName=IVV_holdings&dataType=fund&asOfDate="
        
        # set url
        d = date.strftime("%Y%m%d")
        url = base_url + d
        
        # get csv data
        url_data = open(url).read()
        csv = CSV.parse(url_data)
        
        as_of = csv.find { |row| row[0] == "Fund Holdings as of" }[1]
        
        # increment down if as_of not resolved
        if as_of.blank? 
          date = date - 1.day
        end
      end
        
      return csv, date
    end
    
    start_date = SpMarketCap.all.map(&:date).max || Date.new(2006,9,29)

    # start with end months
    search_dates = (start_date..(Date.today - 1.day)).map { |date| [(Date.today - 1.day), date.end_of_month].min }.uniq
    search_dates.each do |d|
      puts "Getting market cap for #{d.strftime("%F")}..."
      
      # process data
      csv, date = get_csv_data(d)
      mkt_cap = csv.find { |row| row[0] == "Total Net Assets"}
      
      # create entry for this month
      if mkt_cap.blank?
        puts "Couldn't parse for #{date.strftime("%Y-%m-%d")}..."
        SpMarketCap.create(date: date, mkt_cap: 0)
      else
        # scrub commas out of mkt_cap and save
        SpMarketCap.create(date: date, mkt_cap: mkt_cap[1].gsub(",",""))
      end
    end
  end
  
  def self.get_mkt_caps_date(date)
    require 'open-uri'
    require 'csv'
    
    url = "https://www.blackrock.com/us/individual/products/239726/ishares-core-sp-500-etf/1464253357814.ajax?fileType=csv&fileName=IVV_holdings&dataType=fund&asOfDate=#{date.strftime("%Y%m%d")}"
    url_data = open(url).read()
    csv = CSV.parse(url_data)
    date_check = csv.find { |row| row[0] == "Fund Holdings as of" }[1].blank?
    if date_check
      prev = SpMarketCap.find_by(date: date - 1.day)
      SpMarketCap.create(date: date, mkt_cap: prev.mkt_cap)
    else
      mkt_cap = csv.find { |row| row[0] == "Total Net Assets"}
      if mkt_cap.blank?
        puts "Couldn't parse for #{date.strftime("%Y-%m-%d")}"
        SpMarketCap.create(date: date, mkt_cap: 0)
      else
        # scrub commas out of mkt_cap and save
        SpMarketCap.create(date: date, mkt_cap: mkt_cap[1].gsub(",",""))
      end
    end
  end
end
