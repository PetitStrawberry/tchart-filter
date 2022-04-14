#!/usr/bin/perl

# Timing chart formatter  by kumagai
# 02/04/29:  first release?
# 02/07/12:  add settings
# 02/07/22:  add 'slant'

if(!open(SRC,$ARGV[0])) {
    exit(1);
}

if($#ARGV>0) {
    if(!open(DEST,"> $ARGV[1]")) {
	exit(2);
    }
    select(DEST);
}

$set{'step'}=10;                  # Time slice
$set{'lineheight'}=10;            # Height of line in pt(points).
$set{'lineskip'}=20;              # Vertical interval of line in pt
$set{'capwidth'}=40;              # Width of caption in pt
$set{'slant'}=0.3;                # Ratio of slant in transition
$set{'signalline'}='0 0 0 setrgbcolor 5 setlinewidth';
$set{'borderline'}='0.7 0.7 0.7 setrgbcolor 5 setlinewidth';
$set{'gridline'}='1 0 0 setrgbcolor 2 setlinewidth';
                                  # Styles of line
$set{'rotate'}=0;                 # Rotate CCW when set to 1
$set{'capfont'}='Helvetica';      # Font of cation
$set{'strfont'}='Helvetica';      # Font of strings in level lines

$linec=0;
$maxlen=0;
$commentlines='';
while(<SRC>) {
    $commentlines=$commentlines.'%%'.$_;
    if(/^\#/) {
	next;
    }
    if(/^@/) {
	if(!/^@([^\s]+)[\s]+([^\s].*)$/) {
	    print STDERR "Illegal Line: $_";
	    next;
	}
	$set{$1}=$2;
	next;
    }
    if(/^%/) {
	if(!/^%([\d\.]+)[\s]+([\d\.]+)[\s]+([^\s].*)$/) {
	    print STDERR "Illegal Line: $_";
	    next;
	}
	AddString($2,$1,$3);
	next;
    }
    if(/^\s*$/) {
	next;
    }
    s/\s*$//;
    if(!/^([^\s]+)[\s]+([^\s].*)$/) {
	print STDERR "Illegal Line: $_";
	next;
    }
    $caption[$linec]=$1;
    $line[$linec]=$2;
    if(GetLength($line[$linec])>$maxlen) { $maxlen=GetLength($line[$linec]); }
    $linec++;
}

print STDERR "$linec Lines\n";

$w=$maxlen*$set{'step'}+$set{'capwidth'}+3;
$h=$set{'lineskip'}*$linec;
print "%!PS-Adobe-3.0 EPSF-3.0\n";
if($set{'rotate'}) {
    print "%%BoundingBox: 20 20 ".($h+22)." ".($w+22)."\n";
    print "21 21 translate 90 rotate 0.1 -0.1 scale\n";
} else {
    print "%%BoundingBox: 20 20 ".($w+22)." ".($h+22)."\n";
    print "21 ".($h+21)." translate 0.1 -0.1 scale\n";
}
print "/showright { dup stringwidth pop neg 0 rmoveto show } def\n";
print "/showleft { show } def\n";
print "/showcenter { dup stringwidth pop 2 div neg 0 rmoveto show } def\n";

$set{'step'}*=10;
$set{'capwidth'}*=10;
$set{'lineheight'}*=10;
$set{'lineskip'}*=10;
$w*=10; $h*=10;

print "$set{'borderline'}\n";
print "newpath -5 -5 moveto ";
print "".($w+5)." -5 lineto ";
print "".($w+5)." ".($h+5)." lineto ";
print "-5 ".($h+5)." lineto ";
print "-5 -5 lineto stroke\n";


$showcap='showright';
# キャプション
$sz=int($set{'lineheight'}*0.8+0.5);
print "/$set{'capfont'} findfont [$sz 0 0 -$sz 0 0] makefont setfont\n";
print "$set{'signalline'}\n";
for($i=0;$i<$linec;$i++) {
    printf("%d %d moveto\n",$set{'capwidth'},
	   int(($i+0.5)*$set{'lineskip'}+0.3*$set{'lineheight'}));
    print "($caption[$i]) $showcap\n";
}

##############
# レベル出力

$fline{'-'}=0.5; $fline{'~'}=1; $fline{'_'}=0; $fline{'='}=0;
$fline{':'}=-1;
$sline{'-'}=0.5; $sline{'~'}=1; $sline{'_'}=0; $sline{'='}=1;
$sline{':'}=-1;

for($i=0;$i<$linec;$i++) {
    $_=$line[$i];
    for($j=0;$j<$maxlen;$j++) { $_=$_.':'; } # あほや
    $_=':'.$_.':';

    $fline{'='}=0; $sline{'='}=1;
    $extra=1;
    $src=$_;
    $lc=$fline{GetChar($i,0)};
    for($j=0;$j<$maxlen+1;$j++) {
	$ll=$lc;  $lc=$fline{GetChar($i,$j)};
	DrawLevel($i,$j,$ll,$lc);
    }
    $_=$src;
    $fline{'='}=0; $sline{'='}=1;
    $extra=0;
    $lc=$sline{GetChar($i,0)};
    for($j=0;$j<$maxlen+1;$j++) {
	$ll=$lc;  $lc=$sline{GetChar($i,$j)};
	DrawLevel($i,$j,$ll,$lc);
    }
}

##############
# 文字列出力

$sz=int($set{'lineheight'}*0.6+0.5);
$showst='showcenter';
$showleft='showleft';
$showright='showright';
print "/$set{'strfont'} findfont [$sz 0 0 -$sz 0 0] makefont setfont\n";
for($i=0;$i<$stc;$i++) {
    if($st_s[$i]=~/^\s*$/) { next; }
    $showcmd=$showst;
    if($st_s[$i]=~/^_<_/) {
	$st_s[$i]=$';
	$showcmd=$showleft;
    }
    if($st_s[$i]=~/^_>_/) {
	$st_s[$i]=$';
	$showcmd=$showright;
    }
    printf("%d %d moveto\n",
	   int($st_x[$i]*$set{'step'}+$set{'capwidth'}+20),
	   int(($st_y[$i]+0.5)*$set{'lineskip'}+$set{'lineheight'}*0.2));
    print "($st_s[$i]) $showcmd\n";
#    print STDERR "$st_s[$i]\n";
}

print "showpage\n";
print "\n\n\n\n\n$commentlines\n";
######################################################################
######################################################################
######################################################################

sub GetChar {
    local($line,$pos)=@_;
    while(/^./) {
	$_=$';
	local($c)=$&;
	if(index('=~_-:',$c)>=0) { return $c; }
	if($c eq 'X') {
	    local($t)=$fline{'='};
	    $fline{'='}=$sline{'='};
	    $sline{'='}=$t;
	    return '=';
	}
	if($c eq "\"") {
	    if(/^([^\"]*)\"/) {  #"
		if($extra) {
		    AddString($pos,$line,$1);
		}
		$_=$';
		next;
	    }
	}

	if(!$extra) { next; }
	if($c eq '|') {
	    local($x)=int($pos*$set{'step'}+$set{'capwidth'}+20);
	    print "gsave $set{'gridline'}\n";
	    printf("newpath %d 0 moveto %d %d lineto stroke\n",
		   $x,$x,$set{'lineskip'}*$linec);
	    print "grestore\n";
	    next;
	}
	# 文字列抽出
	local($s)=$c;
	while(/^./) {
	    $c=$&;
	    if($c eq "\\") {
		$_=$';  /^./;
		$c=$&;
	    } elsif(index('=~_-:X',$c)>=0) {
		last;
	    }
	    $s=$s.$c;
	    $_=$';
	}
	AddString($pos,$line,$s);
    }
    return '';
}

sub GetLength {
    local($s)=$_[0];
    $s=~s/\"[^\"]*\"//g;  #"
    $s=~s/[^-=~_:X]//g;
    return length($s);
}

sub DrawLevel {
    local($line,$pos,$ll,$cl,$rl)=@_;
    local($sx,$sy,$ex,$ey);

    if(($ll<0)&&($cl<0)) { return; }

#    print STDERR "$line, $pos, $ll, $cl, $rl\n";

    $sx=$pos*$set{'step'}+$set{'capwidth'}+20;
    $ex=$sx+$set{'step'};

    $sy=int(($i+0.5)*$set{'lineskip'}-($ll-0.5)*$set{'lineheight'});
    $ey=int(($i+0.5)*$set{'lineskip'}-($cl-0.5)*$set{'lineheight'});

    if($ll==$cl) {
	return;
    }
    if($ll<0) {
	printf("newpath %d %d moveto\n",$sx,$ey);
	return ;
    }
    if($cl<0) {
	printf("%d %d lineto stroke\n",$sx,$sy);
	return ;
    }
    local($delta)=$set{'lineheight'}*$set{'slant'};
    local($deltap)=$delta*abs($ll-0.5);
    local($deltan)=$delta*abs($cl-0.5);
    printf("%d %d lineto\n",$sx-$deltap,$sy);
    printf("%d %d lineto\n",$sx+$deltan,$ey);
}

sub AddString {
    local($x,$y,$s)=@_;
    $st_x[$stc]=$x;
    $st_y[$stc]=$y;
    $st_s[$stc]=$s;
    $stc++;
}


#@step 5
#@lineheight 10
#@lineskip 20
##
#Clock ___~~~___~~~___~~~___|~~~___|~~~___|~~~___|~~~___|~~~___|~~~
#Bus   ---======------======------______-----=~~~~~~---------
#Test  =======X==========X========X=====X=====X=====X=====X==
#Test  =======X=====abcdefg=====X========X==AA===X==BB===X==CC===X==DD===X==
