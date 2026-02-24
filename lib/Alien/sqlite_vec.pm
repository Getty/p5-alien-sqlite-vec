package Alien::sqlite_vec;
# ABSTRACT: sqlite-vec SQLite extension for vector search
our $VERSION = '0.001';

use parent 'Alien::Base';

1;

=synopsis

  use Alien::sqlite_vec;
  use DBI;

  my $dbh = DBI->connect("dbi:SQLite:dbname=:memory:");
  $dbh->sqlite_enable_load_extension(1);

  my ($vec_path) = Alien::sqlite_vec->dynamic_libs;
  $dbh->do("SELECT load_extension(?)", {}, $vec_path);

=description

Provides the L<sqlite-vec|https://github.com/asg017/sqlite-vec> extension
for SQLite. sqlite-vec enables fast vector search (KNN) directly inside
SQLite using virtual tables.

This module downloads and compiles the sqlite-vec v0.1.6 amalgamation from
source, making the compiled extension available via
C<< Alien::sqlite_vec->dynamic_libs >>.

=seealso

=over

=item * L<SQLite::VecDB> - High-level vector database API using sqlite-vec

=item * L<https://github.com/asg017/sqlite-vec> - sqlite-vec project

=back

=cut
