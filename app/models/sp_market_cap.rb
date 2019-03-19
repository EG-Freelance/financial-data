class SpMarketCap < ActiveRecord::Base
  def self.get_mkt_caps
    require 'open-uri'
    require 'csv'
    
    base_url = "https://www.blackrock.com/us/individual/products/239726/ishares-core-sp-500-etf/1464253357814.ajax?fileType=csv&fileName=IVV_holdings&dataType=fund&asOfDate="
    start_date = SpMarketCap.all.map(&:date).max || Date.new(2006,9,29)
    (start_date..(Date.today - 1.day)).each do |date|
      puts "Getting market cap for #{date.strftime("%F")}..."
      
      # set url
      d = date.strftime("%Y%m%d")
      url = base_url + d
      
      # get csv data
      url_data = open(url).read()
      csv = CSV.parse(url_data)
      
      # process data
      date_check = csv.find { |row| row[0] == "Fund Holdings as of" }[1].blank?
      if date_check
        # duplicate previous data if no data for this date
        prev = SpMarketCap.find_by(date: date - 1.day)
        if prev.nil?
          puts "No previous day data for #{date.strftime("%F")}..."
          SpMarketCap.create(date: date, mkt_cap: 0)
        else
          SpMarketCap.create(date: date, mkt_cap: prev.mkt_cap)
        end
      else
        mkt_cap = csv.find { |row| row[0] == "Total Net Assets"}
        if mkt_cap.blank?
          puts "Couldn't parse for #{date.strftime("%Y-%m-%d")}..."
          SpMarketCap.create(date: date, mkt_cap: 0)
        else
          # scrub commas out of mkt_cap and save
          SpMarketCap.create(date: date, mkt_cap: mkt_cap[1].gsub(",",""))
        end
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
