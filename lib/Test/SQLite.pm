package Test::SQLite;

# ABSTRACT: SQLite setup/teardown for tests

our $VERSION = '0.0100';

use Moo;
use strictures 2;

use DBI;
use File::Basename;
use File::Copy;
use File::Temp qw/ tempfile /;

=head1 NAME

Test::SQLite - SQLite setup/teardown for tests

=head1 SYNOPSIS

  use DBI;
  use Test::SQLite;

  my $sqlite = Test::SQLite->new(
    database => '/some/where/production.db',
  );

  $sqlite = Test::SQLite->new(
    schema => '/some/where/schema.sql',
  );

  my $dbh = DBI->connect($sqlite->dsn);

  $dbh = $sqlite->dbh;

=head1 DESCRIPTION

C<Test::SQLite> is loosely inspired by L<Test::PostgreSQL> and
L<Test::mysqld>, but is limited to setup/teardown of the B<testdb>
given a B<database> or B<schema> SQL, and returning the database
B<DBH> handle or B<DSN> connection string.

=head1 ATTRIBUTES

=head2 database

The database to copy.

=cut

has database => (
    is => 'ro',
);

=head2 schema

The SQL schema to create a test database.

=cut

has schema => (
    is => 'ro',
);

=head2 testdb

The created test database path and filename.

=cut

has testdb => (
    is        => 'lazy',
    init_args => undef,
);

sub _build_testdb {
    my ($self) = @_;

    my ( undef, $filename ) = tempfile( TEMPLATE => 'test_XXXXXX', SUFFIX => '.db', UNLINK => 1 );

    if ( $self->database ) {
        copy( $self->database, $filename )
            or die "Copy failed: $!";
    }
    elsif ( $self->schema ) {
        open my $schema, '<', $self->schema
            or die "Can't read " . $self->schema . ": $!";
        my $content;
        while ( my $line = readline($schema) ) {
            next if $line =~ /^\s*--/;
            $content .= $line;
        }
        close $schema;

        my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $filename );
        for my $command ( split( /;/, $content ) ) {
            next if $command =~ /^\s*$/;
            $dbh->do( $command )
                or die 'SQLite Error(' . $self->schema . "): $command: " . $dbh->errstr;
        }
        undef $dbh;
    }

    return $filename;
}

=head2 dsn

The database connection string.

=cut

has dsn => (
    is => 'lazy',
);

sub _build_dsn {
    my ($self) = @_;

    my $testdb = $self->testdb;

    my $dsn = 'dbi:SQLite:dbname=' . $testdb;

    return $dsn;
}

=head2 dbh

A connected database handle.

=cut

has dbh => (
    is => 'lazy',
);

sub _build_dbh {
    my ($self) = @_;

    my $dbh = DBI->connect( $self->dsn, '', '' );

    return $dbh;
}

=head1 METHODS

=head2 new

  $x = Test::SQLite->new(%arguments);

Create a new C<Test::SQLite> object.

=head2 BUILD

Insure that we are given either a B<database> or a B<schema>.

=cut

sub BUILD {
    my ( $self, $args ) = @_;

    die 'Either a database or a schema are required.'
        unless $self->database or $self->schema;
}

1;
__END__

=head1 THANK YOU

Kaitlyn Parkhurst <symkat@symkat.com>

=head1 SEE ALSO

L<File::Basename>

L<File::Copy>

L<File::Temp>

L<Moo>

=cut
