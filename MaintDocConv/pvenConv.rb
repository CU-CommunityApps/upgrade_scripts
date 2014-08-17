#!/usr/bin/env ruby

require 'rubygems'
require 'xmlsimple'
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

stmt = conn.prepare_statement('select DOC_CNTNT from KRNS_MAINT_DOC_T where doc_hdr_id = 5688174');

rowset = stmt.executeQuery()
while (rowset.next()) do
  doc_cntnt = rowset.getString(1)
  decrypted_doc_contnt = decrypt(doc_cntnt)
end

puts decrypted_doc_contnt
encrypted_doc_contnt = encrypt(decrypted_doc_contnt)

sql = "UPDATE KRNS_MAINT_DOC_T SET DOC_CNTNT = ? where doc_hdr_id = 5688174"
puts sql
pstmt = conn.prepareStatement(sql)
pstmt.setStringForClob(1,encrypted_doc_contnt)
pstmt.executeUpdate()




