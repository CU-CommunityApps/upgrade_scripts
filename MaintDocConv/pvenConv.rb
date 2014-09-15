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

stmt = conn2.prepare_statement("select DOC_HDR_ID from KREW_DOC_HDR_T where DOC_TYP_ID = '101109' and DOC_HDR_STAT_CD != 'I' and DOC_HDR_STAT_CD != 'E'");
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


decrypted_doc_contnt.gsub!("org.kuali.kfs.vnd.document.VendorMaintainableImpl", "edu.cornell.kfs.vnd.document.CuVendorMaintainableImpl")
decrypted_doc_contnt.gsub!("<oldMaintainableObject>", "<org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl></org.apache.ojb.broker.core.proxy.ListProxyDefaultImpl><oldMaintainableObject>")
decrypted_doc_contnt.gsub!("org.kuali.kfs.vnd.businessobject.VendorCreditCardMerchant", "edu.cornell.kfs.vnd.businessobject.CuVendorCreditCardMerchant")


doc = REXML::Document.new decrypted_doc_contnt



vendorAddresses = Array.new
poCodeEls = Array.new
genIds = Array.new
adVNums = Array.new
adObjIds = Array.new
adNewCols = Array.new
i =0


XPath.each( doc, "//org.kuali.kfs.vnd.businessobject.VendorAddress") { |element|
i += 1

if element.elements["extension"].nil?
	vendorAddresses[i] = Element.new "extension"
	vendorAddresses[i].attributes["class"] = "edu.cornell.kfs.vnd.businessobject.CuVendorAddressExtension"

	poCodeEls[i] = Element.new "purchaseOrderTransmissionMethodCode"
	genIds[i] = Element.new "vendorAddressGeneratedIdentifier"
	adVNums[i] = Element.new "versionNumber"
	adNewCols[i] = Element.new "newCollectionRecord"

	if !element.elements["vendorAddressGeneratedIdentifier"].nil?
		if !element.elements["vendorAddressGeneratedIdentifier"].text.nil?
			genIds[i].text = element.elements["vendorAddressGeneratedIdentifier"].text
			vendorAddresses[i].add_element genIds[i]
		end
	end
	if !element.elements["versionNumber"].nil?
		if !element.elements["versionNumber"].text.nil?
			adVNums[i].text = "1"
			vendorAddresses[i].add_element adVNums[i]
		end
	end
	if !element.elements["newCollectionRecord"].nil?
		if !element.elements["newCollectionRecord"].text.nil?	
			adNewCols[i].text = element.elements["newCollectionRecord"].text
			vendorAddresses[i].add_element adNewCols[i]
		end
	end

	if element.elements["purchaseOrderTransmissionMethodCode"].nil?
	else
		vendorAddresses[i].add_element poCodeEls[i]
		poCodeEls[i].text = element.elements["purchaseOrderTransmissionMethodCode"].text
		element.delete_element element.elements["purchaseOrderTransmissionMethodCode"]
	end
	element.add_element vendorAddresses[i]

end


}


i = 0
vendSuppliers = Array.new
expDates = Array.new
divCodes = Array.new
supVNums = Array.new
supNewCols = Array.new




XPath.each( doc, "//org.kuali.kfs.vnd.businessobject.VendorSupplierDiversity") { |element|
i += 1

if element.elements["extension"].nil?
	vendSuppliers[i] = Element.new "extension"
	vendSuppliers[i].attributes["class"] = "edu.cornell.kfs.vnd.businessobject.CuVendorSupplierDiversityExtension"

	expDates[i] = Element.new "vendorSupplierDiversityExpirationDate"
	divCodes[i] = Element.new "vendorSupplierDiversityCode"
	supVNums[i] = Element.new "versionNumber"
	supNewCols[i] = Element.new "newCollectionRecord"

	if !element.elements["vendorSupplierDiversityExpirationDate"].nil?
		if !element.elements["vendorSupplierDiversityExpirationDate"].text.nil?
			expDates[i].text = element.elements["vendorSupplierDiversityExpirationDate"].text
			vendSuppliers[i].add_element expDates[i]
			element.delete_element element.elements["vendorSupplierDiversityExpirationDate"]
		end
	end

	if !element.elements["vendorSupplierDiversityCode"].nil?
		if !element.elements["vendorSupplierDiversityCode"].text.nil?
			divCodes[i].text = element.elements["vendorSupplierDiversityCode"].text
			vendSuppliers[i].add_element divCodes[i]	
		end
	end

	if !element.elements["versionNumber"].nil?
		if !element.elements["versionNumber"].text.nil?
			supVNums[i].text = "1"
			vendSuppliers[i].add_element supVNums[i]
		end
	end

	if !element.elements["newCollectionRecord"].nil?
		if !element.elements["newCollectionRecord"].text.nil?
			supNewCols[i].text = element.elements["newCollectionRecord"].text
			vendSuppliers[i].add_element supNewCols[i]
		end
	end

	element.add_element vendSuppliers[i]
end

}

i = 0
headerExts = Array.new
w9s = Array.new
headerVs = Array.new
headerCols = Array.new
headerIds = Array.new
v4cs = Array.new
vW8BRD = Array.new
vFTN = Array.new
vGIIN = Array.new
vFRBD = Array.new


XPath.each( doc, "//vendorHeader") { |element|
i += 1

if element.elements["extension"].nil?
	headerExts[i] = Element.new "extension"
	headerExts[i].attributes["class"] = "edu.cornell.kfs.vnd.businessobject.CuVendorHeaderExtension"

	w9s[i] = Element.new "vendorW9ReceivedDate"
	headerVs[i] = Element.new "versionNumber"
	headerCols[i] = Element.new "newCollectionRecord"
	headerIds[i] = Element.new "vendorHeaderGeneratedIdentifier"

	v4cs[i] = 	Element.new "vendorChapter4StatusCode"
	vW8BRD[i] = 	Element.new "vendorW8BenReceivedDate"
	vFTN[i] = 	Element.new "vendorForeignTaxNumber"
	vGIIN[i] = 	Element.new "vendorGIIN"
	vFRBD[i] = 	Element.new "vendorForeignRecipientBirthDate"





	if !element.elements["vendorW9ReceivedDate"].nil?
		if !element.elements["vendorW9ReceivedDate"].text.nil?
			w9s[i].text = element.elements["vendorW9ReceivedDate"].text
			headerExts[i].add_element w9s[i]
			element.delete_element element.elements["vendorW9ReceivedDate"]
		end
	end 
	if !element.elements["versionNumber"].nil?
		if !element.elements["versionNumber"].text.nil?
			headerVs[i].text = "1"
			headerExts[i].add_element headerVs[i]
		end
	end
	if !element.elements["newCollectionRecord"].nil?
		if !element.elements["newCollectionRecord"].text.nil?
			headerCols[i].text = element.elements["newCollectionRecord"].text
			headerExts[i].add_element headerCols[i]
		end
	end

	if !element.elements["vendorHeaderGeneratedIdentifier"].nil?
		if !element.elements["vendorHeaderGeneratedIdentifier"].text.nil?
			headerIds[i].text = element.elements["vendorHeaderGeneratedIdentifier"].text
			headerExts[i].add_element headerIds[i]
		end
	end
	if !element.elements["vendorChapter4StatusCode"].nil?
		if !element.elements["vendorChapter4StatusCode"].text.nil?
			v4cs[i].text = element.elements["vendorChapter4StatusCode"].text
			headerExts[i].add_element v4cs[i]
		end
	end

	if !element.elements["vendorW8BenReceivedDate"].nil?
		if !element.elements["vendorW8BenReceivedDate"].text.nil?
			vW8BRD[i].text = element.elements["vendorW8BenReceivedDate"].text		
			headerExts[i].add_element vW8BRD[i]
		end
	end
	
	if !element.elements["vendorForeignTaxNumber"].nil?
		if !element.elements["vendorForeignTaxNumber"].text.nil?
			vFTN[i].text = element.elements["vendorForeignTaxNumber"].text
			headerExts[i].add_element vFTN[i]
		end
	end

	if !element.elements["vendorGIIN"].nil?
		if !element.elements["vendorGIIN"].text.nil?	
			vGIIN[i].text = element.elements["vendorGIIN"].text
			headerExts[i].add_element vGIIN[i]
		end
	end

	if !element.elements["vendorForeignRecipientBirthDate"].nil?
		if !element.elements["vendorForeignRecipientBirthDate"].text.nil?
			vFRBD[i].text = element.elements["vendorForeignRecipientBirthDate"].text
			headerExts[i].add_element vFRBD[i]
		end
	end

	element.add_element headerExts[i]

end

}


i = 0
vendDetExts = Array.new
vheadIds = Array.new
vNums = Array.new

XPath.each( doc, "//org.kuali.kfs.vnd.businessobject.VendorDetail") { |element|
i += 1


if !element.elements["extension"].nil?
        vendDetExts[i] = element.elements["extension"]
        if vendDetExts[i].elements["versionNumber"].nil?
                vNums[i] = Element.new "versionNumber"
                vNums[i].text = "1"
                vendDetExts[i].add_element vNums[i]
        end
else
        vendDetExts[i] = Element.new "extension"
        vendDetExts[i].attributes["class"] = "edu.cornell.kfs.vnd.businessobject.VendorDetailExtension"
        vNums[i] = Element.new "versionNumber"
        vNums[i].text = "1"
        vendDetExts[i].add_element vNums[i]
end

if !element.elements["insuranceRequiredIndicator"].nil?
	insInd = element.elements["insuranceRequiredIndicator"]
else
	insInd = Element.new "insuranceRequiredIndicator"
end

if !element.elements["insuranceRequirementsCompleteIndicator"].nil?
	insCInd = element.elements["insuranceRequirementsCompleteIndicator"]
else
	insCInd = Element.new "insuranceRequirementsCompleteIndicator"
end

if !element.elements["cornellAdditionalInsuredIndicator"].nil?
       cornellAII = element.elements["cornellAdditionalInsuredIndicator"]
else
	cornellAII = Element.new "cornellAdditionalInsuredIndicator"
end

if !element.elements["vendorCreditCardMerchants"].nil?
	ccMerchant = element.elements["vendorCreditCardMerchants"]
else
	ccMerchant = Element.new "vendorCreditCardMerchants"
end

if !element.elements["generalLiabilityCoverageAmount"].nil?
	gLC = element.elements["generalLiabilityCoverageAmount"]
	if vendDetExts[i].elements["generalLiabilityCoverageAmount"].nil?
        	vendDetExts[i].add_element gLC
	end
end

if !element.elements["generalLiabilityExpiration"].nil?
	gLE = element.elements["generalLiabilityExpiration"]
	if vendDetExts[i].elements["generalLiabilityExpiration"].nil?
        	vendDetExts[i].add_element gLE
        end
end

if !element.elements["automobileLiabilityCoverageAmount"].nil?
	aLC = element.elements["automobileLiabilityCoverageAmount"]
	if vendDetExts[i].elements["automobileLiabilityCoverageAmount"].nil?
        	vendDetExts[i].add_element aLC
	end
end

if !element.elements["automobileLiabilityExpiration"].nil?
	aLE = element.elements["automobileLiabilityExpiration"]
	if vendDetExts[i].elements["automobileLiabilityExpiration"].nil?
        vendDetExts[i].add_element aLE
	end
end


if !element.elements["workmansCompCoverageAmount"].nil?
	wCCA = element.elements["workmansCompCoverageAmount"]
	if vendDetExts[i].elements["workmansCompCoverageAmount"].nil?
        	vendDetExts[i].add_element wCCA
	end
end

if !element.elements["workmansCompExpiration"].nil?
	wCE = element.elements["workmansCompExpiration"]
	if vendDetExts[i].elements["workmansCompExpiration"].nil?
        	vendDetExts[i].add_element wCE
	end
end

if !element.elements["excessLiabilityUmbrellaAmount"].nil?
	eLUA = element.elements["excessLiabilityUmbrellaAmount"]
	if vendDetExts[i].elements["excessLiabilityUmbrellaAmount"].nil?
   	     vendDetExts[i].add_element eLUA
	end
end

if !element.elements["excessLiabilityUmbExpiration"].nil?
	eLUE = element.elements["excessLiabilityUmbExpiration"]
	if vendDetExts[i].elements["excessLiabilityUmbExpiration"].nil?
		vendDetExts[i].add_element eLUE
	end
end

if !element.elements["healthOffSiteCateringLicenseReq"].nil?
	hOSCLR = element.elements["healthOffSiteCateringLicenseReq"]
	if vendDetExts[i].elements["healthOffSiteCateringLicenseReq"].nil?
        	vendDetExts[i].add_element hOSCLR
	end
end

if !element.elements["healthOffSiteLicenseExpirationDate"].nil?
	hOSLED = element.elements["healthOffSiteLicenseExpirationDate"]
	if vendDetExts[i].elements["healthOffSiteLicenseExpirationDate"].nil?
        	vendDetExts[i].add_element hOSLED 
	end
end

if !element.elements["insuranceNotes"].nil?
	iNotes = element.elements["insuranceNotes"]
	if vendDetExts[i].elements["insuranceNotes"].nil?
		vendDetExts[i].add_element iNotes
	end
end

if !element.elements["merchantNotes"].nil?
	mNotes = element.elements["merchantNotes"]
	if vendDetExts[i].elements["merchantNotes"].nil?
		vendDetExts[i].add_element mNotes
	end
end

if vendDetExts[i].elements["insuranceRequiredIndicator"].nil?
	vendDetExts[i].add_element insInd
end

if vendDetExts[i].elements["vendorCreditCardMerchants"].nil?
	vendDetExts[i].add_element ccMerchant
end

if vendDetExts[i].elements["insuranceRequirementsCompleteIndicator"].nil?
	vendDetExts[i].add_element insCInd
end

if vendDetExts[i].elements["cornellAdditionalInsuredIndicator"].nil?
   vendDetExts[i].add_element cornellAII	
end

if !element.elements["insuranceNotes"].nil?
	element.delete_element element.elements["insuranceNotes"]
end

if !element.elements["merchantNotes"].nil?
	lement.delete_element element.elements["merchantNotes"]
end

if !element.elements["generalLiabilityCoverageAmount"].nil?
	element.delete_element element.elements["generalLiabilityCoverageAmount"]
end

if !element.elements["generalLiabilityExpiration"].nil?
	element.delete_element element.elements["generalLiabilityExpiration"]
end

if !element.elements["automobileLiabilityCoverageAmount"].nil?
	element.delete_element element.elements["automobileLiabilityExpiration"]
end

if !element.elements["automobileLiabilityExpiration"].nil?
	element.delete_element element.elements["automobileLiabilityExpiration"]
end

if !element.elements["workmansCompCoverageAmount"].nil?
	element.delete_element element.elements["workmansCompCoverageAmount"]
end

if !element.elements["workmansCompExpiration"].nil?
	element.delete_element element.elements["workmansCompExpiration"]
end

if !element.elements["excessLiabilityUmbrellaAmount"].nil?
	 element.delete_element element.elements["excessLiabilityUmbrellaAmount"]
end

if !element.elements["healthOffSiteCateringLicenseReq"].nil?
	element.delete_element element.elements["healthOffSiteCateringLicenseReq"]
end

if !element.elements["healthOffSiteLicenseExpirationDate"].nil?
	element.delete_element element.elements["healthOffSiteLicenseExpirationDate"]
end

if !element.elements["cornellAdditionalInsuredIndicator"].nil?
	element.delete_element element.elements["cornellAdditionalInsuredIndicator"]  
end

if !element.elements["insuranceRequirementsCompleteIndicator"].nil?
	element.delete_element element.elements["insuranceRequirementsCompleteIndicator"]
end

if !element.elements["insuranceRequiredIndicator"].nil?
element.delete_element element.elements["insuranceRequiredIndicator"]
end
if !element.elements["vendorCreditCardMerchants"].nil?
element.delete_element element.elements["vendorCreditCardMerchants"]
end
}
 

docString = ""
doc.write(docString)
decrypted_doc_contnt = docString



encrypted_doc_contnt = encrypt(decrypted_doc_contnt)

sql = "UPDATE KRNS_MAINT_DOC_T SET DOC_CNTNT = ? where doc_hdr_id = '#{sdocid}'"
puts sql
pstmt = conn.prepareStatement(sql)
pstmt.setStringForClob(1,encrypted_doc_contnt)
pstmt.executeUpdate()

conn.commit
pstmt.close()

end
