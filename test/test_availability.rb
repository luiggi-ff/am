# rubocop:disable LineLength
# rubocop:disable EmptyLines

require 'minitest/autorun'
require_relative '../asset_manager.rb'


DatabaseCleaner.strategy = :transaction
ActiveRecord::Base.logger = nil

class AssetMgrTest < Minitest::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def setup
    DatabaseCleaner.start
  end

  def teardown
    DatabaseCleaner.clean
  end

  def parse_params(str)
    Rack::Utils.parse_query(str)
  end

  def tomorrow
    (Time.now + 1).strftime('%F')
  end

  def booking_id
    MultiJson.load(last_response.body, symbolize_keys: true)[:book][:links][0][:uri].split('/').last.to_i
  end

  def request_params
    MultiJson.load(last_response.body, symbolize_keys: true)[:links][0][:uri].split('/').last.split('?').last
  end


  def availability_pattern(n) 
    {
     availabilities: [
        {
        start: String,
        finish: String,
        links: [
          {
            rel: 'book',
            uri: /\Ahttps?\:\/\/.*\z/i,
            method: 'POST'
          },
          {
            rel: 'resource',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
        ]
      }
     ] * n,
     links: [
          {
            rel: 'self',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
    ]
  }
  end

  def availability_pattern2
    {
     availabilities: [
        {
        start: String,
        finish: String,
        links: [
          {
            rel: 'book',
            uri: /\Ahttps?\:\/\/.*\z/i,
            method: 'POST'
          },
          {
            rel: 'resource',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
        ]
      }
     ],
     links: [
          {
            rel: 'self',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
    ]
  }
  end

  def availability_pattern_1
    {
     availabilities: [
        {
        start: String,
        finish: String,
        links: [
          {
            rel: 'book',
            uri: /\Ahttps?\:\/\/.*\z/i,
            method: 'POST'
          },
          {
            rel: 'resource',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
        ]
      }
     ] * 1,
     links: [
          {
            rel: 'self',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
    ]
  }
  end

  def availability_pattern_0
    {
        availabilities: [
        {
        start: String,
        finish: String,
        links: [
          {
            rel: 'book',
            uri: /\Ahttps?\:\/\/.*\z/i,
            method: 'POST'
          },
          {
            rel: 'resource',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
        ]
      }
     ] * 0,
     links: [
          {
            rel: 'self',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
    ]
  }
  end

  def availability_pattern_2
    {
        availabilities: [
        {
        start: String,
        finish: String,
        links: [
          {
            rel: 'book',
            uri: /\Ahttps?\:\/\/.*\z/i,
            method: 'POST'
          },
          {
            rel: 'resource',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
        ]
      }
     ] * 2,
     links: [
          {
            rel: 'self',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
    ]
  }
  end



  def error_message_pattern
    {
      error_message: String
    }
  end

### Get available slots test
  def test_get_availability_success
    Booking.create(resource_id: 1,
                   start: '2014-05-13 11:00'.to_datetime,
                   finish: '2014-05-13 12:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
    Booking.create(resource_id: 1,
                   start: '2014-05-13 14:00'.to_datetime,
                   finish: '2014-05-13 15:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'pending')
    Booking.create(resource_id: 1,
                   start: '2014-05-14 11:00'.to_datetime,
                   finish: '2014-05-14 12:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
      get '/resources/1/availabilities', 'date' => '2014-05-12', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(3), last_response.body
  end

  def test_get_availability_success_1   #nothing free
    Booking.create(resource_id: 1,
                   start: '2014-12-01 00:00'.to_datetime,
                   finish: '2014-12-04 00:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
      get '/resources/1/availabilities', 'date' => '2014-12-1', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(0), last_response.body
  end

  def test_get_availability_success_2    #booking at begin and finish, slot free in the midle
    Booking.create(resource_id: 1,
                   start: '2014-12-01 00:00'.to_datetime,
                   finish: '2014-12-02 00:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
    Booking.create(resource_id: 1,
                   start: '2014-12-03 00:00'.to_datetime,
                   finish: '2014-12-04 00:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
      get '/resources/1/availabilities', 'date' => '2014-12-1', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(1), last_response.body
  end

  def test_get_availability_success_3   #booking at finish
    Booking.create(resource_id: 1,
                   start: '2014-12-03 00:00'.to_datetime,
                   finish: '2014-12-04 00:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
      get '/resources/1/availabilities', 'date' => '2014-12-1', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(1), last_response.body
  end

  def test_get_availability_success_4   #booking at begin
    Booking.create(resource_id: 1,
                   start: '2014-12-01 00:00'.to_datetime,
                   finish: '2014-12-02 00:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
      get '/resources/1/availabilities', 'date' => '2014-12-1', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(1), last_response.body
  end

  def test_get_availability_success_5   #all free
    get '/resources/1/availabilities', 'date' => '2014-12-1', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(1), last_response.body
  end

  def test_get_availability_success_6   #booking at the middle, free slots at begin and finish
    Booking.create(resource_id: 1,
                   start: '2014-12-02 00:00'.to_datetime,
                   finish: '2014-12-03 00:00'.to_datetime,
                   user: 'luiggi@abc.com',
                   status: 'approved')
      get '/resources/1/availabilities', 'date' => '2014-12-1', 'limit' => '3'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match availability_pattern(2), last_response.body
  end





  def test_get_availability_success_default_params
    get '/resources/1/availabilities'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    params = parse_params(request_params)
    assert_equal ((Date.today) + 1).strftime('%F'), params['date']
    assert_equal '30', params['limit']
    assert_json_match availability_pattern(1), last_response.body
  end

  def test_get_availability_success_default_params2
      get '/resources/1/availabilities', 'limit' => '400'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    params = parse_params(request_params)
    assert_equal '365' , params['limit']
    assert_json_match availability_pattern(2), last_response.body
  end

  def test_get_availability_fail_not_found
      get '/resources/1000/availabilities', 'date' => '2014-02-12', 'limit' => '3'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_get_availability_fail_bad_request
      get '/resources/1/availabilities', 'date' => '2014-02-12', 'limit' => 'asd'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_get_availability_fail_bad_request2
      get '/resources/1/availabilities', 'date' => '12/02/2014', 'limit' => 'asd'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_bad_availability_route
      get '/resources/1/availabilities/'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end
end
