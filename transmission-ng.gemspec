Gem::Specification.new do |s|
  s.name        = 'transmission-ng'
  s.version     = '1.0.8'
  s.date        = '2016-06-11'
  s.summary     = "Transmission API gem"
  s.description = "A better API interface for the Transmission torrent client"
  s.authors     = ["m4rkw"]
  s.email       = 'm@rkw.io'
  s.files       = ["lib/transmission.rb"]
  s.homepage    = 'https://github.com/m4rkw/transmission-ng'
  s.license     = 'MIT'
  s.add_runtime_dependency "mechanize", ["~> 2.7"]
end
