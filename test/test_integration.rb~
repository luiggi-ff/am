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


### Integration tests
  def test_create_approve_delete_booking      ## DATES MUST BE IN THE FUTURE!!!
    post '/resources/1/bookings', 'from' => '2015-05-01 10:00', 'to' => '2015-05-01 11:00', 'user' => 'luiggi@gmail.com'
    assert_equal 201, last_response.status

    put "/resources/1/bookings/#{booking_id}"
    assert_equal 200, last_response.status

    delete "/resources/1/bookings/#{booking_id}"
    assert_equal 200, last_response.status
  end

  def test_bad_route
    get '/adsf'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

end
