package MementoThread;

use URI;

use FindBin;
use lib "$FindBin::Bin";

#constructor
sub new {

    my $self = {
        URIQ     => undef,   #String, This is the input URI that we need to retrieve its mementos 
        URIR    => undef,
        Text    => undef,   #String, the URI content
        RedirectionList   => undef,
        FollowEmbedded  => 0,
        TimeGate => "http://mementoproxy.cs.odu.edu/aggr/timegate/",
        Mode => 0, #0 is the default mode (Relaxed)
        RedirectionPolicy => undef,
        DateTime =>undef,
        Debug => 0,
        Override => 0,
        RobotsTG => undef,
        ReplaceFile => undef,
        AllParams=>undef,
        HeadParams=>undef,
        memento=>undef,
        Headers => {
                    status=> undef,
                    vary => 0,  #Vary default false
                    MementoDT => undef,
                    Link => undef,
                    contentType => undef,
                    Location => undef
                    },
        Info => {
                    Type => 'original',
                    Original => undef,
                    Okay => 0,
                    TimeGate => undef,
                    TimeMap => undef,
                    Location =>undef,
                    OneMemento => 0
         }
    };
    if($self->{Debug} == 1){
        print "\nDEBUG: Starting a new memento thread\n";
    }
    bless $self, 'MementoThread';
    return $self;
}

sub setURI {
    my ( $self, $nURI ) = @_;
    $self->{URIQ} = $nURI if defined($nURI);

}

sub setTimeGate {
    my($self, $lTimeGate) = @_;
    $self->{TimeGate} = $lTimeGate;
}

sub setMode {
    my($self, $lMode) = @_;
    $self->{Mode} = $lMode;
}

sub setRedirectionPolicy {
    my($self, $lRedirectionPolicy ) = @_;
    $self->{RedirectionPolicy } = $lRedirectionPolicy ;
}

sub setDateTime {
    my ($self, $lDateTime) = @_;
    $self->{DateTime } = $lDateTime if defined($lDateTime);
}

sub setDebug {
    my ($self, $lDebug) = @_;
    $self->{Debug } = $lDebug if defined($lDebug);
}

sub setOverride {
    my ($self, $lOverride ) = @_;
    $self->{Override} = $lOverride if defined($lOverride);
}

sub setReplaceFile() {
    my ($self, $lReplaceFile ) = @_;
    $self->{ReplaceFile} = $lReplaceFile if defined($lReplaceFile);
}

sub setParams(){

    my ($self, @lParams ) = @_;
    #Here we may have problem with -H and --header for multi values
    $self->{AllParams} = join(' ', map { $_ eq '' || /^--/ ? $_ : "'" . $_ . "'" } @lParams);
    $self->{HeadParams} = $self->{AllParams} ;

    $_  =  $self->{HeadParams} ;
  
    my @removedSwitches = ("-a","--append","-B","--use-ascii","--tcp-nodelay",
    "-e","--referer","--compressed","--create-dirs","--crlf","-f",
    "--fail","--ftp-create-dirs","--ftp-pasv","--ftp-skip-pasv-ip",
    "--ftp-ssl","--ftp-ssl-reqd","-g","--globoff","-G","--get","-h","--help",
    "--ignore-content-length","-I","--head","-l","--list-only","-L","--location",
    "--location-trusted","-M","--manual","-N","--no-buffer","-O","--remote-name",
    "-R","--remote-time","-s","--silent","-S","--show-error","--trace-time","-v",
    "--verbose","-V","--version","-y","--speed-time","-Y","--speed-limit","-0",
    "--http1.0","--3p-quote","--3p-url","--3p-user","-#","--progress-bar");

    foreach $switch (@removedSwitches)
    {
        $self->{HeadParams}=~ s/$switch / /g;
    }
 

    my @removedSwitches2 = ("-c","--cookie-jar","-C","--continue-at","-d",
    "--data","--data-ascii","--data-binary","-D","--dump-header",
    "--connect-timeout","-F","--form","--form-string","-H","--header","-m",
    "--max-time","--max-redirs","--max-filesize","-o","--output","-P",
    "--ftp-port","-Q","--quote","-r","--range","--random-file","--retry",
    "--retry-delay","--retry-max-time","--stderr","-t","--telnet-option",
    "--trace","--trace-ascii","-z","--time-cond","-T","--upload-file","--url");

     foreach $switch (@removedSwitches2)
    {
        $self->{HeadParams}=~ s/$switch \S*/ /g;
    }

    $self->{HeadParams}= $self->{HeadParams}." -s ";

    $self->{AllParams} = $self->{AllParams} ." -s ";
   # print "All Params: ". $self->{AllParams} ."\n";
   # print "Head Params: ".$self->{HeadParams} ."\n";
    #$remvoedSwitches = '(\-c |\-\-cookie\-jar|\-C |\-\-continue\-at|\-d |\-\-data|\-\-data\-ascii|\-\-data\-binary|\-D |\-\-dump\-header|\-\-connect\-timeout|\-F |\-\-form|\-\-form\-string|\-H |\-\-header|\-m |\-\-max\-time|\-\-max\-redirs|\-\-max\-filesize|\-o |\-\-output|\-P |\-\-ftp\-port|\-Q |\-\-quote|\-r |\-\-range|\-\-random\-file|\-\-retry|\-\-retry\-delay|\-\-retry\-max\-time|\-\-stderr|\-t |\-\-telnet\-option|\-\-trace|\-\-trace\-ascii|\-z |\-\-time\-cond|\-T |\-\-upload\-file|\-\-url)*';
    #$self->{HeadParams}=~ s/$remvoedSwitches//;
  
}
sub head {
    my ($self) = @_;
    if($self->{Debug} == 1){
        print "DEBUG: Starting with head command to determine resource type\n";
    }
    my $acceptDateTimeHeader = "";
    if(length($self->{DateTime}) != 0){
        $acceptDateTimeHeader = " -H 'Accept-Datetime: ".$self->{DateTime}." ' ";
    }

    my $command = "curl -I $self->{HeadParams} $acceptDateTimeHeader '$self->{URIQ}' ";
    if($self->{Debug} == 1){
        print "DEBUG: " .$command ."\n";
    }
    my $headCmd = ` $command `;
    if($self->{Debug} == 1){
        print $headCmd;
   #     print "=============================================================\n";
    }
    #Start to look to the different Headers options
    $self->parseHeaders($headCmd);
    
    #In some cases, we need to lookup to URI format itself
  #  $self->determineResourceType();
   # $self->discover_tg_robots();
 #   $self->selectTimeGate();

    $self->{TimeGate} =~ s/\/$//;
    if($self->{Debug} == 1){
        print "\nDEBUG: Resource Type: ". $self->{Info}->{Type} ."\n" ; 
    }
    
}

sub selectTimeGate(){
    my ($self) = @_;

    if($self->{Debug} == 1){
        print "DEBUG: Selecting the TimeGate\n";
    }
    #override

    if($self->{Override} == 1){
        #The timegate will be as it's in $self->{TimeGate}
        #Remove the others values like $self->{Info}->{TimeGate}
        $self->{Info}->{TimeGate}  =undef;
        if($self->{Debug} == 1){
            print "DEBUG: Override case:Accepted\n";        
            print "TimeGate: " .$self->{TimeGate}."\n"
        }
#        return;

    } elsif (  $self->{Info}->{Type} eq "TimeGate"){
        $self->{TimeGate} = $self->{URIQ};

        if($self->{Debug} == 1){
            print "DEBUG: Resource Type is TimeGate case: Accepted\n";        
            print "TimeGate: " .$self->{TimeGate}."\n"
        }

 #       return;
        #Additional steps required in calling the function the memento
        #or, we can remove one of these fields at all

    } elsif( defined( $self->{Info}->{TimeGate} ) ){

        $self->{TimeGate}= $self->{Info}->{TimeGate} ;
        if($self->{Debug} == 1){
            print "DEBUG: TimeGate is defined in Link header case: Accepted\n";        
            print "TimeGate: " .$self->{TimeGate}."\n"
        }
        $self->{URIQ} =  $self->{TimeGate};

 #       return;
    } else {
    
    if($self->{Debug} == 1){
         print "DEBUG: TimeGate is not changed\n";        
         print "TimeGate: " .$self->{TimeGate}."\n";
     }
             $self->{URIQ} =  $self->{TimeGate}."/".$self->{URIQ};

    }
# elsif (defined($self->{RobotsTG})){

 #       $self->{TimeGate} = $self->{RobotsTG};
 #       if($self->{Debug} == 1){
 #           print "DEBUG: TimeGate is discovered in robots.txt case: Accepted\n";        
 #           print "TimeGate: " .$self->{TimeGate};
 #       }
  #      return;
#    }


    
 
 
    return;
}

sub findMemento(){

    my ($self) = @_;
    if($self->{Debug} == 1){
     print "=============================================================\n";
       print "DEBUG: in findMemento() URIQ: $self->{URIQ}\n";        
     print "-------------------------------------------------------------\n";
   }

    $self->head();
    
    my $tg_flag=0;

    # Case 1, bad request 400
    if($self->{status} == 400){
        # Type = bad request
        return $self->{URIQ};
    }
   #########################
   # TEST - 0
    if($self->{Headers}->{vary} == 1){ # It is a TimeGate
        if($self->{Debug} == 1)  {print "DEBUG: TEST - 0 YES\n"};     
        $tg_flag=1;
        $self->{URIR} = $self->{URIQ};
   } else {
        if($self->{Debug} == 1)  {print "DEBUG: TEST - 0 NO\n"};     

    }
   #########################
   # TEST - 1
    my $rewrittenURI = $self->unrewriteURI($self->{URIQ});
    if( length($self->{Headers}->{MementoDT})>0 or length($rewrittenURI)>0 ){
        

        $tg_flag = 0;
        $self->{URIR} = '';
        #set uri-r = blank
    #    print "=============================================================\n";

         if($self->{Headers}->{status} > 300 and $self->{Headers}->{status} <400){
            #Follow
            if($self->{Debug} == 1) {print "DEBUG: TEST - 1 YES FOLLOW\n"};     
             return $self->follow();
        } else {
            if($self->{Debug} == 1) {print "DEBUG: TEST - 1 YES MEMENTO\n"};     

                $self->{memento}=$self->{URIQ};
            return $self->{URIQ};
        }
    }else {
        if($self->{Debug} == 1)  {print "DEBUG: TEST - 1 NO\n"};     

    }
   #########################
   # TEST - 2 -- POOR man
    if($self->{Headers}->{status} > 299 and $self->{Headers}->{status} < 400){
        if($self->{Debug} == 1){  print "DEBUG: TEST - 2 YES\n"};     

        #FOLLOW
  #      print "=============================================================\n";

        return $self->follow();

    }else {
        if($self->{Debug} == 1)  {print "DEBUG: TEST - 2 NO\n"};     

    }
   #########################
   # TEST - 3
    if($tg_flag == 1 and $self->{Headers}->{status} >399){
        if($self->{Debug} == 1) { print "DEBUG: TEST - 3 YES\n"};     
   #     print "=============================================================\n";

        return $self->{URIQ};
    }else {
        if($self->{Debug} == 1)  {print "DEBUG: TEST - 3 NO\n"};     

    }

   #########################
   # TEST - 4
   if( $self->{Info}->{TimeGate}!= ''){
         if($self->{Debug} == 1)  {print "DEBUG: TEST - 4 YES\n"};     
       $tg_flag = 1;
       $self->{URIQ} = $self->{Info}->{TimeGate};
  #      print "=============================================================\n";

        return  $self->findMemento(); 
   } else {
         if($self->{Debug} == 1)  {print "DEBUG: TEST - 4 NO\n"};     

        $self->{URIR} = $self->{URIQ};
        $self->selectTimeGate();
   #     print "=============================================================\n";

        return  $self->findMemento(); 
    }
   
      return $self->{URIQ};
}

sub follow{
    my ($self) = @_;

    if( length($self->{Headers}->{Location} )>0){
    if($self->{Debug} == 1)  {print "DEBUG: follow Location\n"};     

        $self->{URIQ} = $self->{Headers}->{Location};
  #      print "=============================================================\n";

        $self->findMemento();
    } else {
    if($self->{Debug} == 1)  {print "DEBUG: follow ERROR \n"};     
   #     print "=============================================================\n";

        return $self->{URIQ};
    }
}

sub parseHeaders {

   my ($self, $tmp) = @_;
   $_ = $tmp;
   if($self->{Debug} == 1){
        print "DEBUG: In parsing header function\n";
   }

    $self->{Headers}->{MementoDT}=undef;
    $self->{Headers}->{vary} = 0;
    $self->{Headers}->{status}= 0;   
    $self->{FollowEmbedded} = 0;
    $self->{Headers}->{Link} =undef;
    $self->{Headers}->{Location} = undef;

    if( m/Memento-Datetime:.*\n/){
        $self->{Headers}->{MementoDT} = substr($&, 18);
    }

    if( m/Vary:.*accept-datetime.*\n/){
        $self->{Headers}->{vary} = 1;
     }

    if( m/HTTP\/1\.\d\s\d\d\d\s.*\n/ ){
        $self->{Headers}->{status}= int(substr($&,9,3));   
    }

    if( m/Content\-Type:.*\n/){
        if( substr($&,14) =~ m/text\// ){
            $self->{FollowEmbedded} = 1;
        }       
    }
    
    if( m/Link:.*\n/ ){
         
        $self->{Headers}->{Link} =$&;

        my @links = (m/<[^>]*>;[^<]*rel=\"?[^\"]*\"?/g);

        for(my $i=0 ; $i<= $#links ; $i++){

            @line = split( /;/,$links[$i] ) ;

            if($links[$i] =~ m/.*original.*/ ){
                $self->{Info}->{Original} = substr($line[0], 1, length($line[0]) -2);
            }elsif ($links[$i] =~ m/.*timegate.*/ ){
                $self->{Info}->{TimeGate} = substr($line[0], 1, length($line[0]) -2);
            }elsif ($links[$i] =~ m/.*timemap.*/ ){
                $self->{Info}->{TimeMap} = substr($line[0], 1, length($line[0]) -2);
            }elsif ($links[$i] =~ m/.*first last memento.*/ ){
                $self->{Info}->{OneMemento} = 1;
                $self->{memento} = substr($line[0], 1, length($line[0]) -2);

              
            }
        }

    }
    if( m/Location:.*\n/ ){

        $self->{Headers}->{Location} = substr($&,10);
        #This is a special case for the Location header that has a trailer \r that affects the subsequent steps
        if($self->{Headers}->{Location} =~ /\r$/){
            $self->{Headers}->{Location} =substr($self->{Headers}->{Location} , 0,length($self->{Headers}->{Location} )-2);
        }
        
        
    }
    if($self->{Debug} == 1){
       print "DEBUG: Parsing header results: \n\t* Memento-datetime: $self->{Headers}->{MementoDT}\n";
       print "\t* VARY: $self->{Headers}->{vary} \n\t* HTTP Status:  $self->{Headers}->{status}\n";
       print "\t* Follow the embedded resources: $self->{FollowEmbedded} \n";
       print "\t* Link (org): $self->{Info}->{Original}\n\t* Link (timegate):$self->{Info}->{TimeGate}\n";
       print "\t* Link (timemap):$self->{Info}->{TimeMap}\n\t* Location: $self->{Headers}->{Location} \n";
    }
}

sub discover_tg_robots {
     my ($self, @params) = @_;
    if($self->{Debug} == 1){
        print "DEBUG: Discovering Timegate robots\n";
    }
    my $robotTG = '';
  
    my $urlObj = URI->new($self->{URIQ});
    
    my $host =  "http://".$urlObj->host( ) .'/robots.txt' ;
    my $robots = `curl $self->{HeadParams} -L $host`;

    my @lines = split('\n',$robots);
    
     foreach (@lines) {
        if( index($_, 'TimeGate') ==0){
            $robotTG = substr( $_, 9, length ($_)-10);
            
        } elsif(index($_, 'Archived') ==0){

                
            if( $_ eq '*' or index($self->{URIQ}, substr( $_, 10, length ($_)-11)) > -1){
                
                if($self->{Debug} == 1){
                    print "\nDEBUG: A new TimeGate is discovered through (robots.txt): $robotTG";
                }
                $self->{RobotsTG} = $robotTG;
                return;
                }

        }
     } 
    
    
}

sub process_uri {
    my ($self) = @_;
    
    if($self->{Debug} == 1){
        print "DEBUG: in process URI\n";
    }
    
    my $URIFinal = $self->findMemento();

    my $acceptDateTimeHeader = '';
    if(length($self->{DateTime}) != 0){
        $acceptDateTimeHeader = ' -H "Accept-Datetime: '.$self->{DateTime}.'" ';
    }

    my  $command ='';
    my $commandTail = '';
    #it has a problem with different timegates values
    # Ex. mcurl.pl -I -L --datetime "Fri, 23 July 2009 12:00:00 GMT"  http://lanlsource.lanl.gov/hello
    # Ex. mcurl.pl -I -L --datetime "Fri, 23 July 2009 12:00:00 GMT"  http://mementoproxy.cs.odu.edu/aggr/timegate/http://www.digitalpreservation.gov/


    $commandTail = " $acceptDateTimeHeader '" .  $URIFinal . "'";

  # print "Memento: ".$self->{memento} ;
   $command = "curl $self->{AllParams} ". $commandTail;
   if($self->{Debug} == 1){
        print "=============================================================\n";
        print "DEBUG: Final command, " . $command ."\n";
   }
   $result = `$command`;

    #based on the type (text/html) and stict/relaxed mode we will force the retrieve embedded via memento method
    if( $self->{FollowEmbedded} == 1 && $self->{Mode}==1){
       $result= $self->retrieve_embedded($result);
    }
    
    return $result;
}

sub handle_redirection {
     my ($self) = @_;

#Redirection policy case 1, URI-R has 302
    if($self->{Debug} == 1){
        print "DEBUG: In handle_Redirection\n";
    }
    if(  $self->{Headers}->{status} > 299 and $self->{Headers}->{status} < 399 and   $self->{Info}->{Type} eq 'original' ){
            if($self->{Debug} == 1){
                print "DEBUG: Redirection policy #1, URI-R: $self->{URI} has a redirection to $self->{Headers}->{Location}\n";
            }
            my $acceptDateTimeHeader = "";

            if(length($self->{DateTime}) != 0){
                $acceptDateTimeHeader = " -H \"Accept-Datetime: ".$self->{DateTime}." \" ";
            }
           
           my $command ;
           if ( defined( $self->{Info}->{TimeGate} ) ){

                $command = "curl $self->{HeadParams} -I -L $acceptDateTimeHeader '" . $self->{Info}->{TimeGate} . "'";
            } else {
                $command = "curl $self->{HeadParams} -I -L $acceptDateTimeHeader '" . $self->{TimeGate} . "/" . $self->{URIQ} . "'";

            }
            
            if($self->{Debug} == 1){
                print "\nDEBUG: " . $command ."\n";
            }
            my $results = `$command`;

            #if the status 404 move to the redirected location
            my $redirectionStatus = 404;
            my @redirectionStatusList = ($results =~ m/HTTP\/1\.\d\s\d\d\d\s.*\n/g);

            if($#redirectionStatusList > 0){
                $redirectionStatus = int(substr( @redirectionStatusList[-1],9,3));
            }
            #if( m/HTTP\/1\.\d\s\d\d\d\s.*\n/ ){
            #   $redirectionStatus  = int(substr($&,9,3));   
            #}

            # the status may be 200, 302, 404
        #    if ($redirectionStatus >=300 and $redirectionStatus <400){
                #it's an expected status because the timegate will redirect to the memento
                #TODO
                # should we test the location value?
              #  while( $redirectionStatus >=300 and $redirectionStatus <400 ){

               #     my $newLoc = "";
               #     if( $results  =~ m/Location:.*\n/ ){

                #        $newLoc = substr($&,10);
                 #   }
                  #  $results  = `curl -I $newLoc`;
                  #  $redirectionStatus = 404;
                  #  if( $results  =~ m/HTTP\/1\.\d\s\d\d\d\s.*\n/ ){
                  #     $redirectionStatus  = int(substr($&,9,3));   
                  #  }
                   
             #   }
              #  print "DEBUG: Status equals ($redirectionStatus), use the original URI\n";                
              #  return;
                
         #   }
            if( $redirectionStatus == 200 ){
                
                #that's ok, use the original URI
                if($self->{Debug} == 1){
                    print "DEBUG: Memento redirection status equals ($redirectionStatus), use the original URI\n";
                }
                return;                
                #todo
                #check for the time bubble
                
            } else{ #Not success nor redirect
                # use the Location URI
                if($self->{Debug} == 1){
                    print "DEBUG: Memento redirection status equals ($redirectionStatus), use the redirected URI: $self->{Headers}->{Location} \n";
                }
                $self->{URIQ}= $self->{Headers}->{Location} ;
                $self->head();
                return;
                
            }
    }

}

sub retrieve_embedded {
    #Make sure the syntax of the URI
    my ($self,$pageText) = @_;
    if($self->{Debug} == 1){
        print "DEBUG: In retrieve Embedded resources function\n";
    }
    my $dumpFile = undef;
    if(defined($self->{ReplaceFile}) ){

        open $dumpFile, ">", $self->{ReplaceFile};
    }

    my $memParser = new MementoParser();
    $memParser->parse($pageText);

    my @oldURIs =  $memParser->returnURIs();

    if($self->{Debug} == 1){
        print "DEBUG: Number of embedded resources retrieved: " . $#oldURIs."\n";
    }

    my %hash   = map { $_, 'aa'} @oldURIs;
    # or a hash slice: @hash{ @array } = ();3.	# or a foreach: $hash{$_} = 1 foreach ( @array );4.5.	
    #my @unique = keys %hash;

    foreach my $oldURI (keys %hash)
    { 
        my $completeOldURI = $oldURI;

        #There is a missing testcase here if the URI ends with .html for example
        if(index($oldURI, "http") != 0){
           my $urlObj = URI->new($self->{memento});
           $completeOldURI = URI->new_abs($oldURI, $urlObj );  ;
           #$completeOldURI = $baseURI. $oldURI;
        }

        if($self->{Debug} == 1){
            print $completeOldURI."\n";
        }
        my $embeddedThread = new MementoThread();
   
        $embeddedThread->setURI($completeOldURI);
        $embeddedThread->setMode(0);
        $embeddedThread->setDateTime($self->{DateTime});
        $embeddedThread->setDebug($self->{Debug});
        $embeddedThread->setOverride($self->{Override});
        $embeddedThread->setTimeGate($self->{TimeGate});
     #   $embeddedThread->findMemento();
        @param = ();
       # $embeddedThread->setParams($self->{HeadParams} );
  
       $embeddedThread->{HeadParams}=$self->{HeadParams};
        $embeddedThread->{AllParams}=$self->{AllParams};

        $embeddedResult = $embeddedThread->process_uri();
        
        if( defined($embeddedThread->{memento} )){

            my $newURI = $embeddedThread->{memento};
            $pageText =~ s/$oldURI/$newURI/g;

            if($self->{Debug} == 1){
                print "DEBUG: Replace $oldURI \n\t      With $newURI\n";
            }
            if( defined($dumpFile) ){
                print $dumpFile $oldURI .",".$newURI."\n";
            }
        }  else {
            if($self->{Debug} == 1){
                print "DEBUG: Replace was not available\n";
                print "DEBUG: $embeddedResult \n";
            }

        }
        
        
          #  my ($type, $length, $mod)  = head($oldURI);
#            if(!$length)
#            {
#                    #my $missingCommand  = "curl  $acceptDateTimeHeader http://mementoproxy.cs.odu.edu/aggr/timemap/link/$oldURI";
#                    my $missingCommand  = "curl  -IL $acceptDateTimeHeader $timegate/".substr($oldURI,57);
#                    print $oldURI;
#                    print $missingCommand."\n";
#                    my $results = `$missingCommand`;
#                    print $results."\n\n";

#            }



    }
    if( defined($dumpFile) ){
      close $dumpFile;
    }

    return $pageText;
}

sub unrewriteURI {
    my ($self, $orgURI) = @_;
    if($self->{Debug} == 1){
        print "DEBUG: Try to unrewrite the URI, ";
    }
    if( index($orgURI ,'archive.org/') > -1 or
        index($orgURI ,'webarchive.nationalarchives.gov.uk') > -1 or
        index($orgURI ,'wayback.archive-it.org') > -1  or
        index($orgURI ,'enterprise.archiefweb.eu/archives/archiefweb') > -1 or
        index($orgURI ,'memento.waybackmachine.org/memento/') > -1 or
        index($orgURI ,'www.webarchive.org.uk/waybacktg/memento') > -1
        ) {
        
            my $nHttp = index($orgURI , 'http://' , 10);
            if($nHttp > 1){
                    if($self->{Debug} == 1){
                        print "DEBUG: Successfully, URI is: ".substr $orgURI,$nHttp ."\n";
                        print "\n";
                        }
                return substr $orgURI,$nHttp ;
            }

    }
    if($self->{Debug} == 1){
        print "UnSuccessfully\n";
    }
    return "";

}

sub process_timemap{
    
    my ($self, $timemap, @params) = @_;   
    if($self->{Debug} == 1){
        print "DEBUG: in process TimeMap type: $timemap \n";    
    }
    my $timeMapURI = undef;
    my $command = undef;

   if(defined($self->{Info}->{TimeMap})){
        if($self->{Debug} == 1){
            print "DEBUG: Read TimeMap from the Link header \n";    
        }
        $timeMapURI = $self->{Info}->{TimeMap};
    } elsif(     defined( $self->{Info}->{TimeGate} ) 
        or  $self->{Info}->{Type} eq "TimeGate"){
        #This is part should be updated to check if the concatenation between the URI and TimeGate required or not
        $command = "curl $self->{AllParams} -I -L '" . $self->{TimeGate} . "'";

    } else {

       $command ="curl $self->{AllParams} -I -L '". $self->{TimeGate} . "/" . $self->{URIQ} . "'";

    }


    if(defined($command)){
        if($self->{Debug} == 1){
            print "DEBUG: Head request to the TimeGate to get the TimeMap\n";
            print "DEBUG: " . $command;
        }

        my $result = `$command`;
        $_ = $result;

       if(  m/Link:.*\n/ ){
            my @links = ( m/<[^>]*>;\s?rel=\"?[^\"]*\"?/g);

            for(my $i=0 ; $i<= $#links ; $i++){
                @line = split( /;/,$links[$i] ) ;
                if ($line[1] =~ m/.*timemap.*/ ){

                   $self->{Info}->{TimeMap} = substr($line[0], 1, length($line[0]) -2);
                   $timeMapURI = $self->{Info}->{TimeMap} ;
                    if($self->{Debug} == 1){
                        print "DEBUG: Head request successfully retrieved the TimeMap \n";    
                    }

               }
            }
        }
    }
    
    if( not defined($timeMapURI)){
        $timeMapURI = $self->{TimeGate};
        $timeMapURI  =~ s/timegate/timemap/g;

        if ( index( $timeMapURI, '/',length($timeMapURI) -3) < 0 ){
            $timeMapURI = $timeMapURI."/";
        }
        $timeMapURI = $timeMapURI.$timemap . '/' . $self->{URIQ};

        if($self->{Debug} == 1){
            print "DEBUG: Get the TimeMap by replacing the TimeGate \n";    
        }

    }
    my  $command = "curl $self->{AllParams} '$timeMapURI'";
    if($self->{Debug} == 1){
  
        print "DEBUG: ".$command;
    }

    my $result = `$command`;
    return $result;
}

1;
