#! /usr/bin/perl

use Cwd ;
use HTML::Form ;
use LWP::UserAgent ;
use HTTP::Cookies ;

# You'll need this :)
$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = '0' ;

# Usage: AutoIngest <URL_to_cynergy_instance> <ServiceID_to_login_as> <ServiceID_password>
my $server = shift ;
my $netid = shift ;
my $pass = shift ;

my $baseDir = getcwd();
print "Base directory: $baseDir\n" ;

# KFS XML workflow files, with relative paths, must be done in this order
my @kfsFiles = (
  "kfs/4.1.1_5.0/workflow/workflow_attribute_updates.xml",
  "kfs/5.0_5.0.1/workflow/workflow_attribute_updates.xml",
  "kfs/5.0_5.0.1/workflow/workflow_document_updates.xml",
  "kfs/5.0.1_5.0.2/workflow/workflow_attribute_updates.xml", 
  "kfs/5.0.1_5.0.2/workflow/workflow_document_updates.xml",
  "kfs/5.0.5_5.1/workflow/workflow_document_updates.xml",
  "kfs/5.1.2_5.2/workflow/workflow_document_upgrades.xml",
  "custom/kfs/workflow/cu_purchasing_document_updates.xml",
  "custom/kfs/workflow/AccountDelegateModelMaintenanceDocument.xml",
  "custom/kfs/workflow/CU-DisbursementVoucherDocument.xml",
  "custom/kfs/workflow/EffortCommittmentTransactionalDocuments.xml",
  "custom/kfs/workflow/PaymentRequestDocument.xml",
  "custom/kfs/workflow/VendorCreditMemoDocument.xml"
	) ;

my @riceFiles = (
  "12-06-2011-ComponentMaintenanceDocument-doctype.xml",
  "AgendaEditorDocument.xml",
  "AgendaMaintenanceDocument.xml",
  "ContextMaintenanceDocument.xml",
  "PeopleFlowMaintenanceDocument.xml",
  "RuleMaintenanceDocument.xml",
  "TermMaintenanceDocument.xml",
  "TermSpecificationMaintenanceDocument.xml"
  ) ;

my @cynergyFiles = (
  "CynergyADFDocumentType.xml",
  "CynergyCountryMaintenanceDocument.xml",
  "CynergyCountyMaintenanceDocument.xml",
  "CynergyPostalCodeMaintenanceDocument.xml",
  "CynergyStateMaintenanceDocument.xml",
  "ParameterMaintenanceDocument_Cynergy.xml",
  "SecurityGroupDocumentType.xml",
  "SecurityProvisioningGroupDocumentType.xml",
  "SecurityRequestDocument.xml",
  "cmProcessRequest_xsl.xml",
  "cynergy-widgets.xml",
  "CynergyAppsDocument_DocumentType.xml",
  "PDFDocument_DocumentType.xml",
  "MultiPurposeWorkflowDocument_DocumentType.xml",
  "CITTravelRequest_DocumentType.xml",
  "GeneralPurposeWorkflowMaintenanceDocument_DocumentType.xml",
  "MPWDDocTypeMapMaintenanceDocument_DocumentType.xml",
  "PDFCUActivityRequest_DocumentType.xml",
  "PDFCUMigrationRequest_DocumentType.xml",
  "PDFCUSOProcChngRequest_DocumentType.xml",
  "PDFDocTypeMapMaintenanceDocument_DocumentType.xml",
  "InfoAccessDocument_DocumentType.xml",
  "InfoAccessUnitMaintenanceDocument_DocumentType.xml",
  "InfoAccessSubledgerMaintenanceDocument_DocumentType.xml",
  "InfoAccessRoleMaintenanceDocument_DocumentType.xml",
  "InfoAccessOrganizationMaintenanceDocument_DocumentType.xml",
  "InfoAccessNamespaceMaintenanceDocument_DocumentType.xml",
  "InfoAccessDepartmentMaintenanceDocument_DocumentType.xml",
  "ConfagreeDocument_DocumentType.xml",
  "HRDADocument_DocumentType.xml",
  "HRDARequestMaintenanceDocument_DocumentType.xml",
  "ConfAgreementDocument_DocumentType.xml",
  "DFADocument_DocumentType.xml",
  "ProcurementSystemDocument_DocumentType.xml",
  "DFARequestDocument_DocumentType.xml",
  "DFAAdminMaintenanceDocument_DocumentType.xml",
  "ADWDocument_DocumentType.xml",
  "BSCMSDocument_DocumentType.xml",
  "SDADocument_DocumentType.xml",
  "BusinessServiceCenterMaintenanceDocument_DocumentType.xml",
  "BscAcctDeptResponsibilityMaintenanceDocument_DocumentType.xml",
  "StudentRecordsDocument_DocumentType.xml",
  "StudentFinancialsDocument_DocumentType.xml",
  "StudentDataAccessDocument_DocumentType.xml",
  "InfoAccessItemTypeMaintenanceDocument_DocumentType.xml",
  "FinancialAidDocument_DocumentType.xml",
  "AdmissionsDocument_DocumentType.xml",
  "CreditCardDocument_DocumentType.xml",
  "SMSRequestDocument_DocumentType.xml",
  "BursarItemTypeDocument_DocumentType.xml",
  "CreditCardUpdateDocument_DocumentType.xml",
  "SMSRequestSolicitationMaintenanceDocument_DocumentType.xml",
  "BursarItemTypeWorkflowMaintenanceDocument_DocumentType.xml",
  "CynergyApps_KIMData.xml",
  "ConfAgreement_KIMData.xml",
  "BSCMS_KIMData.xml",
  "SDA_KIMData.xml",
  "DFA_KIMData.xml",
  "HRDA_KIMData.xml",
  "IAS_KIMData.xml",
  "kew_email_style_upgrade.xml",
  "gsc_email_style_upgrade.xml",
  "confagree_email_style_upgrade.xml",
  "GSCRequestRoutingDocument_Prod.xml",
  "CuVendorChapter4StatusMaintenanceDocument.xml"
   
  ) ;

my $redir=[qw(GET HEAD POST)] ;
my $cookiefile="cookiejar" ;
my $nomnom = HTTP::Cookies->new(FILE => $cookiefile, AUTOSAVE => 1) ;

print "Cynergy Instance: $server\n" ;
print "ServcieID: $netid\n" ;

# Array of all XML workflow files to be processed, with full pathspecs.
my @fullFileList ;

# Create full paths for KFS files
my $baseDirKfs = $baseDir . "/" ;
foreach my $xmlFile (@kfsFiles) {
  my $fullPathSpec = $baseDirKfs . $xmlFile ;
  push(@fullFileList, $fullPathSpec) ;
} 

# Create full paths for Rice files
my $baseDirRice = $baseDir . "/rice/workflow/" ;
foreach my $xmlFile (@riceFiles) {
  my $fullPathSpec = $baseDirRice . $xmlFile ;
  push(@fullFileList, $fullPathSpec) ;
}

# Create full paths for Cynergy files
my $baseDirCynergy = $baseDir . "/cynergy-standalone/support/upgrade-rice2x/" ;
foreach my $xmlFile (@cynergyFiles) {
  my $fullPathSpec = $baseDirCynergy . $xmlFile ;
  push(@fullFileList, $fullPathSpec) ;
}

foreach my $xmlFile (@fullFileList) {

  # By default LWP won't follow a redirect after a post
  my $ua=LWP::UserAgent->new(cookie_jar => $nomnom, requests_redirectable=>$redir) ;

  # Request the page, following redirects
  my $response=$ua->request(HTTP::Request->new(GET=> $server)) ;
  my $form=HTML::Form->parse($response->decoded_content,$response->base) ;

  # At CUWA login page?
  my $action = $form->action ;
  if (index($action, "loginAction") != -1) {
    print "Form element action contiains the substring: loginAction\n" ;
    $form->value(netid => $netid) ;
    $form->value(password => $pass) ;
    $response = $ua->request($form->click) ;
    $form = HTML::Form->parse($response->decoded_content,$response->base) ;
	}

  # Put XML file in edit field
  $form->value('file[0]'=> $xmlFile) ;

  # submit
  $response = $ua->request($form->click) ;

  @status = $response->content =~ /<pre>(.*?)<\/pre>/gs ;
  if ("Ingestion failed" ne $status[0]) {
    print "$xmlFile was successfully uploaded\n" ;
  } else {
    print "$xmlFile was NOT successfully uploaded.  Error: $status[1]\n" ;
  }	
}
