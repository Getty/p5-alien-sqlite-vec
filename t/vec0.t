use Test2::V0;
use Alien::sqlite_vec;

BEGIN {
  eval { require DBI; require DBD::SQLite; 1 }
    or skip_all 'DBD::SQLite is not available';
}

my ($vec) = Alien::sqlite_vec->dynamic_libs;
ok $vec, 'dynamic_libs yields the extension path' or bail_out 'no extension to load';

my $dbh = DBI->connect('dbi:SQLite:dbname=:memory:', '', '', { RaiseError => 1, PrintError => 0 });
$dbh->sqlite_enable_load_extension(1);

ok lives { $dbh->do('SELECT load_extension(?)', {}, $vec) }, 'extension loads into SQLite'
  or bail_out 'extension did not load';

my ($version) = $dbh->selectrow_array('SELECT vec_version()');
like $version, qr/^v?0\.1\.6/, 'vec_version() reports sqlite-vec 0.1.6';

ok lives { $dbh->do('CREATE VIRTUAL TABLE v USING vec0(embedding float[3])') },
  'vec0 virtual table can be created';

$dbh->do('INSERT INTO v(rowid, embedding) VALUES (1, ?)', {}, '[1,0,0]');
$dbh->do('INSERT INTO v(rowid, embedding) VALUES (2, ?)', {}, '[0,1,0]');

my ($nearest) = $dbh->selectrow_array(
  'SELECT rowid FROM v WHERE embedding MATCH ? AND k = 1', {}, '[0,0.9,0]',
);
is $nearest, 2, 'KNN query returns the nearest vector';

done_testing;
