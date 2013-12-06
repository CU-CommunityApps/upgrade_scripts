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
  "custom/kfs/workflow/cu_purchasing_document_updates.xml"
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
  "103_to_200_perm_resp_upgrade.sql",
  "CynergyADFDocumentType.xml",
  "CynergyCountryMaintenanceDocument.xml",
  "CynergyCountyMaintenanceDocument.xml",
  "CynergyPostalCodeMaintenanceDocument.xml",
  "CynergyStateMaintenanceDocument.xml",
  "Default.xml",
  "ParameterMaintenanceDocument_Cynergy.xml",
  "SecurityGroupDocumentType.xml",
  "SecurityProvisioningGroupDocumentType.xml",
  "SecurityRequestDocument.xml",
  "cmProcessRequest_xsl.xml",
  "cynergy-widgets.xml"
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
  print $response->decoded_content ;
  my $form=HTML::Form->parse($response->decoded_content,$response->base) ;

  # At CUWA login page?
  my $action = $form->action ;
  if (index($action, "loginAction") != -1) {
    print "Form element action contiains the substring: loginAction\n" ;
    $form->value(netid => $netid) ;
    $form->value(password => $pass) ;
    $response = $ua->request($form->click) ;
    print "Cuwa form submitted." ;
    $form = HTML::Form->parse($response->decoded_content,$response->base) ;
	}

  # Put XML file in edit field
  print "Looking for file_0 name element" ;
  $form->value('file[0]'=> $xmlFile) ;
  print "Set file_0 name element" ;

  # submit
  $response = $ua->request($form->click) ;
  print "Ingest form submitted" ;

  @status = $response->content =~ /<pre>(.*?)<\/pre>/gs ;
  if ("Ingestion failed" ne $status[0]) {
   print "$xmlFile was successfully uploaded\n" ;
  } else {
    print "$xmlFile was NOT successfully uploaded.  Error: $status[1]\n" ;
  }	
}
