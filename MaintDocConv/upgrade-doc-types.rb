#!/usr/bin/env ruby

require 'rubygems'
require 'oci8'

dry_run = "true"
if ARGV.length < 3
	print "Usage: UpgradeDocType database schema password dryrun?\n\tExample: UpgradeDocType dev_db cynergy my_secret_password true\n\n"
	exit
else
	db = ARGV[0]
	pass = ARGV[2]
	schema = ARGV[1]
	if ARGV.length == 4
		dry_run = ARGV[3]
	end
	print "Database: #{db}\n"
	print "Schema: #{schema}\n"
	print "Password: #{pass}\n"
	print "Dry run?: #{dry_run}\n"	
end

$conn = OCI8.new(schema, pass, db)
	
class DocTypeUpgrade
	def initialize
		@docTypes = Array.new	
	end

	def readFlatFile(fileName)
		text = File.open(fileName).read
		text.each_line do |line|
			@docTypes.push(line)
		end
	end

	def upgradeDocTypes(dryRun)
		output = File.open("dry-run.txt", "w")
		updateOutput = File.open("update-output.txt", "w")
		@docTypes.each do | dt |

			dt = dt.delete("\n")
			newDocType = $conn.exec("SELECT DOC_TYP_ID FROM KREW_DOC_TYP_T WHERE DOC_TYP_NM='#{dt}' AND CUR_IND='1'")

			newDocTypeCursor = newDocType.fetch_hash()

			newDocTypeString = newDocTypeCursor['DOC_TYP_ID']

			oldDocTypes = $conn.exec("SELECT PREV_DOC_TYP_VER_NBR FROM KREW_DOC_TYP_T WHERE DOC_TYP_NM='#{dt}' AND PREV_DOC_TYP_VER_NBR IS NOT NULL")

			while r = oldDocTypes.fetch_hash()
				oldDocTypeString = r['PREV_DOC_TYP_VER_NBR']
				if dryRun
					output << "UPDATE KREW_DOC_HDR_T SET DOC_TYP_ID='#{newDocTypeString}' WHERE DOC_TYP_ID='#{oldDocTypeString}'\n"
				else
					updateCommand = $conn.exec("UPDATE KREW_DOC_HDR_T SET DOC_TYP_ID='#{newDocTypeString}' WHERE DOC_TYP_ID='#{oldDocTypeString}'")
					updateOutput << updateCommand
					updateOutput << " -  UPDATE KREW_DOC_HDR_T SET DOC_TYP_ID='#{newDocTypeString}' WHERE DOC_TYP_ID='#{oldDocTypeString}'\n"
				end
			end

			updateOutput << "*****************\n"
			output << "******************\n\n\n"
			oldDocTypes.close
		end
		$conn.commit
		output.close
		updateOutput.close
	end

end

doc = DocTypeUpgrade.new

doc.readFlatFile("doctypes.txt");

if dry_run==="true"
	print "Performing a dry run"
	doc.upgradeDocTypes(true)
else
	doc.upgradeDocTypes(false)
end

$conn.logoff


