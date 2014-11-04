require 'sinatra/activerecord'



class Booking < ActiveRecord::Base
  belongs_to :resource
  validates :start, presence: true
  validates :finish, presence: true
  validates :user, presence: true

  def self.from_date(resource, date, to, status)
    bookings = Booking.where('resource_id = ? AND start >= ? AND start <= ?', resource, date, to)
    bookings = bookings.where('status = ?', status) if status != 'all'
    bookings.load
  end

  def self.get_a_booking(r_id, b_id)
    where('id= ? AND resource_id = ?', b_id, r_id).first
  end
end

