#!/usr/bin/env perl
use Test2::V0;
use Alien::Build;
use Config;
use Cwd qw( getcwd );
use File::Temp qw( tempdir );
use File::Spec;

# Drives the alienfile's build sub directly against a stub sqlite-vec.c, so
# the sqlite3ext.h lookup is tested without the network download.

my $alienfile = File::Spec->rel2abs('alienfile');
open my $in, '<', $alienfile or die "Cannot read $alienfile: $!";
my $src = do { local $/; <$in> };
close $in;

sub run_build {
  my ($file) = @_;
  my $work  = tempdir( CLEANUP => 1 );
  my $stage = tempdir( CLEANUP => 1 );
  open my $c, '>', "$work/sqlite-vec.c" or die $!;
  print $c "#include <sqlite3ext.h>\nint vec_stub;\n";
  close $c;

  my $build = Alien::Build->load($file);
  $build->install_prop->{stage} = $stage;
  my $hook = $build->meta->{hook}{build}[0];

  my $cwd = getcwd();
  chdir $work or die $!;
  my $ok = eval { $hook->($build); 1 };
  my $err = $@;
  chdir $cwd or die $!;
  return ($ok, $err, $stage, $build);
}

subtest 'header found via DBD::SQLite share dir' => sub {
  my $share = eval {
    require DBD::SQLite;
    require File::ShareDir;
    File::ShareDir::dist_dir('DBD-SQLite');
  };
  plan skip_all => 'DBD::SQLite share dir not available'
    unless $share && -f "$share/sqlite3ext.h";

  my ($ok, $err, $stage, $build) = run_build($alienfile);
  ok $ok, 'build sub succeeds' or diag $err;
  ok -f "$stage/dynamic/libvec.$Config{dlext}", 'extension lands in dynamic/';
  is $build->runtime_prop->{ffi_name}, 'vec', 'ffi_name is set';
};

subtest 'header found nowhere' => sub {
  # Hide DBD::SQLite and point the system search at directories without it.
  (my $patched = $src) =~ s{'/usr/include', '/usr/local/include'}{'/nonexistent/a', '/nonexistent/b'}
    or die 'system include dirs not found in alienfile';
  my $dir  = tempdir( CLEANUP => 1 );
  my $file = "$dir/alienfile";
  open my $out, '>', $file or die $!;
  print $out $patched;
  close $out;

  local %INC = %INC;
  delete $INC{'DBD/SQLite.pm'};
  local @INC = (
    sub { die "DBD::SQLite hidden for this test\n" if $_[1] eq 'DBD/SQLite.pm'; return },
    @INC,
  );
  my ($ok, $err, $stage) = run_build($file);

  ok !$ok, 'build sub dies';
  like $err, qr/sqlite3ext\.h/, 'diagnostic names the missing header';
  like $err, qr/DBD::SQLite/,   'diagnostic says how to provide it';
  unlike $err, qr/Compilation of sqlite-vec failed/, 'fails before the compile';
  ok !-e "$stage/dynamic/libvec.$Config{dlext}", 'no extension was built';
};

done_testing;
