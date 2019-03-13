class Constituent < ActiveRecord::Base
  def self.get_current_constituents
    agent = Mechanize.new
    
    response = agent.get('https://en.wikipedia.org/wiki/List_of_S%26P_500_companies')
    
    const_table = response.css('#constituents')
    
    const = const_table.css('tr')
    
    header = const[0].css('th').map { |th| th.text.gsub("\n", "") }
    constituents = const[1..-1].map { |c| c.css('td').map { |td| td.text.gsub("\n", "") } }.map { |c| Hash[*header.zip(c).flatten] }

    constituents.each do |c|
      constituent = Constituent.where(sym: c["Symbol"], name: c["Security"]).first_or_initialize
      next unless constituent.id.nil? # skip if already exists
      added_raw = c["Date first added"]
      if added_raw.match(/\d{4}-\d{2}-\d{2}/).nil?
        # default add date to 1900/01/01
        date = Date.new(1900,1,1)
      else
        date = Date.strptime(added_raw, "%Y-%m-%d")
      end
      constituent.added = date
      constituent.cik = c["CIK"]
      
      constituent.save
    end
  end
  
  def self.get_constituent_changes
    agent = Mechanize.new

    response = agent.get('https://en.wikipedia.org/wiki/List_of_S%26P_500_companies')
    
    tables = response.css('table')
    
    change_table = tables.find { |t| t.css('tr')[0].css('th').map { |th| th.text.gsub("\n", "") }.include?("Reason") } # search for the table that includes "Reason" in the header

    header = ["date", "a_ticker", "a_sec", "r_ticker", "r_sec", "reason"]

    adjustments_raw = change_table.css('tr')[2..-1].map { |c| [c.css('td').map { |td| td.text.gsub("\n", "") }, c.css('td')[0]['rowspan'].to_i] } # [[data....], num_rows] -- necessary to fix multi-row entries
    
    i = 0 # set iterator
    prev_date = nil
    prev_reason = nil
    adjustments = adjustments_raw.map do |a|
      out = a[0]
      if !prev_date.nil?
        out = [prev_date, out, prev_reason].flatten # push in data affected by multi-row entries
        i -= 1
        if i == 0
          # clear prev_vars
          prev_date = nil
          prev_reason = nil
        end
      end
      
      if a[1].to_i > 0
        i = a[1] - 1
        prev_date = a[0][0]
      end
      
      out
    end

    adjustments = adjustments.map { |c| Hash[*header.zip(c).flatten] }
    
    adjustments.each do |a|
      date = Date.parse(a['date'])
      if !a['a_ticker'].blank?
        # remove trailing inc, corp, ltc, and plc
        name = a['a_sec'].gsub(/\,?\s(?:corp\.?|ltd\.?|inc\.?|plc\.?)\z/i, "")
        if Constituent.exists?(['sym = ? AND added > ? AND added < ?', a['a_ticker'], date - 7.days, date + 7.days])
          puts "ignore..."
        else
          if Rails.env == "development"
            add_constituent = Constituent.where("(sym = ? AND name LIKE ?) OR name = ?",a['a_ticker'], "#{name}%", name).first_or_initialize
          else
            add_constituent = Constituent.where("(sym = ? AND name ~* ?) OR name = ?",a['a_ticker'], "#{name}.*", name).first_or_initialize
          end
          if add_constituent.id.nil?
            add_constituent.sym = a['a_ticker']
            add_constituent.name = a['a_sec']
          end
          add_constituent.added = date
          add_constituent.save
        end
      end
      
      if !a['r_ticker'].blank?
        if Rails.env == "development"
        # remove trailing inc, corp, ltc, and plc
        name = a['r_sec'].gsub(/\,?\s(?:corp\.?|ltd\.?|inc\.?|plc\.?)\z/i, "")
          rm_constituent = Constituent.where("(sym = ? AND name LIKE ?) OR name = ?",a['r_ticker'], "#{name}%", name).first_or_initialize
        else
          rm_constituent = Constituent.where("(sym = ? AND name ~* ?) OR name = ?",a['r_ticker'], "#{name}.*", name).first_or_initialize
        end
        if rm_constituent.id.nil?
          rm_constituent.sym = a['r_ticker']
          rm_constituent.name = a['r_sec']
        end
        rm_constituent.removed = date
        rm_constituent.save
      end
    end
    
    self.clean_up
  end
  
  def self.clean_up
    # clean special cases
    # CMCSK
    cmcsk = Constituent.find_by(sym: "CMCSK", added: nil)
    if cmcsk
      Constituent.find_by(sym: "CMCSK", removed: nil).update(removed: cmcsk.removed)
      cmcsk.destroy
    end
    
    # Q
    Constituent.find_by(name: "QuintilesIMS").try(:destroy) # just destroy, there is no removal date
    
    # KORS
    Constituent.find_by(sym: "KORS").try(:destroy) # just destroy, there is no removal date
    
    # GGP
    ggp = Constituent.find_by(sym: "GGP", added: nil)
    if ggp
      Constituent.find_by(sym: "GGP", removed: nil).update(removed: ggp.removed)
      ggp.destroy
    end
    
    # DLPH
    Constituent.find_by(sym: "DLPH").try(:destroy) # just destroy, there is no removal date
    
    # TYC
    Constituent.find_by(sym: "TYC").try(:destroy) # just destroy, there is no removal date
    
    # PCLN
    Constituent.find_by(sym: "PCLN").try(:destroy) # just destroy, there is no removal date
    
    # LUK
    Constituent.find_by(sym: "LUK").try(:destroy) # just destroy, there is no removal date
    
    # KFT
    Constituent.find_by(sym: "KFT").try(:destroy) # just destroy, there is no removal date
  end
end

### SPECIAL CASES ###
# KORS => CPRI
# Q => IQV
# GGP => GGP (different name)
# DLPH => APTV
# TYC => JCI
# PCLN => BKNG
# LUK => JEF
# KFT => KRFT
# CMCSK