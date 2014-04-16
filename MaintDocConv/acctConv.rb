#!/usr/bin/env ruby

require 'rubygems'
require 'oci8'
require 'xmlsimple'
require 'base64'
require 'fast-aes'
require 'pp'
require 'prettyprint'
require "rexml/document"
include REXML


kfsdb = ARGV[2]
kfs_pass = ARGV[1]
kfsusername = ARGV[0]
cyndb = ARGV[5]
cyn_pass = ARGV[4]
cynusername = ARGV[3]
key = ARGV[6]
KEY = key.ljust(16)

def decrypt(encoded_data)
  data = Base64.decode64(encoded_data)
  aes = FastAES.new(KEY)
  
  aes.decrypt(data)
end

def encrypt(unencoded_data)
  aes = FastAES.new(KEY)

  data = aes.encrypt(unencoded_data)
  Base64.encode64(data)
 
end


conn = OCI8.new(kfsusername, kfs_pass, kfsdb)
conn2 = OCI8.new(cynusername, cyn_pass, cyndb)

docIds = Array.new

cursor2 = conn2.exec("select DOC_HDR_ID from KREW_DOC_HDR_T where DOC_TYP_ID = '1849556' and DOC_HDR_STAT_CD != 'I' and DOC_HDR_STAT_CD != 'E'")

while r2 = cursor2.fetch()
  docIds.push(r2)
end
cursor2.close()

docId = ""

docIds.each do |docid|
  sdocid = docid.to_s
  puts sdocid


cursor = conn.exec("SELECT DOC_CNTNT from KRNS_MAINT_DOC_T WHERE
                      DOC_HDR_ID = '#{sdocid}'")


r = cursor.fetch_hash()
if r.nil?
   puts "no maint doc"
   cursor.close()
   next
end

xml_in = decrypt(r['DOC_CNTNT'].read)
cursor.close()

xml_in.gsub!("><", ">zz1<")

doc_contnt = XmlSimple.xml_in(xml_in)

lbrCodeOld = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['extension'][0]['laborBenefitRateCategoryCode']
lbrCodeNew = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['extension'][0]['laborBenefitRateCategoryCode']

newICRAcct = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['indirectCostRecoveryAcctNbr']
oldICRAcct = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['indirectCostRecoveryAcctNbr']
newICRCd = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['indirectCostRcvyFinCoaCode']
oldICRCd = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['indirectCostRcvyFinCoaCode']
newaccountNumber = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['accountNumber']
oldaccountNumber = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['accountNumber']
newaccountChart = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['chartOfAccountsCode']
oldaccountChart = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['chartOfAccountsCode']

oldICRAccts = Element.new "indirectCostRecoveryAccounts"
oldICRAccts.attributes["class"] = "org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl"
newICRAccts = Element.new "indirectCostRecoveryAccounts"
newICRAccts.attributes["class"] = "org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl"


oldAcctNum = Element.new "accountNumber"
oldAcctNum.text = oldaccountNumber
newAcctNum = Element.new "accountNumber"
newAcctNum.text = newaccountNumber

oldICRAcctNum = Element.new "indirectCostRecoveryAccountNumber"
oldICRAcctNum.text = oldICRAcct
newICRAcctNum = Element.new "indirectCostRecoveryAccountNumber"
newICRAcctNum.text = newICRAcct

oldICRFCd = Element.new "indirectCostRecoveryFinCoaCode"
oldICRFCd.text = oldICRCd
newICRFCd = Element.new "indirectCostRecoveryFinCoaCode"
newICRFCd.text = newICRCd

lbrElOld = Element.new "laborBenefitRateCategoryCode"
lbrElOld.text = lbrCodeOld

lbrElNew = Element.new "laborBenefitRateCategoryCode"
lbrElNew.text = lbrCodeNew

version = Element.new "versionNumber"
version.text = "1"

lbr_done = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.Account'][0]['laborBenefitRateCategoryCode']

if !(lbr_done.nil?)
    puts "Already done"
    next
else
   puts "1st run\n"
end


doc = REXML::Document.new xml_in

XPath.each( doc, "//laborBenefitRateCategoryCode") { |element| element.text ="ZZ" }
XPath.each( doc, "//accountGuideline") { |element| element.add_element version }


  if newICRAcct.nil?
    puts "No ICR"
    newAcct = XPath.first( doc, "//newMaintainableObject/org.kuali.kfs.coa.businessobject.Account" )
    newAcct.add_element lbrElNew
    newAcct.add_element newICRAccts
  else
    newAcct = XPath.first( doc, "//newMaintainableObject/org.kuali.kfs.coa.businessobject.Account" )
    newAcct.add_element lbrElNew
    newAcct.add_element newICRAccts
    newICR = XPath.first( doc, "//org.kuali.kfs.coa.businessobject.Account/indirectCostRecoveryAccounts" )
    newICR.add_element newAcctNum
    newICR.add_element newICRAcctNum
    newICR.add_element newICRFCd
  end 

if oldICRAcct.nil?
  puts "No old ICR"
  if lbrCodeOld.nil?
    puts "No old labor benefit cat code"
  else
    oldAcct = XPath.first( doc, "//oldMaintainableObject/org.kuali.kfs.coa.businessobject.Account" )
    oldAcct.add_element lbrElOld
    oldAcct.add_element oldICRAccts
  end
else
  oldAcct = XPath.first( doc, "//oldMaintainableObject/org.kuali.kfs.coa.businessobject.Account" )
  oldAcct.add_element lbrElOld
  oldAcct.add_element oldICRAccts
  oldICR = XPath.first( doc, "//org.kuali.kfs.coa.businessobject.Account/indirectCostRecoveryAccounts" )
  oldICR.add_element oldAcctNum
  oldICR.add_element oldICRAcctNum
  oldICR.add_element oldICRFCd
end

docString = ""
doc.write(docString)

docString.gsub!("<laborBenefitRateCategoryCode>#{lbrCodeNew}</laborBenefitRateCategoryCode>", "  <laborBenefitRateCategoryCode>#{lbrCodeNew}</laborBenefitRateCategoryCode>\n")          

if lbrCodeNew.eql? lbrCodeOld 
puts "The labor ben rate codes are equal"
else
docString.gsub!("<laborBenefitRateCategoryCode>#{lbrCodeOld}</laborBenefitRateCategoryCode>", "  <laborBenefitRateCategoryCode>#{lbrCodeOld}</laborBenefitRateCategoryCode>\n")
end

docString.gsub!("<indirectCostRecoveryAccounts class='org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl'>", "  <indirectCostRecoveryAccounts class='org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl'>\n")

docString.gsub!("<indirectCostRecoveryAccounts class='org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl'/>", "<indirectCostRecoveryAccounts class='org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl'/>\n")

docString.gsub!("<accountNumber>#{newaccountNumber}</accountNumber><indirectCostRecoveryAccountNumber>#{newICRAcct}</indirectCostRecoveryAccountNumber><indirectCostRecoveryFinCoaCode>#{newICRCd}</indirectCostRecoveryFinCoaCode></indirectCostRecoveryAccounts></org.kuali.kfs.coa.businessobject.Account>", "    <org.kuali.kfs.coa.businessobject.IndirectCostRecoveryAccount>\n      <chartOfAccountsCode>#{newaccountChart}</chartOfAccountsCode>\n      <accountNumber>#{newaccountNumber}</accountNumber>\n      <indirectCostRecoveryAccountNumber>#{newICRAcct}</indirectCostRecoveryAccountNumber>\n      <indirectCostRecoveryFinCoaCode>#{newICRCd}</indirectCostRecoveryFinCoaCode>\n      <accountLinePercent>100</accountLinePercent>\n      <active>true</active>\n      <newCollectionRecord>false</newCollectionRecord>\n    </org.kuali.kfs.coa.businessobject.IndirectCostRecoveryAccount>\n  </indirectCostRecoveryAccounts>\n</org.kuali.kfs.coa.businessobject.Account>")

if ((oldaccountNumber.eql? newaccountNumber) && (oldICRAcct.eql? newICRAcct) && (oldICRCd.eql? newICRCd))
  puts "ICR values are equal"
else
docString.gsub!("<accountNumber>#{oldaccountNumber}</accountNumber><indirectCostRecoveryAccountNumber>#{oldICRAcct}</indirectCostRecoveryAccountNumber><indirectCostRecoveryFinCoaCode>#{oldICRCd}</indirectCostRecoveryFinCoaCode></indirectCostRecoveryAccounts></org.kuali.kfs.coa.businessobject.Account>", "    <org.kuali.kfs.coa.businessobject.IndirectCostRecoveryAccount>\n      <chartOfAccountsCode>#{oldaccountChart}</chartOfAccountsCode>\n      <accountNumber>#{oldaccountNumber}</accountNumber>\n      <indirectCostRecoveryAccountNumber>#{oldICRAcct}</indirectCostRecoveryAccountNumber>\n      <indirectCostRecoveryFinCoaCode>#{oldICRCd}</indirectCostRecoveryFinCoaCode>\n      <accountLinePercent>100</accountLinePercent>\n      <active>true</active>\n      <newCollectionRecord>false</newCollectionRecord>\n    </org.kuali.kfs.coa.businessobject.IndirectCostRecoveryAccount>\n  </indirectCostRecoveryAccounts>\n</org.kuali.kfs.coa.businessobject.Account>")
end

docString.gsub!(">zz1<", "><")
newDoc = encrypt(docString)
newDoc.gsub!("\n", "")


clob = OCI8::CLOB.new(conn, newDoc)


cursor = conn.parse("UPDATE KRNS_MAINT_DOC_T SET DOC_CNTNT=(:1) WHERE DOC_HDR_ID = '#{sdocid}'")
cursor.bind_param(1, clob, OCI8::CLOB, clob.size)
cursor.exec()
cursor.close()

conn.commit

end
