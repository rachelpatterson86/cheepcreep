require "cheepcreep/version"
require "cheepcreep/init_db"
require "httparty"
require "pry"
require 'json'

#response = HTTParty.get("https://api.github.com/users/redline6561/gists")
#browser = https://api.github.com/users/redline6561/gists
# in terminal => ENV['apitest'] ENV 'IronYard1!' budle exec ruby lib...
# TODO: QUESTION = un/pw, are those dummie?
# TODO: QUESTION = review option.merge!
# TODO: QUESTION = review query param syntax. gh docs
# TODO: QUESTION = review query param logic
# TODO: QUESTION = look at and review : #why before JSON
# TODO: QUESTION = review update_user fx
# TODO: QUESTION = attr_* review
# TODO: QUESTION = keywords and yield

module Cheepcreep
  class GithubUser < ActiveRecord::Base
    validates :login, uniqueness: true, presence: true
  end
end

class Github
  attr_reader :auth #why use?
  include HTTParty
  base_uri 'https://api.github.com'

  def initialize
    # ENV["FOO"] is like echo $FOO
    @auth = {:username => ENV['GITHUB_USER'], :password => ENV['GITHUB_PASS']}
  end

  def get_followers(username, per_page = 50, page = 2)
    options= {:query => {:per_page => per_page, :page => page}}
    options.merge!({:basic_auth => @auth})
    follower_list = []
    response = self.class.get("/users/#{username}/followers", options) #can also use Github.get...
    puts "#{response.headers['x-ratelimit-remaining']} request left" #why before JSON
    json = JSON.parse(response.body)
    json.sample(20).each do |f|
      followers_list << f["login"]
    end
    followers_list
  end

  def get_users_all( per_page = 50, page = 2)
    options= {:query => {:per_page => per_page, :page => page}}
    response = self.class.get("/users")
    puts "#{response.headers['x-ratelimit-remaining']} request left" #why before JSON
    json = JSON.parse(response.body)
  end

  def get_users(username)
    response = self.class.get("/users")
    puts "#{response.headers['x-ratelimit-remaining']} request left" #why before JSON
    json = JSON.parse(response.body)
  end

  def update_user (options={})#nil no work...do't use query params unless get req, need to pass some body.
    options = {:body =>{:name => name, :email => email, :blog => blog, :location => location}.json}
    self.class.patch('/user',options) #need options
  end

  def get_team_members(id)
    response = self.class.get("/teams/#{id}/members")
  end

  def get_gist(username)
    response = self.class.get("/users/#{username}/gist")
    puts "#{response.headers['x-ratelimit-remaining']} request left" #why before JSON
  end

  def create_repo(opts={})
    options = {:body => opts.to_json}
  response = self.class.post("/users/repos", options)
  JSON.parse(response.body)
  end
end

class CheepcreepApp
  include GithubUser
end


def add_user(json)
user = Cheepcreep::GithubUser.new
[:login, :name, :blog, :public_repos, :followers, :following].each do |k|
  user[k] = json[k.to_s]
  #active rec model can index like a hash for the table
  end
  user.save
  #or put all credentials in a hash and then insert hash into db...
end

binding.pry
creeper = CheepcreepApp.new("redline6561")
Cheepcreep::GithubUser.find_or_create_by('login'        => response['login'],
                                         'blog'         => response['blog'],
                                         'public_repos' => response['public_repos'],
                                         'public_repos' => response['followers'],
                                         'following'    => response['following']
                                         )
