#!/usr/bin/env ruby

require 'rubygems'
require 'base64'
require 'prettyprint'

require 'java'
require 'encrypt-helper-1.0-SNAPSHOT-jar-with-dependencies.jar'

java_import 'edu.cornell.cynergy.EncryptionHelper'
java_import 'oracle.jdbc.OracleDriver'
java_import 'java.sql.DriverManager'

kfsdb = ARGV[0]
kfsusername = ARGV[1]
kfs_pass = ARGV[2]

key = ARGV[3]

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

vendor_hdr_ids = Array.new


stmt = conn.prepare_statement("select VNDR_HDR_GNRTD_ID, VNDR_FOREIGN_TAX_ID from PUR_VNDR_HDR_T where VNDR_FOREIGN_TAX_ID is not null")

rowset = stmt.executeQuery()
while (rowset.next()) do
  vendor_hdr_id = rowset.getString(1)
  vendor_hdr_ids.push(vendor_hdr_id)
  vendor_foreign_tax_id = rowset.getString(2)
end
stmt.close()

vendorHdrId = ""

vendor_hdr_ids.each do |vendorhdrid|
  svendorhdrid = vendorhdrid.to_s


encrypted_vendor_foreign_tax_id = encrypt(vendor_foreign_tax_id)

sql = "UPDATE PUR_VNDR_HDR_T SET VNDR_FOREIGN_TAX_ID = ? where VNDR_HDR_GNRTD_ID = '#{svendorhdrid}'"
puts sql
pstmt = conn.prepareStatement(sql)
pstmt.setStringForClob(1,encrypted_vendor_foreign_tax_id )
pstmt.executeUpdate()

conn.commit
pstmt.close()

end
