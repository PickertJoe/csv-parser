require "csv"
require "date"

class DataFormatter
  attr_reader :valid_data, :invalid_data

  def initialize
    @valid_data = []
    @invalid_data = []
  end

  def parse(input: )
    @csv_text = CSV.new(input, headers: true, header_converters: :symbol)
    @hashed_row_data = @csv_text.to_a.map { |row| row.to_hash }
    validate_presence_of_required_fields
    parse_dates
    parse_phone_numbers
    @valid_data = @hashed_row_data
  end

  def validate_presence_of_required_fields
    @hashed_row_data.each_with_index do |row, index|
      if row.fetch_values(:first_name, :last_name, :dob, :member_id, :effective_date).any?(&:nil?)
        @invalid_data.push(@hashed_row_data.delete_at(index))
      end
    end
  end

  def parse_phone_numbers
    @hashed_row_data.each_with_index do |row, index|
      begin
        row[:phone_number] = format_as_E164(phone_number: row[:phone_number])
      rescue => e
        puts "#{e} for record #{row}"
        @invalid_data.push(@hashed_row_data.delete_at(index))
      end
    end
  end

  def parse_dates
    @hashed_row_data.each_with_index do |row, index|
      begin
        row[:dob] = format_as_ISO8601(date: row[:dob])
        row[:effective_date] = format_as_ISO8601(date: row[:effective_date])
        row[:expiry_date] = format_as_ISO8601(date: row[:expiry_date])
      rescue => e
        puts "#{e} for record #{row}"
        @invalid_data.push(@hashed_row_data.delete_at(index))
      end
    end
  end

  def format_as_ISO8601(date: )
    if date.nil?
      return
    end

    parsable_formats = [
      "%m/%d/%y",
      "%d/%m/%y",
      "%m-%d-%y",
      "%d/%m/%Y",
      "%Y-%m-%d",
    ]

    parsable_formats.each do |format|
      begin
        formatted_date = Date.strptime(date, format).iso8601.to_s
      rescue => exception
        next
      else
        return formatted_date
      end
    end

    raise "Invalid date format"
    date
  end

  def format_as_E164(phone_number: )
    e164_regexp = /^\+1\d{10}$/
    return phone_number if e164_regexp.match?(phone_number) || phone_number.nil?

    stripped_phone_number = phone_number.tr('^0-9', '')

    ten_digit_regexp = /^\d{10}$/
    eleven_digit_regexp = /^1\d{10}$/

    if ten_digit_regexp.match?(stripped_phone_number)
      return "+1" + stripped_phone_number
    elsif eleven_digit_regexp.match?(stripped_phone_number)
      return "+" + stripped_phone_number
    else
      raise "Invalid phone number"
    end
  end
end