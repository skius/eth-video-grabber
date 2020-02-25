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
  attr_accessor :url, :created_at, :id
  def initialize(url:, created_at:, id:)
    @created_at = created_at
    @url = url
    @id = id
  end
end

class Lecture
  attr_accessor :username, :password, :base, :department, :year, :semester, :course, :code

  class << self
    def from_json(filename)
      json = JSON.parse(File.read(filename))
      json.map do |lecture|
        Lecture.new(
          username: lecture['username'],
          password: lecture['password'],
          base: lecture['base'],
          course: lecture['course']
        )
      end
    end
  end

  def initialize(username:, password:, base:, course:)
    @username = username
    @password = password
    @base = base
    @department, @year, @semester, @code = base.scan(%r{https://video\.ethz\.ch/lectures/(.*?)/(.*?)/(.*?)/(.*)}).first
    @course = course
  end

  def missing_episodes
    @missing_episodes ||= metadata['episodes'].reject { |e| downloaded_ids.include?(e['id']) }.map do |e|
      id = e['id']
      Video.new(id: id, url: best_video_url(id), created_at: e['createdAt'].split('T')[0])
    end
  end

  private

  def cookie
    @cookie ||= Faraday.post(base + '.series-login.json') do |req|
      req.params['username'] = username
      req.params['password'] = password
    end.headers['set-cookie']
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

  def best_video_url(id)
    episode_videos(id)['streams'][0]['sources']['mp4'].max { |a, b| a['res']['w'].to_i - b['res']['w'].to_i }['src']
  end

  def protected?
    username && password
  end
end

def download_missing_lectures
  lectures = Lecture.from_json 'lectures.json'

  lectures.reject { |lecture| lecture.missing_episodes.empty? }.each do |lecture|
    puts "Found #{lecture.missing_episodes.count} new #{lecture.missing_episodes.count > 1 ? 'episodes' : 'episode'} for lecture \"#{lecture.course}\"!"

    lecture.missing_episodes.each do |video|
      dest = "#{DOWNLOAD_DIR}/#{lecture.department}/#{lecture.year}/#{lecture.semester}/#{lecture.course}"
      filename = "#{video.created_at}_#{lecture.course.gsub(' ', '-')}_#{lecture.code}_#{video.id}.mp4"
      puts "Saving to #{dest}/#{filename}"

      FileUtils.mkdir_p(dest)
      Down.download(video.url, destination: "#{dest}/#{filename}")

      puts 'Saved.'

      File.write('downloaded_ids', video.id + "\n", mode: 'a')
    end
  end
end

download_missing_lectures
