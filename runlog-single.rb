#!/usr/bin/env ruby

instance = ARGV.shift
user = ARGV.shift
password = ARGV.shift
changelog_path = ARGV.shift
version = ARGV.shift
folder = changelog_path.slice(0, changelog_path.rindex('/'))
changelog = changelog_path.slice(changelog_path.rindex('/') + 1, changelog_path.length)

CURRENT_DIR = Dir.pwd

CLASSPATH = "--classpath=#{CURRENT_DIR}/lib/ojdbc6-11.2.0.3.jar"

DBURL = "--url=jdbc:oracle:thin:@ldap://oidmaster1.cit.cornell.edu:389/#{instance},cn=oraclecontext"
USER = "--username=#{user}"
PASS = "--password=#{password}"

LIQUIBASE_CMD  = "java -jar #{CURRENT_DIR}/lib/LIQUIBASE_CMD --logLevel=info #{CLASSPATH} --driver=oracle.jdbc.OracleDriver #{DBURL} #{USER} #{PASS} --changeLogFile=LOGFILE update"
LIQUIBASE_1_9_5_CMD = LIQUIBASE_CMD.sub("LIQUIBASE_CMD", "liquibase-1.9.5.jar")
LIQUIBASE_2_0_5_CMD = LIQUIBASE_CMD.sub("LIQUIBASE_CMD", "liquibase-2.0.5.jar")
LIQUIBASE_3_0_2_CMD = LIQUIBASE_CMD.sub("LIQUIBASE_CMD", "liquibase-3.0.2.jar")
                  
lb_cmd = version == 1 ? LIQUIBASE_1_9_5_CMD : version == 2 ? LIQUIBASE_2_0_5_CMD : LIQUIBASE_3_0_2_CMD
Dir.chdir(folder) do
  puts  "*" * 25 + "\n"
  puts "working in #{Dir.pwd}\n\n"

  puts "Running changelog #{Dir.pwd}/#{changelog}"
  puts `#{lb_cmd.sub("LOGFILE", changelog)}`
  puts "\n"

  puts  "*" * 25 + "\n"
  puts "\n\n"
end

