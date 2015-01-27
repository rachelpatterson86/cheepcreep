require "cheepcreep/version"
require "cheepcreep/init_db"
require "httparty"
require "pry"
require 'json'


#pull data from the Github API, put it in the database, and then print a sorted list of users

#When run with GITHUB_USER=foo GITHUB_PASS=bar bundle exec ruby lib/cheepcreep.rb
#the script should choose 20 of my (redline6561) users at random. Then it will get
#their data and create matching database records for each one. Finally, it will print
#a list of users sorted by the number of their followers.

module Cheepcreep
end

class Github
  include HTTParty
  base_uri 'https://api.github.com'

  # def initialize
  #   # ENV["FOO"] is like echo $FOO
  #   @auth = {:username => ENV['GITHUB_USER'], :password => ENV['GITHUB_PASS']}
  # end

  def get_followers(username)
    options = {:basic_auth => @auth}
    follower_list = []
    response = self.class.get("/users/#{username}/followers")
    json = JSON.parse(response.body)
    json.sample(20) do |f|
      followers_list << f["login"]  #push followers push into empty array..
    end
    followers_list
  end

  #response = HTTParty.get("https://api.github.com/users/redline6561/gists")

  def get_users
    response = self.class.get("/users")
    all_users_list = []
    json = JSON.parse(response.body)
    json do |users|
      all_users_list << users["login"]  #push followers push into empty array..
    end
    all_users_list
  end

  def get_gist(username)
    response = self.class.get("/users/#{username}/gist")
    binding.pry
  end

end

class CheepcreepApp
end

binding.pry

creeper = CheepcreepApp.new("redline6561")
creeper.creep
