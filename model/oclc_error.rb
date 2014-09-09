class OCLCError
  attr_accessor :message, :validation_errors
  
  def initialize(message)
    @message = message
    @validation_errors = Array.new
  end
end