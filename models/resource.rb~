require 'sinatra/activerecord'

class Resource < ActiveRecord::Base
  has_many :bookings
  def available_slots?(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND start <= ? AND status = ?', id, start, finish, 'approved')
    avail = bookings.load.map { |b| [b.start.strftime('%FT%TZ'), b.finish.strftime('%FT%TZ')] }.sort.flatten
    avail.insert(0, start.to_date.strftime('%FT%TZ'))
    avail.insert(-1, finish.to_date.strftime('%FT%TZ'))
    avail = avail.each_slice(2).to_a
    avail.map { |a| Slot.new(id, a[0], a[1]) }
  end

  def remove_pending(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND start <= ? AND status = ?', id, start, finish, 'pending')
    bookings.each { |b| b.destroy }
  end
end


