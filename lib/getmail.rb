require 'logger'
require 'rubygems'
require 'lockfile'

LOG_DIR = '/var/log/getmail'
LOG_FILE = 'getmail.log'
STOP_FILE = '/home/vmail/do_not_run_getmail'
GETMAIL_PATH = '/usr/bin/getmail'
#RCFILES = %w(bobnickyadslrc bobthegreenshrc)
RCFILES = %w(bobnickyadslrc bobthegreenshrc nickythegreenshrc brynthegreenshrc lucathegreenshrc vickythegreenshrc)
LOCK_FILE = '/home/vmail/.getmail/getmail.lock'

def log_path
  File.join(LOG_DIR, LOG_FILE)
end

def getmail_call
  GETMAIL_PATH + RCFILES.inject("") { |p, file| "#{p} --rcfile=#{file}"}
end

#logger = Logger.new('/var/log/getmail/getmail.log', 5, 1024000)
logger = Logger.new(log_path, 5, 1024000)
logger.level = Logger::DEBUG

if File.exist? STOP_FILE
  logger.debug { "Stop file found, mail will NOT be checked" }
else
  begin
    Lockfile.new(LOCK_FILE, :retries => 0) do
      logger.info { "Checking email" }
      logger.debug { "calling #{getmail_call}" }
      res = `#{getmail_call}`
      if $?.to_i == 0
        logger.info { res }
      else
        logger. error { res }
      end
    end
  rescue Lockfile::MaxTriesLockError => e
    logger.info { "Another fetcher is running" }
  end
end
