# frozen_string_literal: true

require 'faraday'
require 'json'
require 'down'
require 'fileutils'
require 'yaml'

DOWNLOAD_DIR = YAML.safe_load(File.read('config.yaml'))['download_dir']

def downloaded_ids
  FileUtils.touch('downloaded_ids')
  File.read('downloaded_ids').split("\n")
end

class Video
  attr_accessor :url, :created_at, :id, :lecture
  def initialize(url:, created_at:, id:, lecture:)
    @created_at = created_at
    @url = url
    @id = id
    @lecture = lecture
  end

  def download
    dest = "#{lecture.dir}/#{filename}"
    puts "Saving to #{dest}"

    FileUtils.mkdir_p(lecture.dir)
    Down.download(url, destination: dest)

    puts 'Saved.'

    File.write('downloaded_ids', id + "\n", mode: 'a')
  end

  def filename
    "#{created_at}_#{lecture.course.gsub(' ', '-')}_#{lecture.code}_#{id}.mp4"
  end
end

class Lecture
  attr_accessor :username, :password, :base, :department, :year, :semester, :course, :code, :ldap

  class << self
    def from_json(filename)
      json = JSON.parse(File.read(filename))
      json.map do |lecture|
        Lecture.new(
          username: lecture['username'],
          password: lecture['password'],
          base: lecture['base'],
          course: lecture['course'],
          ldap: lecture['ldap']
        )
      end
    end
  end

  def initialize(username:, password:, base:, course:, ldap:)
    @username = username
    @password = password
    @base = base
    @department, @year, @semester, @code = base.scan(%r{https://video\.ethz\.ch/lectures/(.*?)/(.*?)/(.*?)/(.*)}).first
    @course = course
    @ldap = ldap ? true : false
  end

  def missing_episodes
    @missing_episodes ||= metadata['episodes'].reject { |e| downloaded_ids.include?(e['id']) }.map do |e|
      id = e['id']
      created_at = e['createdAt'].split('T')[0]
      Video.new(id: id, url: best_video_url(id), created_at: created_at, lecture: self)
    end
  end

  def dir
    "#{DOWNLOAD_DIR}/#{department}/#{year}/#{semester}/#{course}"
  end

  private

  def cookie
    @cookie ||= (ldap? ? ldap_cookie : series_cookie)
  end

  def series_cookie
    Faraday.post(base + '.series-login.json') do |req|
      req.params['username'] = username
      req.params['password'] = password
    end.headers['set-cookie']
  end

  def ldap_cookie
    Faraday.post(ldap_url) do |req|
      req.params['j_username'] = username
      req.params['j_password'] = password
      req.params['j_validate'] = true
      req.params['_charset_'] = 'utf-8'
    end.headers['set-cookie']
  end

  def ldap_url
    "https://video.ethz.ch/lectures/#{department}/#{year}/#{semester}/j_security_check"
  end

  def metadata
    @metadata ||= JSON.parse(Faraday.get(base + '.series-metadata.json').body).to_h
  end

  def episode_videos(id)
    JSON.parse(Faraday.get('https://video.ethz.ch/.episode-video.json') do |req|
      req.params['recordId'] = id
      req.headers['cookie'] = cookie if protected?
    end.body).to_h
  end

  def episode_audios(id)
    JSON.parse(Faraday.get('https://video.ethz.ch/.episode-audio.json') do |req|
      req.params['recordId'] = id
      req.headers['cookie'] = cookie if protected?
    end.body).to_h
  end

  def best_video_url(id)
    unless episode_videos(id)['streams'].length() == 0
      episode_videos(id)['streams'][0]['sources']['mp4'].max { |a, b| a['res']['w'].to_i - b['res']['w'].to_i }['src']
    else
      episode_audios(id)['sources'][0]['src']
    end
  end

  def protected?
    username && password
  end

  def ldap?
    ldap
  end
end

def download_missing_lectures
  lectures = Lecture.from_json 'lectures.json'

  lectures.reject! { |lecture| lecture.missing_episodes.empty? }
  lectures.each do |lecture|
    puts "Found #{lecture.missing_episodes.count} new #{lecture.missing_episodes.count > 1 ? 'episodes' : 'episode'} for lecture \"#{lecture.course}\"!"

    lecture.missing_episodes.each(&:download)
  end

  puts 'No new episodes found.' if lectures.empty?
end

download_missing_lectures
