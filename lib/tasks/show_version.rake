desc "Show the current version of migration"
task :show_version => :environment do
  puts ActiveRecord::Migrator.current_version
end
