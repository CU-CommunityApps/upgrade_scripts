#!/usr/bin/env ruby

require 'rubygems'
#require 'xmlsimple'
require 'base64'
require 'prettyprint'
require "rexml/document"
include REXML

require 'java'
require 'encrypt-helper-1.0-SNAPSHOT-jar-with-dependencies.jar'

java_import 'edu.cornell.cynergy.EncryptionHelper'
java_import 'oracle.jdbc.OracleDriver'
java_import 'java.sql.DriverManager'

kfsdb = ARGV[2]
kfs_pass = ARGV[1]
kfsusername = ARGV[0]

cyndb = ARGV[5]
cyn_pass = ARGV[4]
cynusername = ARGV[3]

key = ARGV[6]
poCode = ""

@encryptionHelper = EncryptionHelper.new
@encryptionHelper.setKey(key)

def decrypt(encoded_data)
  @encryptionHelper.decrypt(encoded_data)
end

def encrypt(unencoded_data)
  data = @encryptionHelper.encrypt(unencoded_data)
end


oradriver = OracleDriver.new
DriverManager.registerDriver oradriver
conn = DriverManager.get_connection("jdbc:oracle:thin:@ldap://oid.cit.cornell.edu:389/#{kfsdb},cn=OracleContext",
                           kfsusername, kfs_pass)


conn.auto_commit = false



oradriver = OracleDriver.new
DriverManager.registerDriver oradriver
conn2 = DriverManager.get_connection("jdbc:oracle:thin:@ldap://oid.cit.cornell.edu:389/#{cyndb},cn=OracleContext",
                           cynusername, cyn_pass)


conn2.auto_commit = false

docIds = Array.new

stmt = conn2.prepare_statement("select DOC_HDR_ID from KREW_DOC_HDR_T where DOC_TYP_ID = '101261' and DOC_HDR_STAT_CD != 'I' and DOC_HDR_STAT_CD != 'E'");
#stmt = conn2.prepare_statement("select DOC_HDR_ID from KREW_DOC_HDR_T where DOC_HDR_ID = '5906627'");

rowset = stmt.executeQuery()
while (rowset.next()) do
  doc_id = rowset.getString(1)
  docIds.push(doc_id)
end
stmt.close()

docId = ""

docIds.each do |docid|
  sdocid = docid.to_s
  puts sdocid

  stmt = conn.prepare_statement("select DOC_CNTNT from KRNS_MAINT_DOC_T where doc_hdr_id = '#{sdocid}'");

  rowset = stmt.executeQuery()
  while (rowset.next()) do
    doc_cntnt = rowset.getString(1)
    decrypted_doc_contnt = decrypt(doc_cntnt)
  end
  stmt.close()


  if decrypted_doc_contnt.nil?
   next
  end
  
  #puts decrypted_doc_contnt
  decrypted_doc_contnt.gsub!("org.kuali.kfs.coa.businessobject.AccountGlobal", "edu.cornell.kfs.coa.businessobject.CuAccountGlobal")
  decrypted_doc_contnt.gsub!("edu.cornell.kfs.coa.businessobject.CuAccountGlobalDetail", "org.kuali.kfs.coa.businessobject.AccountGlobalDetail")
  

  encrypted_doc_contnt = encrypt(decrypted_doc_contnt)
   
  sql = "UPDATE KRNS_MAINT_DOC_T SET DOC_CNTNT = ? where doc_hdr_id = '#{sdocid}'"
  puts sql
  pstmt = conn.prepareStatement(sql)
  pstmt.setStringForClob(1,encrypted_doc_contnt)
  pstmt.executeUpdate()
  
  conn.commit
  pstmt.close()

end
