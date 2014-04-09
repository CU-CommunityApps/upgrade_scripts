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

rice_changelogs = ['rice_server/parameter_updates.xml',
                   'rice_server/kim_upgrade.xml',
                   'rice_server/kew_upgrade.xml']

custom_changelogs = ['krim_rsp_t_update.xml',
                     'krim_ext_id_typ_t_no_encrypyt.xml',
                     'gl-module-customizations.xml',
                     'krcr_parm_t_update.xml',
                     'krim_perm_t_update.xml',
                     'krim_role_t_update.xml',
                     'krim_role_permt_t_update.xml',
                     'parm_routing_update.xml',
                     'reindex_docs.xml',
                     'clear_ksb.xml',
                     'krlc_cntry_t_update.xml',
                     'krim_dlgn_t.xml',
                     'krcr_cmpnt_t_update.xml',
                     'krim_role_mbr_attr_data_t.xml',
                     'krim_role_rsp_t_update.xml',
                     'krim_role_mbr_t.xml',
                     'cynapps_namespaces.xml']

# folders in the correct order
folders = [ {:name => "kfs/3.0.1_4.0", :version => 1, :changelogs => ['rice/kns_upgrade.xml', 
                                                                      'rice/kns_parm_upgrade.xml', 
                                                                      'rice/kns_endow_upgrade.xml', 
                                                                      'rice/kim_upgrade.xml', 
                                                                      'rice/kim_endow_upgrade.xml'] }, 
            {:name => "kfs/4.0_4.1", :version => 1, :changelogs => ['rice/kns_upgrade.xml', 
                                                                    'rice/kns_security_module.xml', 
                                                                    'rice/kim_upgrade_optional.xml', 
                                                                    'rice/kim_upgrade.xml'] }, 
            {:name => "kfs/4.1_4.1.1", :version => 1, :changelogs => ['rice/kns_upgrade.xml'] },
            {:name => "rice", :version => 3, :changelogs => [
                                                             '1011_to_102_update_final_oracle.xml', 
                                                             '102_to_103_update_final_oracle.xml',
                                                             '1031_to_1032_update_final_oracle.xml',
                                                             '103_to_200_perm_resp_upgrade.xml',
                                                             '103_to_200_update_final_oracle.xml',
                                                             '103_to_200_cleanup.xml',
                                                             '200_to_210_update_final_oracle.xml',
                                                             '210_to_212_update_final_oracle.xml',
                                                             '212_to_213_update_final_oracle.xml',
                                                             '213_to_221_update_final_oracle.xml',
                                                             '221_to_222_update_final_oracle.xml',
                                                             '221_to_222_cleanup_final_oracle.xml',
                                                             '223_to_224_update_final_oracle.xml',
                                                             '22x_to_230_update_final_oracle.xml',
                                                             '230_to_231_update_final_oracle.xml'
                                                             ]},
            
            {:name => "kfs/4.1.1_5.0", :version => 2, :changelogs => ['rice_server/parameter_updates.xml',
                                                                      'rice_server/kim_upgrade.xml',
                                                                      'rice_server/kew_upgrade.xml'] },
            {:name => "kfs/5.0_5.0.1", :version => 2, :changelogs => rice_changelogs},
            {:name => "kfs/5.0.1_5.0.2", :version => 2, :changelogs => rice_changelogs },
            {:name => "kfs/5.0.2_5.0.3", :version => 2, :changelogs => rice_changelogs },
            {:name => "kfs/5.0.3_5.0.4", :version => 2, :changelogs => rice_changelogs },
            {:name => "kfs/5.0.4_5.0.5", :version => 2, :changelogs => rice_changelogs },
            {:name => "kfs/5.0.5_5.1", :version => 2, :changelogs => rice_changelogs },
            {:name => "kfs/5.1_5.1.1", :version => 2, :changelogs => rice_changelogs },
            {:name => "custom/rice", :version => 3, :changelogs => custom_changelogs },
            {:name => "custom/rice/access_security", :version => 3, :changelogs => ['access-security-customizations.xml'] },
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
