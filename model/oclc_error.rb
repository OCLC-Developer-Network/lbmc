class OCLCError
  attr_accessor :summary, :validation_errors
  
  def initialize(summary)
    @summary = summary
    @validation_errors = Array.new
  end
end