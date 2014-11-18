# rubocop:disable LineLength
# rubocop:disable EmptyLines
#

require 'bundler'
Bundler.require:default, ENV['RACK_ENV'] ||= 'development'
require './decorators'
require './models/resource'
require './models/booking'
require './helpers'


DB_CONFIG = YAML::load(File.open('config/database.yml'))[ENV['RACK_ENV']]
APP_CONFIG = YAML::load(File.open('config/app.yml'))[ENV['RACK_ENV']]

set :database, "#{DB_CONFIG['adapter']}:///#{DB_CONFIG['database']}"
set :port, APP_CONFIG['port']
set :base_url, APP_CONFIG['base_url']

Link = Struct.new(:type, :url, :method)
Slot = Struct.new(:id, :start, :finish)


before do
  content_type 'application/json', charset: 'utf-8'
end


get '/resources' do
  resources = Resource.all
  ResourceCollectionDecorator.new(resources, settings.base_url).jsonify
end

post '/resources' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless  valid_string?(params[:name]) \
                                                       && valid_string?(params[:description])


#!params[:name].nil? \
 #                                                       || !params[:description].nil?

#unless valid_string?(params[:name]) \
 #                                                       && valid_string?(params[:description])
  new_resource = Resource.create(name: params[:name],
                                 description: params[:description])
  unless new_resource.nil?
    status 201
    ResourceDecorator.new(new_resource, settings.base_url).jsonify
  end

end

put '/resources/:r_id' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless  valid_string?(params[:name]) \
                                                       && valid_string?(params[:description]) \
                                                       && valid_integer?(params[:r_id])
#  p params[:r_id]
#&& !valid_integer?(params[:r_id])
  resource = Resource.find_by_id(params[:r_id])
  if resource.nil?
    halt 404, json({ error_message: "Resource NOT FOUND" })
  else
    resource.name = params[:name]
    resource.description = params[:description]
    if resource.save
      ResourceDecorator.new(resource, settings.base_url).jsonify
    end
  end

end




get '/resources/:id' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:id])

  halt 404, json({ error_message: "Resource NOT FOUND" }) unless Resource.exists?(params[:id])

  resource = Resource.find_by_id(params[:id])
  ResourceDecorator.new(resource, settings.base_url).jsonify
end

delete '/resources/:id' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:id])
  halt 404, json({ error_message: "Resource NOT FOUND" }) unless Resource.exists?(params[:id])
  resource = Resource.find_by_id(params[:id])
  resource.destroy
end



get '/resources/:id/bookings' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:id]) \
                                                        && (params[:limit].nil? || valid_integer?(params[:limit])) \
                                                        && (params[:date].nil? || valid_date?(params[:date]))

  limit = check_and_set(params[:limit], 30, 365)
  params[:date] ||= tomorrow
  params[:status] ||= 'approved'
  date = params[:date].to_date
  to = (params[:date].to_date + limit)

  halt 404, json({ error_message: "Resource NOT FOUND" }) unless Resource.exists?(params[:id])

  bookings = Booking.from_date(params[:id], date, to, params[:status])

  request = "resources/#{ params[:id] }/bookings?date=#{ date }&limit=#{ limit }&status=#{ params[:status] }"
  BookingCollectionDecorator.new(bookings, settings.base_url).jsonify(request)

end


get '/resources/:id/availability' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:id]) \
                                                        && (params[:limit].nil? || valid_integer?(params[:limit])) \
                                                        && (params[:date].nil? || valid_date?(params[:date]))

  limit = check_and_set(params[:limit], 30, 365)
  params[:date] ||= tomorrow
  date = params[:date].to_date
  to = (params[:date].to_date + limit)

  halt 404, json({ error_message: "Resource NOT FOUND" }) unless Resource.exists?(params[:id])

  avail = Resource.find_by_id(params[:id]).available_slots?(date, to)
  request = "resources/#{ params[:id] }/availability?date=#{ date }&limit=#{ limit }"
  SlotCollectionDecorator.new(avail, settings.base_url).jsonify(request)
end


post '/resources/:id/bookings' do
#  p '/resources/#{params[:id]}/bookings', valid_integer?(params[:id]) 
#  p valid_datetime?(params[:from]) 
#  p valid_datetime?(params[:to]) 
#  p Time.now < params[:from].to_datetime 
#  p params[:from].to_datetime < params[:to].to_datetime




  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:id]) \
                                                        && valid_datetime?(params[:from]) \
                                                        && valid_datetime?(params[:to]) \
                                                        && Time.now < params[:from].to_datetime \
                                                        && params[:from].to_datetime < params[:to].to_datetime

  halt 404, json({ error_message: "Resource NOT FOUND" })  unless Resource.exists?(params[:id])

  resource = Resource.find_by_id(params[:id])
#  p "book - params",params[:from].to_datetime, params[:to].to_datetime
#  p "book - available slots",resource.available_slots?(params[:from].to_datetime, params[:to].to_datetime)
  if resource.available_slots?(params[:from].to_datetime, params[:to].to_datetime).size == 1
    new_booking = Booking.create(resource_id: params[:id],
                                 start: params[:from].to_datetime,
                                 finish: params[:to].to_datetime,
                                 user: params[:user],
                                 status: 'pending')
    unless new_booking.nil?
      status 201
      BookingDecorator.new(new_booking, settings.base_url).jsonify
    end
  else halt 409, json({ error_message: "Booking CONFLICT" })
  end
end


delete '/resources/:r_id/bookings/:b_id' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:r_id]) \
                                                        && valid_integer?(params[:b_id])

  booking = Booking.get_a_booking(params[:r_id], params[:b_id])
  if booking.nil?
    halt 404, json({ error_message: "Booking NOT FOUND" })
  else
    booking.destroy
  end
end


put '/resources/:r_id/bookings/:b_id' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:r_id]) \
                                                        && valid_integer?(params[:b_id])

  booking = Booking.get_a_booking(params[:r_id], params[:b_id])
  if booking.nil?
    halt 404, json({ error_message: "Booking NOT FOUND" })
  else
    resource = Resource.find_by_id(params[:r_id])
    if resource.available_slots?(booking.start, booking.finish).size == 1
      booking.status = 'approved'
      if booking.save
        resource.remove_pending(booking.start, booking.finish)
        BookingDecorator.new(booking, settings.base_url).jsonify
      end
    else
      halt 409, json({ error_message: "Booking CONFLICTS with another approved Booking" })
    end
  end
end


get '/resources/:r_id/bookings/:b_id' do
  halt 400, json({ error_message: "BAD REQUEST" })  unless valid_integer?(params[:r_id]) \
                                                        && valid_integer?(params[:b_id])

  booking = Booking.get_a_booking(params[:r_id], params[:b_id])
  if booking.nil?
    halt 404, json({ error_message: "Booking NOT FOUND" })
  else
    BookingDecorator.new(booking, settings.base_url).jsonify
  end
end


route :get, :post, :put, :patch,:delete, "/*" do
  halt 404, json({ error_message: "NOT FOUND" })
end
