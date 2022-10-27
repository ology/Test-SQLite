package Test::SQLite;

# ABSTRACT: SQLite setup/teardown for tests

our $VERSION = '0.0409';

use strictures 2;
use DBI ();
use File::Copy qw(copy);
use File::Temp ();
use Moo;
use namespace::clean;

=head1 SYNOPSIS

  use DBI;
  use Test::SQLite;

  # An empty test db:
  my $sqlite = Test::SQLite->new;
  my $dbh = $sqlite->dbh;
  # Fiddle with the test database...
  $dbh->disconnect;

  # Use an in-memory test db:
  $sqlite = Test::SQLite->new(memory => 1);

  # Copy a database file to the test db:
  $sqlite = Test::SQLite->new(database => '/some/where/database.db');

  # Use a schema file to create the test db:
  $sqlite = Test::SQLite->new(
    schema   => '/some/where/schema.sql',
    db_attrs => { RaiseError => 1, AutoCommit => 0 },
  );

  # Explicitly use the dsn and db_attrs to connect:
  $dbh = DBI->connect($sqlite->dsn, '', '', $sqlite->db_attrs);
  # Fiddle with the test database...
  $dbh->commit;
  $dbh->disconnect;

=head1 DESCRIPTION

C<Test::SQLite> is inspired by L<Test::PostgreSQL> and
L<Test::mysqld>, and creates a temporary sqlite database to use in
tests.

This module will also return the database B<dbh> handle, B<dsn>
connection string, and B<db_attrs> connection attributes.

=head1 ATTRIBUTES

=head2 database

The existing database to copy to create a new test database.

=head2 has_database

Boolean indicating that a B<database> file was provided to the
constructor.

=cut

has database => (
    is        => 'ro',
    isa       => sub { die 'database does not exist' unless -e $_[0] },
    predicate => 'has_database',
);

=head2 schema

The SQL schema with which to create a test database.

* The SQL parsing done by this module does not handle triggers.

=head2 has_schema

Boolean indicating that a B<schema> file was provided to the
constructor.

=cut

has schema => (
    is        => 'ro',
    isa       => sub { die 'schema does not exist' unless -e $_[0] },
    predicate => 'has_schema',
);

=head2 memory

Create a test database in memory.

=head2 has_memory

Boolean indicating that B<memory> was provided to the constructor.

=cut

has memory => (
    is        => 'ro',
    predicate => 'has_memory',
);

=head2 db_attrs

DBI connection attributes.

Default: { RaiseError => 1, AutoCommit => 1 }

=cut

has db_attrs => (
    is      => 'ro',
    default => sub { return { RaiseError => 1, AutoCommit => 1 } },
);

=head2 dsn

The database connection string.  This is a computed attribute and an
argument given to the constructor will be ignored.

=cut

has dsn => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_dsn {
    my ($self) = @_;
    return 'dbi:SQLite:dbname=' . ( $self->has_memory ? $self->_database : $self->_database->filename );
}

=head2 dbh

A connected database handle based on the B<dsn> and B<db_attrs>.  This
is a computed attribute and an argument given to the constructor will
be ignored.

=cut

has dbh => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build_dbh {
    my ($self) = @_;
    return DBI->connect( $self->dsn, '', '', $self->db_attrs );
}

has _database => (
    is       => 'lazy',
    init_arg => undef,
);

sub _build__database {
    my ($self) = @_;

    my $tempfile = $self->has_memory
        ? ':memory:'
        : File::Temp->new( unlink => 1, suffix => '.db', EXLOCK => 0 );

    if ( $self->has_database ) {
        copy( $self->database, $tempfile->filename )
            or die "Can't copy " . $self->database . ": $!";
    }
    elsif ( $self->has_schema ) {
        open my $schema, '<', $self->schema
            or die "Can't read " . $self->schema . ": $!";

        my $dbh = DBI->connect( "dbi:SQLite:dbname=$tempfile", '', '', { RaiseError => 1, AutoCommit => 0 } )
            or die "Can't connect to $tempfile: " . $DBI::errstr;

        my $sql = '';
        while ( my $line = readline($schema) ) {
            next if $line =~ /^\s*--/;
            next if $line =~ /^\s*$/;

            $sql .= $line;

            if ( $line =~ /;/ ) {
                $dbh->do($sql)
                    or die 'Error executing SQL for ' . $self->schema . ': ' . $dbh->errstr;

                $sql = '';
            }
        }

        $dbh->commit;

        $dbh->disconnect;
    }

    return $tempfile;
}

=head1 METHODS

=head2 new

  $sqlite = Test::SQLite->new;
  $sqlite = Test::SQLite->new(%arguments);

Create a new C<Test::SQLite> object.

=for Pod::Coverage BUILD

=cut

sub BUILD {
    my ( $self, $args ) = @_;
    die 'The schema, database and memory arguments may not be used together.'
        if ( $self->has_database and $self->has_schema )
            or ( $self->has_database and $self->has_memory )
            or ( $self->has_schema and $self->has_memory );
}

1;
__END__

=head1 SEE ALSO

The F<t/01-methods.t> file in this distribution.

The F<eg/dbic.t> example test in this distribution.

L<DBI>

L<File::Copy>

L<File::Temp>

L<Moo>

=head1 THANK YOU

Kaitlyn Parkhurst (SYMKAT) <symkat@symkat.com>

=cut
