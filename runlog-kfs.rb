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

#liqiubase changelogs to process in each folder
kfs_changelogs = [ 'db/master-structure-script.xml', 'db/master-data-script.xml', 'db/master-constraint-script.xml']
kfs_changelogs_with_rice_client = [ 'db/master-structure-script.xml', 'db/master-data-script.xml', 'db/master-constraint-script.xml', 'db/rice-client-script.xml']

## folders in the correct order
folders = [ {:name => "kfs/3.0.1_4.0", :version => 1, :changelogs => kfs_changelogs }, 
            {:name => "kfs/4.0_4.1", :version => 1, :changelogs => kfs_changelogs }, 
            {:name => "kfs/4.1_4.1.1", :version => 1, :changelogs => kfs_changelogs }, 
            {:name => "kfs/4.1.1_5.0", :version => 2, :changelogs => kfs_changelogs }, 
            {:name => "kfs/5.0_5.0.1", :version => 2, :changelogs => kfs_changelogs_with_rice_client }, 
            {:name => "kfs/5.0.1_5.0.2", :version => 2, :changelogs => kfs_changelogs_with_rice_client },
            {:name => "kfs/5.0.2_5.0.3", :version => 2, :changelogs => kfs_changelogs_with_rice_client },
            {:name => "kfs/5.0.3_5.0.4", :version => 2, :changelogs => kfs_changelogs_with_rice_client }, 
            {:name => "kfs/5.0.4_5.0.5", :version => 2, :changelogs => kfs_changelogs_with_rice_client }, 
            {:name => "kfs/5.0.5_5.1", :version => 2, :changelogs => kfs_changelogs_with_rice_client },   
            {:name => "kfs/5.1_5.1.1", :version => 2, :changelogs => kfs_changelogs_with_rice_client },
            {:name => "kfs/5.1.1_5.1.2", :version => 2, :changelogs => kfs_changelogs_with_rice_client },
            {:name => "kfs/5.1.2_5.2", :version => 2, :changelogs => kfs_changelogs_with_rice_client },  
            {:name => "kfs/5.2_5.2.1", :version => 2, :changelogs => kfs_changelogs_with_rice_client },  
            {:name => "kfs/5.2.1_5.2.2", :version => 2, :changelogs => kfs_changelogs_with_rice_client }, 
            {:name => "kfs/5.2_5.3", :version => 2, :changelogs => kfs_changelogs_with_rice_client }, 
            {:name => "custom/kfs/coa", :version => 3, :changelogs => ['code_cleanup.xml', 'higher_ed.xml'] },
            {:name => "custom/kfs/cam", :version => 3, :changelogs => ['tag_number.xml', 'asset_payment_doc_type.xml'] },
            {:name => "custom/kfs/ld", :version => 3, :changelogs => ['ld-module-customizations.xml'] },
            {:name => "custom/kfs/access_security", :version => 3, :changelogs => ['access-security-customizations.xml'] },
            {:name => "custom/kfs/vnd", :version => 3, :changelogs => ['vendor_extension.xml', 'delete_vendor_type.xml', 'chapter4_status_code.xml'] },
            {:name => "custom/kfs/fp", :version => 3, :changelogs => ['capital_asset_conversion.xml'] },
            {:name => "custom/kfs/purap", :version => 3, :changelogs => ['app_doc_status.xml', 'app_pmt_rqst_itm_tx.xml', 'purap_po_v.xml', 'delete_item_type.xml'] },
            {:name => "custom/kfs/gl", :version => 3, :changelogs => ['iaa-offset-defn.xml'] },
            {:name => "custom/kfs/purap", :version => 3, :changelogs => ['fs_doc_header_t_update.xml'] },
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
