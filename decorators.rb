# rubocop:disable LineLength
# rubocop:disable EmptyLines

# Receives a "resource" and outputs an json object
class ResourceDecorator  < SimpleDelegator
  def initialize(resource, base_url)
    @base_url = base_url
    super resource
  end

  def jsonify
    links = [Link.new('self', "#{ @base_url }resources/#{ id }"),
             Link.new('bookings', "#{ @base_url }resources/#{ id }/bookings")]
    json = Jsonify::Builder.new
    json.resource do
      json.id id
      json.name name
      json.description description
      json.links(links) do |l|
        json.rel l.type
        json.uri l.url
      end
    end
    json.compile!
  end
end

# Receives a "booking" and outputs an json object
class BookingDecorator  < SimpleDelegator
  def initialize(resource, base_url)
    @base_url = base_url
    super resource
    @links = [Link.new('self', "#{ @base_url }resources/#{ resource_id }/bookings/#{ id }"),
              Link.new('resource', "#{ @base_url }resources/#{ resource_id }"),
              Link.new('accept', "#{ @base_url }resources/#{ resource_id }/bookings/#{ id }", 'PUT'),
              Link.new('reject', "#{ @base_url }resources/#{ resource_id }/bookings/#{ id }", 'DELETE')]
  end

  def jsonify
    json = Jsonify::Builder.new
    json.booking do
      json.resource_id resource_id
      json.id id
      json.from start.strftime('%FT%TZ')
      json.to finish.strftime('%FT%TZ')
      json.status status
      json.user   user
      json.links(@links) do |l|
        json.rel l.type
        json.uri l.url
        json.tag!('method', l.method) unless l.method.nil?
      end
    end
    json.compile!
  end
end


# Receives an iterable of "resources" and outputs an json object
class ResourceCollectionDecorator  < SimpleDelegator
  def initialize(resource, base_url)
    @base_url = base_url
    super resource
  end

  def jsonify
    elem = self
    json = Jsonify::Builder.new
    json.resources(elem) do |e|
      json.id e.id
      json.name e.name
      json.description e.description
      links = [Link.new('self', "#{ @base_url }resources/#{ e.id }")]
      json.links(links) do |l|
        json.rel l.type
        json.uri l.url
      end
    end
    links = [Link.new('self', "#{ @base_url }resources")]
    json.links(links) do |l|
      json.rel l.type
      json.uri l.url
    end
    json.compile!
  end
end


# Receives an iterable of "bookings" and outputs an json object
class BookingCollectionDecorator  < SimpleDelegator
  def initialize(resource, base_url)
    @base_url = base_url
    super resource
  end

  def jsonify(request)
    elem = self
    json = Jsonify::Builder.new
    json.bookings(elem) do |e|
        json.resource_id e.resource_id
      json.id e.id
      json.start e.start.strftime('%FT%TZ')
      json.finish e.finish.strftime('%FT%TZ')
      json.status e.status
      json.user   e.user
      links = [Link.new('self', "#{ @base_url }resources/#{ e.resource_id }/bookings/#{ e.id }"),
               Link.new('resource', "#{ @base_url }resources/#{ e.resource_id }"),
               Link.new('accept', "#{ @base_url }resources/#{ e.resource_id }/bookings/#{ e.id }", 'PUT'),
               Link.new('reject', "#{ @base_url }resources/#{ e.resource_id }/bookings/#{ e.id }", 'DELETE')]
      links.reject! { |l|  l.type == 'accept' } if e.status == 'approved'
      json.links(links) do |l|
        json.rel l.type
        json.uri l.url
        json.tag!('method', l.method) unless l.method.nil?
      end
    end
    links = [Link.new('self', "#{ @base_url }#{ request }")]
    json.links(links) do |l|
      json.rel l.type
      json.uri l.url
    end
    json.compile!
  end
end

# Receives an iterable of "slots" and outputs an json object
class SlotCollectionDecorator  < SimpleDelegator
  def initialize(resource, base_url)
    @base_url = base_url
    super resource
  end

  def jsonify(request)
    elem = self
    json = Jsonify::Builder.new
#    json.freeSlots(elem) do |e|
      json.availabilities(elem) do |e|
      json.start e.start.to_datetime.strftime('%FT%TZ')
      json.finish e.finish.to_datetime.strftime('%FT%TZ')
      links = [Link.new('book', "#{ @base_url }resources/#{ e.id }/bookings", 'POST'),
               Link.new('resource', "#{ @base_url }resources/#{ e.id }")]
      json.links(links) do |l|
        json.rel l.type
        json.uri l.url
        json.tag!('method', l.method) unless l.method.nil?
      end
    end
    links = [Link.new('self', "#{ @base_url }#{ request }")]
    json.links(links) do |l|
      json.rel l.type
      json.uri l.url
    end
    json.compile!
  end
end
