set :deploy_lock_file, -> { File.join(shared_path, 'deploy-lock.yml') }
set :deploy_lock_roles, -> { :app }
set :default_lock_expiry, (15 * 60)
set :deploy_lock, false
set :lock_message, nil
set :lock_expiry, nil
set :enable_deploy_lock_local, true
set :local_lock_path, '.' # working directory
set :deploy_lock_file_local, -> { File.join(fetch(:local_lock_path), "#{fetch(:rails_env)}-#{fetch(:stage)}-deploy-lock.yml") }

namespace :deploy do

  desc 'Deploy with a custom deploy lock'
  task :with_lock do
    invoke 'deploy:lock'
    invoke 'deploy'
  end

  desc 'Set deploy lock with a custom lock message and expiry time'
  task :lock do
    set :custom_deploy_lock, true
    set :lock_message, ask('lock message', '', echo: true)
    puts "Lock message: #{fetch(:lock_message)}"

    while fetch(:lock_expiry).nil?
      set :expire_after, ask('minutes of expiry', 'optional', echo: true)
      expire_after = fetch(:expire_after)

      if expire_after == 'optional'
        # Never expire an explicit lock if no time given
        set :lock_expiry, false
        puts colorize('Lock will never expire automatically.', color: 33)
      else
        unless expire_after.to_i == 0
          set :lock_expiry, (Time.now + expire_after.to_i * 60).utc
          puts colorize("Expire after #{fetch(:expire_after)} minutes", color: 33)
        else
          puts colorize("'#{expire_after}' is not valid input. Please try again.")
        end
      end
    end

    invoke 'deploy:create_lock'
  end

  desc 'Creates a lock file, so that futher deploys will be prevented'
  task :create_lock do
    if fetch(:deploy_lock)
      puts colorize('Deploy lock already created.', color: 33)
      next
    end

    if fetch(:lock_message).nil?
      if fetch(:enable_deploy_lock_local)
        set :lock_message, "Deploying #{fetch(:branch)} branch in #{fetch(:rails_env)} and on local"
      else
        set :lock_message, "Deploying #{fetch(:branch)} branch in #{fetch(:rails_env)}"
      end
    end

    if fetch(:lock_expiry).nil?
      set :lock_expiry, (Time.now + fetch(:default_lock_expiry)).utc
    end

    deploy_lock_data = {
      created_at: Time.now.utc,
      username: ENV['USER'],
      expire_at: fetch(:lock_expiry),
      message: fetch(:lock_message).to_s,
      custom: !!fetch(:custom_deploy_lock)
    }

    write_deploy_lock(deploy_lock_data)

    set :deploy_lock, deploy_lock_data
  end

  desc 'Checks for a deploy lock. If present, deploy is aborted and message is displayed. Any expired locks are deleted.'
  task :check_lock do
    # Don't check the lock if we just created it
    next if fetch(:deploy_lock)

    fetch_deploy_lock

    # Return if no lock
    next unless fetch(:deploy_lock)

    deploy_lock = fetch(:deploy_lock)

    if deploy_lock[:expire_at] && deploy_lock[:expire_at] < Time.now
      remove_deploy_lock
      next
    end

    # Check if lock is a custom lock
    set :custom_deploy_lock, deploy_lock[:custom]

    # Unexpired lock is present, so display the lock message
    puts message(fetch(:application), fetch(:stage), deploy_lock)

    # Don't raise exception if current user owns the lock, and lock has an expiry time.
    # Just sleep for a few seconds so they have a chance to cancel the deploy with Ctrl-C
    if deploy_lock[:expire_at] && deploy_lock[:username] == ENV['USER']
      10.downto(1) do |i|
        Kernel.print "\r\e[0;33mDeploy lock was created by you (#{ENV['USER']}). Continuing deploy in #{i}...\e[0m"
        sleep 1
      end
      puts
    else
      exit 1
    end
  end

  namespace :unlock do
    desc 'Unlocks the server for deployment'
    task :default do
      # Don't automatically remove custom deploy locks created by deploy:lock task
      if fetch(:custom_deploy_lock)
        puts colorize('Not removing custom deploy lock.', color: 33)
      else
        remove_deploy_lock
        puts colorize('Deploy unlocked.', color: 32)
      end
    end

    task :force do
      remove_deploy_lock
      puts colorize('Deploy unlocked.', color: 32)
    end
  end

  before 'deploy:started', 'check_lock'
  before 'deploy:started', 'create_lock'
  after 'deploy:published', 'unlock:default'
  after 'deploy:rollback', 'unlock:default'
  after 'deploy:failed', 'unlock:default'

end

# Fetch the deploy lock unless already cached
def fetch_deploy_lock
  # Return if we know that the deploy lock has just been removed
  return if fetch(:deploy_lock_removed)

  unless fetch(:deploy_lock)
    # Check all matching servers for a deploy lock.
    on roles(fetch(:deploy_lock_roles)), in: :parallel do |host|
      if test("[ -f #{fetch(:deploy_lock_file)} ]")
        output = capture "cat #{fetch(:deploy_lock_file)}"
        set :deploy_lock, YAML.load(output)
      else
        # no deploy lock was found on server
        next
      end
    end
  end
end

def write_deploy_lock(deploy_lock)
  on roles(fetch(:deploy_lock_roles)), in: :parallel do |host|
    upload! StringIO.new(deploy_lock.to_yaml), fetch(:deploy_lock_file)
  end

  if fetch(:enable_deploy_lock_local)
    Dir.mkdir(shared_path)
    File.write(fetch(:deploy_lock_file_local), deploy_lock.to_yaml)
  end
end

def remove_deploy_lock
  on roles(fetch(:deploy_lock_roles)), in: :parallel do |host|
    execute :rm, '-f', fetch(:deploy_lock_file)
  end
  File.delete(fetch(:deploy_lock_file_local)) if File.exist?(fetch(:deploy_lock_file_local))

  set :deploy_lock, nil
  set :deploy_lock_removed, true
end

def message(application, stage, deploy_lock)
  message = "#{application} (#{stage}) was locked"
  message << " at #{deploy_lock[:created_at].localtime.strftime("%c %Z")}"
  message << " by '#{deploy_lock[:username]}'\nMessage: #{deploy_lock[:message]}"

  if deploy_lock[:expire_at]
    message << "\n\e[0;33mLock expires at #{deploy_lock[:expire_at].localtime.strftime("%H:%M:%S")}\e[0m"
  else
    message << "\n\e[0;33mLock must be manually removed with: cap #{stage} deploy:unlock\e[0m"
  end

  colorize(message)
end

def colorize(text, options = {})
  attribute = options[:attribute] || 0
  color = options[:color] || 31
  "\e[#{attribute};#{color}m" + text.strip + "\e[0m\n"
end
