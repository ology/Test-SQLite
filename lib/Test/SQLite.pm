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
L<Test::mysqld>, but is limited to setup/teardown of the test db
given a B<database> or B<schema> SQL, and returning the database
B<DBH> handle or B<DSN> connection string.

=head1 ATTRIBUTES

=head2 database

The database to copy.

=cut

has database => (
    is        => 'ro',
    isa       => sub { -e $_[0] },
    predicate => 'has_database',
);

=head2 schema

The SQL schema to create a test database.

=cut

has schema => (
    is        => 'ro',
    isa       => sub { -e $_[0] },
    predicate => 'has_schema',
);

=head2 dsn

The database connection string.

=cut

has dsn => (
    is => 'lazy',
);

sub _build_dsn {
    my ($self) = @_;
    return 'dbi:SQLite:dbname=' . $self->_database->filename;
}

=head2 dbh

A connected database handle.

=cut

has dbh => (
    is => 'lazy',
);

sub _build_dbh {
    my ($self) = @_;
    return DBI->connect( 'dbi:SQLite:dbname=' . $self->_database->filename );
}

has _database => (
    is => 'lazy',
);

sub _build__database {
    my ($self) = @_;

    my $filename = File::Temp->new( unlink => 1, suffix => 'db' );

    if ( $self->has_database ) {
        copy( $self->database, $filename )
            or die 'Copy of ' . $self->database . "failed: $!";
    }
    elsif ( $self->has_schema ) {
        open my $schema, '<', $self->schema
            or die "Can't read " . $self->schema . ": $!";

        my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $filename )
            or die "Failed to open DB $filename";

        while ( my $line = readline($schema) ) {
            $dbh->do($line)
                or die 'SQLite Error(' . $self->schema . '): ' . $dbh->errstr;
        }

        $dbh->disconnect;
    }

    return $filename;
}

=head1 METHODS

=head2 new

  $x = Test::SQLite->new(%arguments);

Create a new C<Test::SQLite> object.

=head2 BUILD

Ensure that we are given either a B<database> or a B<schema>.

=cut

sub BUILD {
    my ( $self, $args ) = @_;

    die 'Schema and database may not be used at the same time.'
        if $self->database and $self->schema;
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
