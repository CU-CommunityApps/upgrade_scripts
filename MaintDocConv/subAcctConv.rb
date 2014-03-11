#!/usr/bin/env ruby

require 'rubygems'
require 'oci8'
require 'xmlsimple'
require 'base64'
require 'fast-aes'
include REXML

kfsdb = ARGV[0]
kfs_pass = ARGV[1]
cyndb = ARGV[2]
cyn_pass = ARGV[3]
key = ARGV[4]
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

conn = OCI8.new("kfs", kfs_pass, kfsdb)
conn2 = OCI8.new("cynergy", cyn_pass, cyndb)

docIds = Array.new

cursor2 = conn2.exec("select DOC_HDR_ID from KREW_DOC_HDR_T where DOC_TYP_ID = '3419899' and DOC_HDR_STAT_CD !='I' and DOC_HDR_STAT_CD !='E'")

while r2 = cursor2.fetch()
  docIds.push(r2)
end

docId = ""

docIds.each do |docid|
  sdocid = docid.to_s
  puts sdocid


cursor = conn.exec("SELECT DOC_CNTNT from KRNS_MAINT_DOC_T WHERE
                      DOC_HDR_ID = '#{sdocid}'")


r = cursor.fetch_hash()

if r.nil?
   puts "no maint doc"
   next
end
xml_in = decrypt(r['DOC_CNTNT'].read)

doc_contnt = XmlSimple.xml_in(xml_in)

xml_in.gsub!("><", ">zz1<")

newICRAcct = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['indirectCostRecoveryAccountNumber']
oldICRAcct = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['indirectCostRecoveryAccountNumber']
newICRCd = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['indirectCostRecoveryChartOfAccountsCode']
oldICRCd = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['indirectCostRecoveryChartOfAccountsCode']

newaccountChart = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['chartOfAccountsCode']
oldaccountChart = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['chartOfAccountsCode']
newaccountNumber = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['accountNumber']
oldaccountNumber = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['accountNumber']
newsubaccountNumber = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['subAccountNumber']
oldsubaccountNumber = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['subAccountNumber']
newsubaccountType = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['subAccountTypeCode']
oldsubaccountType = doc_contnt['oldMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['subAccountTypeCode']

oldICRAccts = Element.new "a21IndirectCostRecoveryAccounts"
newICRAccts = Element.new "a21IndirectCostRecoveryAccounts"

oldSubAcctNum = Element.new "subAccountNumber"
oldSubAcctNum.text = oldsubaccountNumber
newSubAcctNum = Element.new "subAccountNumber"
newSubAcctNum.text = newsubaccountNumber

oldSubAcctType = Element.new "subAccountTypeCode"
oldSubAcctType.text = oldsubaccountType
newSubAcctType = Element.new "subAccountTypeCode"
newSubAcctType.text = newsubaccountType

oldICRAcctNum = Element.new "indirectCostRecoveryAccountNumber"
oldICRAcctNum.text = oldICRAcct
newICRAcctNum = Element.new "indirectCostRecoveryAccountNumber"
newICRAcctNum.text = newICRAcct

oldICRFCd = Element.new "indirectCostRecoveryFinCoaCode"
oldICRFCd.text = oldICRCd
newICRFCd = Element.new "indirectCostRecoveryFinCoaCode"
newICRFCd.text = newICRCd

new_boA21 = Element.new "org.kuali.kfs.coa.businessobject.A21IndirectCostRecoveryAccount"
old_boA21 = Element.new "org.kuali.kfs.coa.businessobject.A21IndirectCostRecoveryAccount"

newIcr_done = doc_contnt['newMaintainableObject'][0]['org.kuali.kfs.coa.businessobject.SubAccount'][0]['a21SubAccount'][0]['a21IndirectCostRecoveryAccounts']

if !(newIcr_done.nil?)
    puts "Already done"
    next
else
   puts "1st run\n"
end

doc = REXML::Document.new xml_in


  if newICRAcct.nil?
    puts "No ICR skipping"
    next
  else
    if !(oldICRAcct.nil?)
      newICRAccts.attributes["class"] = "org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl"
    end
    newAcct = doc.root.elements[2].elements[1].elements["a21SubAccount"]
    newAcct.add_element newICRAccts
    newICR = doc.root.elements[2].elements[1].elements["a21SubAccount"].elements["a21IndirectCostRecoveryAccounts"]
    newICR.add_element newSubAcctNum
    newICR.add_element newICRAcctNum
    newICR.add_element newICRFCd
  end 

if oldICRAcct.nil?
  puts "No old ICR"
  oldAcct = doc.root.elements[1].elements[1].elements["a21SubAccount"]
  oldAcct.add_element oldICRAccts
else
  oldICRAccts.attributes["class"] = "org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl"
  oldAcct = doc.root.elements[1].elements[1].elements["a21SubAccount"]
  oldAcct.add_element oldICRAccts
  oldICR = doc.root.elements[1].elements[1].elements["a21SubAccount"].elements["a21IndirectCostRecoveryAccounts"]
  oldICR.add_element oldSubAcctNum
  oldICR.add_element oldICRAcctNum
  oldICR.add_element oldICRFCd
end

docString = ""
doc.write(docString)


docString.gsub!("org.kuali.kfs.coa.document.SubAccountMaintainableImpl", "edu.cornell.kfs.coa.document.CuSubAccountMaintainableImpl")

docString.gsub!("<a21IndirectCostRecoveryAccounts class='org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl'>", "  <a21IndirectCostRecoveryAccounts class='org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl'>\n")

docString.gsub!("<a21IndirectCostRecoveryAccounts>", "  <a21IndirectCostRecoveryAccounts>\n")


docString.gsub!("<a21IndirectCostRecoveryAccounts/></a21SubAccount>", "  <a21IndirectCostRecoveryAccounts/>\n  </a21SubAccount>")

docString.gsub!("<subAccountNumber>#{newsubaccountNumber}</subAccountNumber><indirectCostRecoveryAccountNumber>#{newICRAcct}</indirectCostRecoveryAccountNumber><indirectCostRecoveryFinCoaCode>#{newICRCd}</indirectCostRecoveryFinCoaCode></a21IndirectCostRecoveryAccounts></a21SubAccount>", "      <org.kuali.kfs.coa.businessobject.A21IndirectCostRecoveryAccount>\n        <indirectCostRecoveryAccountNumber>#{newICRAcct}</indirectCostRecoveryAccountNumber>\n        <indirectCostRecoveryFinCoaCode>#{newICRCd}</indirectCostRecoveryFinCoaCode>\n        <accountLinePercent>100</accountLinePercent>\n        <active>true</active>\n        <newCollectionRecord>true</newCollectionRecord>\n      </org.kuali.kfs.coa.businessobject.A21IndirectCostRecoveryAccount>\n    </a21IndirectCostRecoveryAccounts>\n  </a21SubAccount>")
 
if ((oldsubaccountNumber.eql? newsubaccountNumber) && (oldICRAcct.eql? newICRAcct) && (oldICRCd.eql? newICRCd))
  puts "ICR values are equal"
else
docString.gsub!("<subAccountNumber>#{oldsubaccountNumber}</subAccountNumber><indirectCostRecoveryAccountNumber>#{oldICRAcct}</indirectCostRecoveryAccountNumber><indirectCostRecoveryFinCoaCode>#{oldICRCd}</indirectCostRecoveryFinCoaCode></a21IndirectCostRecoveryAccounts></a21SubAccount>", "      <org.kuali.kfs.coa.businessobject.A21IndirectCostRecoveryAccount>\n        <indirectCostRecoveryAccountNumber>#{oldICRAcct}</indirectCostRecoveryAccountNumber>\n        <indirectCostRecoveryFinCoaCode>#{oldICRCd}</indirectCostRecoveryFinCoaCode>\n        <accountLinePercent>100</accountLinePercent>\n        <active>true</active>\n        <newCollectionRecord>true</newCollectionRecord>\n      </org.kuali.kfs.coa.businessobject.A21IndirectCostRecoveryAccount>\n    </a21IndirectCostRecoveryAccounts>\n  </a21SubAccount>")
end

docString.gsub!(">zz1<", "><")

first, *rest = docString.split("</maintainableDocumentContents>")
first.concat("</maintainableDocumentContents>")
docString = first

file2 = File.open("xml_out.xml", "w")
file2.write(docString)
file2.close

newDoc = `/eig/sys/software/java/jdk1.7.0_51/jre/bin/java -cp encrypt-helper-1.0-SNAPSHOT-jar-with-dependencies.jar edu.cornell.cynergy.MainApp xml_out.xml genico4e`
newDoc.gsub!("\n", "")

clob = OCI8::CLOB.new(conn, newDoc)

cursor = conn.parse("UPDATE KRNS_MAINT_DOC_T SET DOC_CNTNT=(:1) WHERE DOC_HDR_ID = '#{sdocid}'")
cursor.bind_param(1, clob, OCI8::CLOB, clob.size)
cursor.exec()
cursor.close()

conn.commit

end