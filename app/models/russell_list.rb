class RussellList < ActiveRecord::Base
  def self.get_r2000_sym
    start_date = RussellList.all.map(&:date).max || Date.new(2006,9,29)

    # start with end months
    search_dates = (start_date..(Date.today - 1.day)).map { |date| [(Date.today - 1.day), date.end_of_month].min }.uniq
    search_dates.each do |d|
      puts "Getting market cap for #{d.strftime("%F")}..."
      
      # process data
      csv, date = RussellList.get_rsym_csv_data(d)
      
      header = csv[10]
      syms = csv[11..-2]
      
      sym_ix = header.index("Ticker")
      sect_ix = header.index("Sector")
      exch_ix = header.index("Exchange")
      ast_ix = header.index("Asset Class")
      
      syms.delete_if { |s| s[sect_ix]["Financial"] || s[sect_ix]["Energy"] || s[sect_ix]["Oil"] || s[sym_ix] == "-" || s[ast_ix] != "Equity" || s[exch_ix] == "-" }
      
      sym_str = syms.map { |s| s[0].gsub(" ", ".").gsub("*","") }.join("; ")

      # create entry for this month
      if sym_str.blank?
        puts "Couldn't parse for #{date.strftime("%Y-%m-%d")}..."
        RussellList.create(date: date, syms: "")
      else
        # scrub commas out of mkt_cap and save
        RussellList.create(date: date, syms: sym_str)
      end
    end
  end
  
  def self.get_rsym_csv_data(date)
    require 'open-uri'
    require 'csv'
    
    # set proxies in case of need for use
    manager = ProxyFetcher::Manager.new
    
    i = 0
    as_of = ""
    
    while i < 10 && as_of.blank?
      # loop back through dates until date includes data (stop at 10 loops to make sure to avoid infinite loops)
      base_url = "https://www.blackrock.com/us/individual/products/239714/ishares-russell-3000-etf/1464253357814.ajax?fileType=csv&fileName=IWM_holdings&dataType=fund&asOfDate="
      
      # set url
      d = date.strftime("%Y%m%d")
      url = base_url + d
      
      # get csv data
      retries = 0
      begin
        if retries == 0
          url_data = open(url).read()
        else
          url_data = open(url, proxy: URI.parse("http://" + proxy.addr + ":" + proxy.port.to_s))
        end
      rescue
        puts "Failed on try ##{retries + 1}"
        if retries <= 20
          puts "Trying with proxy #{retries + 1}..."
          retries += 1
          proxy = manager.pop!
          retry
        else
          puts "Failed to pull."
          return false
        end
      end
      csv = CSV.parse(url_data)
      
      as_of = csv.find { |row| row[0] == "Fund Holdings as of" }[1]
      
      # increment i and date
      if as_of.blank? 
        puts "going back 1 day..."
        date = date - 1.day
        i += 1
      end
    end
      
    return csv, date
  end
  
  def self.get_r2000_sym_date(date)
    require 'open-uri'
    require 'csv'
    
    url = "https://www.blackrock.com/us/individual/products/239714/ishares-russell-3000-etf/1464253357814.ajax?fileType=csv&fileName=IWM_holdings&dataType=fund&asOfDate=#{date.strftime("%Y%m%d")}"
    url_data = open(url).read()
    csv = CSV.parse(url_data)
    date_check = csv.find { |row| row[0] == "Fund Holdings as of" }[1].blank?
    if date_check
      prev = RussellList.find_by(date: date - 1.day)
      RussellList.create(date: date, mkt_cap: prev.mkt_cap)
    else
      mkt_cap = csv.find { |row| row[0] == "Total Net Assets"}
      if mkt_cap.blank?
        puts "Couldn't parse for #{date.strftime("%Y-%m-%d")}"
        RussellList.create(date: date, mkt_cap: 0)
      else
        # scrub commas out of mkt_cap and save
        RussellList.create(date: date, mkt_cap: mkt_cap[1].gsub(",",""))
      end
    end
  end
end