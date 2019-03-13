class Edgar < ActiveRecord::Base
  
  def get_data_edgar(sym)
    agent = Mechanize.new
    key = "f830fc9b91bce59373389fccadfdfe04"
    base = "https://datafied.api.edgar-online.com/v2/corefinancials/"
  end
  
  def get_data_intrinio
    agent = Mechanize.new
    key_sb = "OmE1MTdmNDZjN2NkZTE1NzI4ZGVmODg1Njc3ODI0MGEz"
    key = "OmRkNDE2YjJlNzVjYzVmN2NlMTRmMmMzMDM0OGU3MmQz"
    base = "https://api-v2.intrinio.com/"
    key_int = "MTIzNjI1YzNiMmUwNzUzYzFkNDNmN2IwNGM3ZDk1MDQ6MDQwNDEwNWNiN2Y3MGEyYjc4ZTE3OWEwMjI2N2VlZDQ="
  end
end
