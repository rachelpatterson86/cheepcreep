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
  attr_reader :auth
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

  def gists(username)
    response = self.class.get("/users/#{username}/gists")
    puts "#{response.headers['x-ratelimit-remaining']}"
    gists_json = JSON.parse(response.body)
  end

  def delete_gist(gist_id)
    response = self.class.delete("/gists/#{gist_id}", basic_auth: @auth)
    puts "#{response.headers['x-ratelimit-remaining']}"
  end

  def star_gist(gist_id)
    response = self.class.put("/gists/#{gist_id}/star", basic_auth: @auth, headers: headers)
    puts "#{response.headers['x-ratelimit-remaining']}"
  end

  def headers
    {
      "User-Agent" => ENV['GITHUB_USER'],
      "Content-Length" => "0"
    }
  end

  def unstar_gist(gist_id)
    response = self.class.delete("/gists/#{gist_id}/star", basic_auth: @auth)
    puts "#{response.headers['x-ratelimit-remaining']}"
  end

  def edit_gist(gist_id)
    options = {
      "description": "the description for this gist",
      "files": {
        "sample.txt": {
          "content": 'new content!'
        }
      }
    }.to_json

    response = self.class.patch("/gists/#{gist_id}", body: options, basic_auth: @auth)
    puts "#{response.headers['x-ratelimit-remaining']}"
  end

  def create_gist
    response = self.class.post("/gists", body: gist_file, basic_auth: @auth)
    puts "#{response.headers['x-ratelimit-remaining']}"
  end
end

def gist_file
  file_name = 'sample.txt'
  gist_file = File.open(file_name, "w"){ |somefile| somefile.puts "Hello file!"}
  {
    "description": "the description for this gist",
    "public": true,
    "files": {
      "#{file_name}": {
        "content": File.open(file_name, "r"){ |file| file.read }
      }
    }
  }.to_json
end
