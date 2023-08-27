require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def legislators_by_zipcode(zipcode)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
  begin
    civic_info.representative_info_by_address(
      address: zipcode,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_zip(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def filter_dates(array)
  dates = []
  array.each do |item|
    dates.push(Hash[hour: item.hour, day: item.wday])
  end
  dates
end

def peak_day(array)
  day_organized = {
    0 => 'Sunday',
    1 => 'Monday',
    2 => 'Tuesday',
    3 => 'Wednesday',
    4 => 'Thursday',
    5 => 'Friday',
    6 => 'Saturday'
  }
  days = array.map { |item| item[:day] }
  days_repeated = {}
  max_repeat_day = []
  days.each do |element|
    days_repeated[element] = days.count(element)
  end
  days_repeated.each_pair do |key, value|
    max_repeat_day.push(key) if days_repeated.values.max == value
  end
  day_organized[max_repeat_day[0].to_i]
end

def peak_time(array)
  hours = array.map { |item| item[:hour] }
  hours_repeated = {}
  max_repeat_hour = []
  hours.each do |element|
    hours_repeated[element] = hours.count(element)
  end
  hours_repeated.each_pair do |key, value|
    max_repeat_hour.push(key) if hours_repeated.values.max == value
  end
  max_repeat_hour
end

def parse_time(hour, year)
  year = Date.strptime(year, '%D')
  Time.parse(hour, year)
end

def clean_phone_numbers(number)
  number = number.scan(/\d/).join('')
  if number.length == 10
    number
  elsif number.length == 11 && number[0] == '1'
    number[0] = ''
    number
  else
    'Wrong number!'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
peak_hours = []

contents.each do |row|
  name = row[:first_name]
  id = row[0]

  zipcode = clean_zip(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)
  phone_number = clean_phone_numbers(row[:homephone])
  data_time = row[:regdate].split(' ')
  peak_hours.push(parse_time(data_time[1], data_time[0]))
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end
p peak_time(filter_dates(peak_hours))
p peak_day(filter_dates(peak_hours))
