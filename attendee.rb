require 'ostruct'

class Zipcode
  def self.clean(dirty_zipcode)
    dirty_zipcode.to_s.rjust(5, '0')
  end
end

class PhoneNumber
  def initialize(phone_number)
    @phone_number = phone_number.scan(/\d/).join
  end

  def to_s
    "(#{@phone_number[0..2]}) #{@phone_number[3..5]}-#{@phone_number[6..-1]}"
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

  def phone_number
    PhoneNumber.new(homephone)
  end

  def to_array
    [self.last_name, self.first_name, self.email_address,
      self.zipcode, self.city, self.state, self.street]
  end

  def to_dict
    self.attributes
  end

end
