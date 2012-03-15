require 'ostruct'

class Zipcode
  INVALID_ZIPCODE = "00000"

  def self.clean(dirty_zipcode)
    dirty_zipcode.to_s.rjust(5, '0')
  end
end

class PhoneNumber
  INVALID_PHONE_NUMBER = "0"*10

  def initialize(phone_number)
    @phone_number = phone_number.scan(/\d/).join

    if @phone_number.length == 10
      @phone_number
    elsif (@phone_number.length == 11) && (@phone_number[0] == "1")
      @phone_number = @phone_number[1..-1]
    else
      @phone_number = INVALID_PHONE_NUMBER
    end
  end

  def to_s
    @phone_number
  end
end

class Attendee < OpenStruct
  attr_accessor :attributes

  def initialize(attributes)
    self.attributes = attributes
    # Clean the attributes data?
    super
  end

  def full_name
    [first_name, last_name].join(' ')
  end

  def zipcode
    Zipcode.clean(super)
  end

  def homephone
    PhoneNumber.new(self.attributes[:homephone])
  end

  def to_array
    [self.last_name, self.first_name, self.email_address,
      zipcode, self.city, self.state, 
      homephone, self.street]
  end

  def to_dict
    self.attributes
  end

end
