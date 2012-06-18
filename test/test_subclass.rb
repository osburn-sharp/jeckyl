require File.join(File.dirname(__FILE__), 'test_class')

class Bclass < Aclass
  
  def configure_another(text)
    default "Hey"
    a_string(text)
    
  end
  
end