require 'tmpdir'

extension = File.expand_path(ARGV.fetch(0))
abi = File.basename(extension)[/sqlite3_(\d+)\./, 1]
running = RUBY_VERSION.split('.')[0..1].join
abort "#{extension} is for Ruby #{abi}, running #{RUBY_VERSION}" unless abi == running

require extension
abort 'binary defined SpeckleConnector' if defined?(::SpeckleConnector)

Dir.mktmpdir do |dir|
  path = File.join(dir, 'smoke.db')
  File.write(path, '')
  db = SpeckleConnector3::Sqlite3::Database.new(path)
  abort 'objects exists before CREATE' if db.table_exist?('objects')
  db.exec('CREATE TABLE objects (hash TEXT PRIMARY KEY NOT NULL, content TEXT NOT NULL);')
  db.exec("INSERT INTO objects VALUES ('id', 'payload');")
  rows = db.exec('SELECT * FROM objects;')
  abort 'objects missing after CREATE' unless db.table_exist?('objects')
  abort "unexpected rows #{rows.inspect}" unless rows == [%w[id payload]]
  db.close
end

puts "ok #{File.basename(extension)} ruby=#{RUBY_VERSION} #{RUBY_PLATFORM} " \
     "built_for=#{SpeckleConnector3::Sqlite3.ruby_platform}"
