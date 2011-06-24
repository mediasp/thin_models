require 'lib/thin_models/version'

desc 'build a gem release and push it to dev'
task :release do
  sh 'gem build thin_models.gemspec'
  sh "scp thin_models-#{ThinModels::VERSION}.gem dev.playlouder.com:/var/www/gems.playlouder.com/pending"
  sh "ssh dev.playlouder.com sudo include_gems.sh /var/www/gems.playlouder.com/pending"
end

require 'rake/testtask'
Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/test_*.rb']
  t.verbose = true
  t.options = '--runner=specdox'
end
