require "cheepcreep/version"
require "cheepcreep/init_db"
require "httparty"
require "pry"
require 'json'

# in terminal => `GITHUB_USER=foo GITHUB_PASS=bar bundle exec ruby lib/cheepcreep.rb ARGV`
module Cheepcreep
  class GithubUser < ActiveRecord::Base
    validates :login, uniqueness: true, presence: true
    scope :order_desc, -> { order("#{column_name}": :desc) }

    def self.add(response)
      create('login'        => response['login'],
             'name'         => response['name'],
             'blog'         => response['blog'],
             'public_repos' => response['public_repos'],
             'followers'    => response['followers'],
             'following'    => response['following']
            )
    end

    private
    def self.column_name
      column_names.include?(ARGV[0]) ? ARGV[0] : 'followers'
    end
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

  def run(username)
    follower_usernames = followers(username).sample(20)
    add_followers(follower_usernames)
    Cheepcreep::GithubUser.order_desc.each { |user| puts user.login }
  end

  def followers(username)
    response = self.class.get("/users/#{username}/followers")
    puts "#{response.headers['x-ratelimit-remaining']} request left"

    followers = JSON.parse(response.body)
    followers.inject([]) { |memo, follower| memo << follower['login']}
  end

  def add_followers(usernames)
    usernames.each { |username| Cheepcreep::GithubUser.add(user(username)) }
  end

  def user(username)
    response = self.class.get("/users/#{username}")
    puts "#{response.headers['x-ratelimit-remaining']} request left"

    JSON.parse(response.body)
  end

  # def update_user (options={})#nil no work...do't use query params unless get req, need to pass some body.
  #   options = {:body =>{:name => name, :email => email, :blog => blog, :location => location}.json}
  #   self.class.patch('/user',options) #need options
  # end

  # def get_team_members(id)
  #   response = self.class.get("/teams/#{id}/members")
  # end

#list Gists
#   def get_gists(username)
#     response = self.class.get("/users/#{username}/gists")
#     puts "#{response.headers['x-ratelimit-remaining']} request left" #why before JSON
#     gists_json = JSON.parse(response.body)
#     get_gists_id(gists_json)
#   end
#
#   def get_gists_id(gists_json)
#     gists_id = []
#     gists_json.each do |id|
#       id["id"] << gist_id
#     end
#     gist_id
#   end
#
# #delete Gists
#   def delete_gists(id)
#     response = self.class.delete("/gists/#{id}")
#     puts "#{response.headers['x-ratelimit-remaining']} request left" #why before JSON
#   end
#
#   def create_repo(opts={})
#     options = {:body => opts.to_json}
#     response = self.class.post("/users/repos", options)
#     JSON.parse(response.body)
#   end
end

class CheepcreepApp
end
binding.pry

# Github.new.run('rachelpatterson86')
