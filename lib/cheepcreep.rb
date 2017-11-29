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

class GithubApi
  attr_reader :auth
  include HTTParty
  base_uri 'https://api.github.com'

  def initialize
    # ENV["FOO"] is like echo $FOO
    @auth = { username: ENV['GITHUB_USER'], password: ENV['GITHUB_PASS'] }
  end

  def rate_limit(response)
    puts "#{response.headers['x-ratelimit-remaining']}"
  end
end

class User < GithubApi
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
    rate_limit(response)

    JSON.parse(response.body)
  end
end

class Gist < GithubApi
  def gists(username)
    response = self.class.get("/users/#{username}/gists")
    JSON.parse(response.body)
    rate_limit(response)
  end

  def delete_gist(gist_id)
    response = self.class.delete("/gists/#{gist_id}", basic_auth: @auth)
    rate_limit(response)
  end

  def star_gist(gist_id)
    response = self.class.put("/gists/#{gist_id}/star",
                              basic_auth: @auth,
                              headers: {
                                "User-Agent" => @auth[:username],
                                "Content-Length" => "0"
                              })
    rate_limit(response)
  end

  def unstar_gist(gist_id)
    response = self.class.delete("/gists/#{gist_id}/star", basic_auth: @auth)
    rate_limit(response)
  end

  def edit_gist(description, content)
    body = gist_file(description, content)
    response = self.class.patch("/gists/#{gist_id}", body: body, basic_auth: @auth)
    rate_limit(response)
  end

  def create_gist(description, content)
    body = gist_file(description, content)
    response = self.class.post("/gists", body: body, basic_auth: @auth)
    rate_limit(response)
  end

  private

  def gist_file(description, content)
    file_name = 'sample.txt'
    File.open(file_name, "w"){ |somefile| somefile.puts content }
    {
      "description": description,
      "public": true,
      "files": {
        "#{file_name}": {
          "content": File.open(file_name, "r"){ |file| file.read }
        }
      }
    }.to_json
  end
end
