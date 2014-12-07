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

  def resource_pattern
    {
      resource: {
        id: Integer,
        name: String,
        description: String,
        links: [
          {
            rel: 'self',
            uri: /\Ahttps?\:\/\/.*\z/i
          },
          {
            rel: 'bookings',
            uri: /\Ahttps?\:\/\/.*\z/i
          }
        ]
      }
    }
  end

  def resources_pattern
    {
      resources: [
        {
            id: Integer,
          name: String,
          description: String,
          links: [
            {
              rel: 'self',
              uri: /\Ahttps?\:\/\/.*\z/i
            }
          ]
        }
      ] * 3,
      links: [
        {
          rel: 'self',
          uri: /\Ahttps?\:\/\/.*\z/i
        }
      ]
    }
  end

### Get resources tests
  def test_get_resources
    get '/resources'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match resources_pattern, last_response.body
  end



### Get resource tests
  def test_get_resource_success
    get '/resources/1'
    assert_equal 200, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match resource_pattern, last_response.body

  end

  def test_get_resource_fail_not_exist
    get '/resources/100'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_get_resource_fail_bad_request
    get '/resources/asd'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

    def test_bad_resource_route
    get '/resources/1/'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

### Create resource tests

  # parameters missing
  def test_create_fail
    post '/resources'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_create_success   
    post '/resources', 'name' => 'proyector2', 'description' => 'proyector S/N 12345'
    assert_equal 201, last_response.status
    assert_json_match resource_pattern, last_response.body
  end

  def test_create_fail   
    post '/resources',  'description' => 'proyector S/N 12345'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end


### Modify resource tests
  def test_modify_resource_fail_bad_request
    put '/resources/1'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_modify_resource_fail_bad_request_2
    put '/resources/asd', 'name' => 'Monitor2', 'description' => 'Monitor S/N 55544'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end


  def test_modify_resource_success
    put '/resources/2', 'name' => 'Monitor2', 'description' => 'Monitor S/N 55544'
    assert_equal 200, last_response.status
    assert_json_match resource_pattern, last_response.body
  end

  def test_modify_resource_fail_not_found
    put '/resources/2000', 'name' => 'Monitor2', 'description' => 'Monitor S/N 55544'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end



### Delete resource tests
  def test_delete_resource_sucess
    delete '/resources/3'
    assert_equal 200, last_response.status
  end

  def test_delete_resource_fail_not_found
    delete '/resources/500'
    assert_equal 404, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end

  def test_delete_resource_fail_bad_request
    delete '/resources/asd'
    assert_equal 400, last_response.status
    last_response.headers['Content-Type'].must_equal 'application/json;charset=utf-8'
    assert_json_match error_message_pattern, last_response.body
  end


end
