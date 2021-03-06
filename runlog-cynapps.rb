#!/usr/bin/env ruby

instance = ARGV.shift
user = ARGV.shift
password = ARGV.shift

CURRENT_DIR = Dir.pwd

CLASSPATH = "--classpath=#{CURRENT_DIR}/lib/ojdbc6-11.2.0.3.jar"

DBURL = "--url=jdbc:oracle:thin:@ldap://oidmaster1.cit.cornell.edu:389/#{instance},cn=oraclecontext"
USER = "--username=#{user}"
PASS = "--password=#{password}"

LIQUIBASE_1_9_5_CMD = "java -jar #{CURRENT_DIR}/lib/liquibase-1.9.5.jar --logLevel=info #{CLASSPATH} --driver=oracle.jdbc.OracleDriver #{DBURL} #{USER} #{PASS} --changeLogFile=LOGFILE update"
LIQUIBASE_2_0_5_CMD = "java -jar #{CURRENT_DIR}/lib/liquibase-2.0.5.jar --logLevel=info #{CLASSPATH} --driver=oracle.jdbc.OracleDriver #{DBURL} #{USER} #{PASS} --changeLogFile=LOGFILE update"
LIQUIBASE_3_0_2_CMD = "java -jar #{CURRENT_DIR}/lib/liquibase-3.0.2.jar --logLevel=info #{CLASSPATH} --driver=oracle.jdbc.OracleDriver #{DBURL} #{USER} #{PASS} --changeLogFile=LOGFILE update"

custom_changelogs = ['all_to_224_update_client_final_oracle.xml']

# folders in the correct order
folders = [ 
            {:name => "custom/cynapps", :version => 3, :changelogs => custom_changelogs },
          ]
          
folders.each do |folder|
  lb_cmd = folder[:version] == 1 ? LIQUIBASE_1_9_5_CMD : folder[:version] == 2 ? LIQUIBASE_2_0_5_CMD : LIQUIBASE_3_0_2_CMD
  Dir.chdir(folder[:name]) do
    puts  "*" * 25 + "\n"
    puts "working in #{Dir.pwd}\n\n"
    folder[:changelogs].each do |changelog|
      puts "Running changelog #{Dir.pwd}/#{changelog}"
      puts `#{lb_cmd.gsub("LOGFILE", changelog)}`
      puts "\n"
    end
    puts  "*" * 25 + "\n"
    puts "\n\n"
  end
end
