require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_homephone(homephone)
  parsed_homephone = homephone.gsub(/[^0-9]/, '')
  if !parsed_homephone.length.eql?(10, 11) ||
       (parsed_homephone.length == 11 && parsed_homephone[0] != '1')
    'Invalid Phone Number'
  else
    parsed_homephone[-10..-1]
  end
end

def parse_date(date)
  Time.strptime(date, '%D %k:%M')
end

def time_targeting(parsed_csv, col_name)
  parsed_csv
    .map { |row| parse_date(row[col_name]).hour }
    .tally
    .sort_by { |hour, _count| hour }
    .to_h
end

def day_of_week_targeting(parsed_csv, col_name)
  parsed_csv
    .map { |row| parse_date(row[col_name]).wday }
    .tally
    .sort_by { |day, _count| day }
    .to_h
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: %w[legislatorUpperBody legislatorLowerBody]
    ).officials
  rescue StandardError
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') { |file| file.puts form_letter }
end

puts 'EventManager initialized.'

contents =
  CSV.open('event_attendees.csv', headers: true, header_converters: :symbol)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter

# contents.each do |row|
#   id = row[0]
#   name = row[:first_name]
#   zipcode = clean_zipcode(row[:zipcode])
#   legislators = legislators_by_zipcode(zipcode)

#   form_letter = erb_template.result(binding)

#   save_thank_you_letter(id, form_letter)
# end

# contents.each { |row| puts parse_date(row[:regdate]).hour }

puts day_of_week_targeting(contents, :regdate)
contents.rewind
puts time_targeting(contents, :regdate)
