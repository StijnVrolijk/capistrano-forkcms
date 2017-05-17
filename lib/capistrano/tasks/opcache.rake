namespace :forkcms do
  namespace :opcache do
    desc <<-DESC
      Reset the opcache
    DESC
    task :reset do
      if fetch(:opcache_reset_strategy) === "file"
        invoke "forkcms:opcache:reset_with_file"
      elsif fetch(:opcache_reset_strategy) === "fcgi"
        invoke "forkcms:opcache:reset_with_fcgi"
      else
        raise "Invalid value for :opcache_reset_strategy, possible values are: file, fcgi."
      end
    end

    task :reset_with_file do
      # make sure that we have all needed variables
      raise "opcache_reset_base_url not set" unless fetch(:opcache_reset_base_url)

      on roles(:web) do
        stream = StringIO.new("<?php clearstatcache(true); if (function_exists('opcache_reset')) { opcache_reset(); }")
        upload! stream, "#{current_path}/php-opcache-reset.php"
        execute :curl, "-L --fail --silent --show-error", "#{fetch :opcache_reset_base_url}/php-opcache-reset.php"
        execute :rm, "#{current_path}/php-opcache-reset.php"
      end
    end

    task :reset_with_fcgi do
      # make sure that we have all needed variables
      raise "opcache_reset_fcgi_connection_string not set" unless fetch(:opcache_reset_fcgi_connection_string)

      invoke "cachetool:run", "opcache:reset", "--fcgi=#{fetch :opcache_reset_fcgi_connection_string}"

      # reenable our command, see https://github.com/capistrano/capistrano/issues/1686 for more information
      Rake::Task["cachetool:run"].reenable

      invoke "cachetool:run", "stat:clear", "--fcgi=#{fetch :opcache_reset_fcgi_connection_string}"
    end
  end
end
