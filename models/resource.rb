require 'sinatra/activerecord'

class Resource < ActiveRecord::Base
  has_many :bookings
  def available_slots2?(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND finish <= ? AND status = ?', id, start.to_datetime, finish.to_datetime, 'approved')
    #bookings = Booking.where('resource_id = ? AND start >= ?  AND status = ?', id, start,  'approved')
    p "ava - start - finish", start, finish
    booking = bookings.load
    p "booking", booking
    if booking.empty?
      p "vacio"

      avail = [start.strftime('%FT%TZ'), finish.strftime('%FT%TZ')]      
    else
      p "no vacio"

      avail= booking.map { |b| [b.start.strftime('%FT%TZ'), b.finish.strftime('%FT%TZ')] }
    end 
    avail=avail.sort.flatten
    p "ava - availlable slots", avail
    start_date= start.to_datetime.strftime('%FT%TZ')
    finish_date= finish.to_datetime.strftime('%FT%TZ')
    if avail.size==2
       if avail.first==start_date && avail.last == finish_date
          avail=[]
       end
    end      

    if !avail.empty?
      p "no vacio"
      if avail[0]!=start_date
         avail.insert(0, start_date)
      end
      if avail.last!=finish_date
        avail.insert(-1, finish_date)
      end
    else
      avail=[start_date,finish_date]
    end 
    avail = avail.each_slice(2).to_a
    avail.delete_if {|a| a[0] == a[1] }
    avail.map! { |a| Slot.new(id, a[0], a[1]) }
    return avail
  end

    
  def available_slots?(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND finish <= ? AND status = ?', id, start.to_datetime, finish.to_datetime, 'approved')
    avail = bookings.load.map { |b| [b.start.strftime('%FT%TZ'), b.finish.strftime('%FT%TZ')] }.sort.flatten
    if start == DateTime.now.to_date
       start_date = ((DateTime.now + 1.hour).change(:hour => 0)).strftime('%FT%TZ')
       # start_date= (start_date 
    else     
       start_date= start.to_datetime.strftime('%FT%TZ')
    end
    finish_date= finish.to_datetime.strftime('%FT%TZ')

    avail.insert(0, start_date)
    avail.insert(-1, finish_date)
    avail = avail.each_slice(2).to_a
    avail.delete_if {|a| a[0] == a[1] }
    avail.map! { |a| Slot.new(id, a[0], a[1]) }
    return avail
  end



  def remove_pending(start, finish)
    bookings = Booking.where('resource_id = ? AND start >= ? AND start <= ? AND status = ?', id, start, finish, 'pending')
    bookings.each { |b| b.destroy }
  end
end


