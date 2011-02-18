require 'lib/lazy_data/version'

desc 'build a gem release and push it to dev'
task :release do
  sh 'gem build lazy-data.gemspec'
  sh "scp lazy-data-#{LazyData::VERSION}.gem dev.playlouder.com:/var/www/gems.playlouder.com/pending"
  sh "ssh dev.playlouder.com sudo include_gems.sh /var/www/gems.playlouder.com/pending"
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
  t.options = '--runner=specdox'
end
