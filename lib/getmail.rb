require 'logger'
require 'rubygems'
require 'lockfile'
require 'yaml'

CONFIG_FILE = File.join(ENV['HOME'], '.getmail',  'getmailrb')
LOG_DIR = '/var/log/getmail'
LOG_FILE = 'getmail.log'
LOG_PATH = File.join(LOG_DIR, LOG_FILE)
#STOP_FILE = '/home/vmail/do_not_run_getmail'
GETMAIL_PATH = '/usr/bin/getmail'
#RCFILES = %w(bobnickyadslrc bobthegreenshrc)
#RCFILES = %w(bobnickyadslrc bobthegreenshrc nickythegreenshrc brynthegreenshrc lucathegreenshrc vickythegreenshrc)
#LOCK_FILE = '/home/vmail/.getmail/getmail.lock'

#logger = Logger.new('/var/log/getmail/getmail.log', 5, 1024000)
@logger = Logger.new(LOG_PATH, 5, 1024000)
@logger.level = Logger::DEBUG

def config_loaded
	res = false
	if File.exist? CONFIG_FILE
		begin
			@logger.debug "loading config file from #{CONFIG_FILE}"
			@config = YAML.load_file CONFIG_FILE
			res = true
		rescue Exception => e
			@logger.fatal e.message
			@logger.error e.backtrace
		end # rescue
	else
		@logger.fatal "could not find @config file #{@config_FILE}"
	end # if
	res
end # def

def mounts_ok
	res = true
	if @config.has_key?(:reqd_mount)
		if Regexp.new(@config[:reqd_mount]).match(`mount`)
			@logger.debug "mount #{@config[:reqd_mount]} found"
		else
			res = false
			@logger.fatal "mount #{@config[:reqd_mount]} could not be found"
		end
	end
	res
end

def getmail_call
  GETMAIL_PATH + @rcfiles.inject("") { |p, file| "#{p} --rcfile=#{file}"}
end

#return unless config_loaded
#return unless mounts_ok

if config_loaded and mounts_ok
	@rcfiles = @config[:rcfiles]
	@stop_file = @config[:stop_file]
	@lock_file = @config[:lock_file]

	if File.exist? @stop_file
		@logger.info { "Stop file found, mail will NOT be checked" }
	else
		
		begin
			Lockfile.new(@lock_file, :retries => 0) do
					@logger.info { "Checking email" }
					@logger.debug { "calling #{getmail_call}" }
					res = `#{getmail_call}`
					if $?.to_i == 0
						@logger.info { res }
					else
						@logger. error { res }
					end
			end # Lockfile... do
		rescue Lockfile::MaxTriesLockError => e
			@logger.info { "Another process is accessing the mailbox" }
		end # rescue block

	end # if File.exist
end # if config_load...
