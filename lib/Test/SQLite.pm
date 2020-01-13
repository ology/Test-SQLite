package Test::SQLite;

# ABSTRACT: SQLite setup/teardown for tests

our $VERSION = '0.0103';

use Moo;
use strictures 2;

use DBI;
use File::Copy;
use File::Temp qw/ tempfile /;

=head1 SYNOPSIS

  use DBI;
  use Test::SQLite;

  my $sqlite = Test::SQLite->new(
    database => '/some/where/production.db',
  );

  my $dbh = DBI->connect($sqlite->dsn, '', '');

  $sqlite = Test::SQLite->new(
    schema => '/some/where/schema.sql',
  );

  $dbh = $sqlite->dbh;

=head1 DESCRIPTION

C<Test::SQLite> is loosely inspired by L<Test::PostgreSQL> and
L<Test::mysqld>, and creates a temporary db to use in tests.  Unlike
those modules, it is limited to setup/teardown of the test db given a
B<database> or B<schema> SQL file.  Also this module will return the
database B<dbh> handle and B<dsn> connection string.

=head1 ATTRIBUTES

=head2 database

The database to copy.

=head2 has_database

Boolean indicating that a database file was provided to the constructor.

=cut

has database => (
    is        => 'ro',
    isa       => sub { -e $_[0] },
    predicate => 'has_database',
);

=head2 schema

The SQL schema to create a test database.

=head2 has_schema

Boolean indicating that a schema file was provided to the constructor.

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
    return DBI->connect( $self->dsn, '', '' );
}

has _database => (
    is => 'lazy',
);

sub _build__database {
    my ($self) = @_;

    my $filename = File::Temp->new( unlink => 1, suffix => '.db' );

    if ( $self->has_database ) {
        copy( $self->database, $filename )
            or die "Can't copy " . $self->database . ": $!";
    }
    elsif ( $self->has_schema ) {
        open my $schema, '<', $self->schema
            or die "Can't read " . $self->schema . ": $!";

        my $dbh = DBI->connect( 'dbi:SQLite:dbname=' . $filename, '', '' )
            or die "Failed to open DB $filename: " . $DBI::errstr;

        my $sql = '';
        while ( my $line = readline($schema) ) {
            next if $line =~ /^\s*--/;

            $sql .= $line;

            if ( $line =~ /;/ ) {
                $dbh->do($sql)
                    or die 'Error executing SQL for ' . $self->schema . ': ' . $dbh->errstr;

                $sql = '';
            }
        }

        $dbh->disconnect;
    }

    return $filename;
}

=head1 METHODS

=head2 new

  $sqlite = Test::SQLite->new(%arguments);

Create a new C<Test::SQLite> object.

=head2 BUILD

Ensure that we are not given both a B<database> and a B<schema>.

=cut

sub BUILD {
    my ( $self, $args ) = @_;
    die 'Schema and database may not be used at the same time.'
        if $self->has_database and $self->has_schema;
}

1;
__END__

=head1 THANK YOU

Kaitlyn Parkhurst <symkat@symkat.com>

=head1 SEE ALSO

L<DBI>

L<File::Copy>

L<File::Temp>

L<Moo>

=cut
