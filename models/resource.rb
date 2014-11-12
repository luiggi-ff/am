require 'sinatra/activerecord'

class Resource < ActiveRecord::Base
  has_many :bookings
  def available_slots?(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND start <= ? AND status = ?', id, start, finish, 'approved')
    avail = bookings.load.map { |b| [b.start.strftime('%FT%TZ'), b.finish.strftime('%FT%TZ')] }.sort.flatten

    start_date= start.to_datetime.strftime('%FT%TZ')
    finish_date= finish.to_datetime.strftime('%FT%TZ')
    avail.insert(0, start_date)
    avail.insert(-1, finish_date)

    avail = avail.each_slice(2).to_a
    avail.delete_if {|a| a[0] == a[1] }
    avail.map { |a| Slot.new(id, a[0], a[1]) }
  end

  def remove_pending(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND start <= ? AND status = ?', id, start, finish, 'pending')
    bookings.each { |b| b.destroy }
  end
end


