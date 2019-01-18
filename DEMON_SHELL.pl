#!/usr/local/bin/perl
use strict; use warnings;
use POSIX;
##############################
# SHELL - DEMON skeleton
##############################
# BIRTH ######################
die "FAIL STILLBORN $!\n" unless (daemon() == 0);
# GLOBAL #####################
my $NAME = name();
# /HIVE/
my $PING = '/HIVE/PING';
my $BIO = '/HIVE/BIO/'.$NAME;
my $BIOYAY = '/HIVE/BIO/'.$NAME.'_YAY';
my $BIOFAIL = '/HIVE/BIO/'.$NAME.'_FAIL';
my $TODO = '/HIVE/TODO/'.$NAME;
my $FEED = '/HIVE/FEED/';
my $POOL = '/HIVE/DUMP/pool/';
my $G = '/HIVE/DUMP/g/';
# attributes
my $BIRTH = age();
my $SLEEP = $TODO.'_SLEEP';
my $RATE = 100;
my $YAY = 0;
my $FAIL = 0;
# log
my $Lfh; 
my $Yfh;
my $Ffh;
# LOG ########################
open($Lfh, '>>', $BIO);
open($Yfh, '>>', $BIOYAY);
open($Ffh, '>>', $BIOFAIL);
$Lfh->autoflush(1);
$Yfh->autoflush(1);
$Ffh->autoflush(1);
# PREP #######################
printf $Lfh ("HELLOWORLD %s\n", TIME());
ping();
die "FAIL write pool $!\n" unless (-w $POOL);
die "FAIL write g $!\n" unless (-w $G);
die "FAIL write BIO $!\n" unless (-w $BIO);
die "FAIL write PING $!\n" unless (-w $PING);
die "FAIL write TODO $!\n" unless (-w $TODO);
die "FAIL write FEED $!\n" unless (-w $FEED);
die "FAIL write PING $!\n" unless (-w $PING);
# LIVE #######################
while (1)
{
	my ($cnt, $ttl);
	my @QUE = que_up();
# SLEEP ######################
	do { print $Lfh "bored\n"; sleep 3600; next} if (!@QUE);
# WORK #######################
	$cnt = 0;
	$ttl = @QUE;
	print $Lfh "ttl $ttl\n";
	for (@QUE)
	{
		SLEEP($cnt, $ttl, @QUE) if (-e $SLEEP);
		act($_);
		if ($cnt % $RATE == 0)
		{
			tombstone($cnt, $ttl);
			que_flush(@QUE);
		}
		$cnt++;
	}
	unlink $TODO;
}
# ACT ########################
# CORE #######################
sub name
{
	my $id = int(rand(999));
	my $name = $$.'_'.$id;
	return $name;
}
sub tombstone
{
	my ($cnt, $ttl) = @_;
	my ($tTIME, $nTIME, $life);
	$tTIME = age();
	$nTIME = TIME();
	$life = "$BIRTH $tTIME";
	print $Lfh "$nTIME demon: $NAME age: $life yay: $YAY fail: $FAIL\n";
}
sub ping
{
	my ($Pfh, $curTIME);
	open($Pfh, '>>', $PING);
	$curTIME = TIME();
	print $Pfh "$curTIME $$\n";
	close $Pfh;
}
sub age
{
	my $age = localtime();
	$age =~ s%..........20..%%;
	$age =~ s%^....%%;
	$age =~ s% %_%;
}
sub TIME
{
	my ($t, $mon, $day, $hour, $time);
	$t = localtime();
	$mon = (split(/\s+/, $t))[1];
	$day = (split(/\s+/, $t))[2];
	$hour = (split(/\s+/, $t))[3];
	$time = $mon.'_'.$day.'_'.$hour;
	return $time;
}
sub daemon
{
	my ($pid, $pid2, $fd, $des);
	die "FAIL fork 1 $!\n" unless (($pid = POSIX::fork()) == 0);
	die "FAIL child 1 $!\n" unless ($pid == 0);
	die "FAIL setsid $!\n" unless POSIX::setsid();
	die "FAIL fork 2 $!\n" unless (($pid2 = POSIX::fork()) == 0); 
	die "FAIL child 2 $!\n" unless ($pid2 == 0);
	die "FAIL chdir tmp $!\n" unless chdir('/HIVE/');
	POSIX::umask 0;	
	$fd = 3;
	do { POSIX::close($fd); $fd++; } while ($fd < 1024);
	$des = '/dev/null';
	open(STDIN, '<', $des);
	open(STDOUT, '>', $des);
	open(STDERR, '>', $des);
	return 0;
}
sub SLEEP
{
	my ($cnt, $ttl, @QUE) = @_;
	my ($Sfh, $timeout, $curTIME);
	open($Sfh, '<', $SLEEP);
	$timeout = readline $Sfh; chomp $timeout;
	$curTIME = TIME();
	print $Lfh "SLEEP $curTIME $timeout\n";	
	close $Sfh; unlink $SLEEP;
	SUICIDE($cnt, $ttl, @QUE) if ($timeout eq 'SUICIDE');
	tombstone($cnt, $ttl);
	sleep $timeout;
}
sub SUICIDE
{
	my ($cnt, $ttl, @QUE) = @_;
	my $curTIME = TIME();
	print $Lfh "FKTHEWORLD $curTIME\n";
	tombstone($cnt, $ttl);
	que_flush(@QUE);
	move($TODO, $FEED);
	die;
}
sub que_up
{
	my $qfh; my @QUE;	
	que_get();
	open($qfh, '<', $TODO);
	@QUE = readline $qfh; 
	chomp @QUE; close $qfh;
	return (@QUE);
}
sub que_get
{
	my $dh;
	opendir($dh, $FEED);
	my @ls = readdir($dh);
	shift(@ls); shift(@ls);
	my $que_path = $FEED.$ls[0];
	move($que_path, $TODO);
	print $Lfh "que: $que_path\n";
}
sub que_flush
{
	my (@QUE) = @_;
	open(my $TODOfh. '>', $TODO);
	print $TODOfh "$_\n" for (@QUE);
	close $TODOfh;	
}