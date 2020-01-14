#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Test::More;
use Test::Exception;

use_ok 'Test::SQLite';

throws_ok {
    Test::SQLite->new
} qr/No schema or database given/,
'schema or database required';

throws_ok {
    Test::SQLite->new( schema => 'eg/test.sql', database => 'eg/test.db' )
} qr/may not be used at the same time/,
'schema and database declared together';

throws_ok {
    Test::SQLite->new( schema => 'eg/bogus.sql' )
} qr/schema does not exist/,
'schema does not exist';

throws_ok {
    Test::SQLite->new( database => 'eg/bogus.db' )
} qr/database does not exist/,
'database does not exist';

my $got = from_sql();
ok !-e $got, 'db removed';

$got = from_db();
ok !-e $got, 'db removed';

done_testing();

sub from_sql {
    my $sqlite = Test::SQLite->new(
        schema    => 'eg/test.sql',
        dsn       => 'foo',
        dbh       => 'foo',
        _database => 'foo',
    );
    ok -e $sqlite->_database, 'create test database from schema';

    isnt $sqlite->dsn, 'foo', 'dsn constructor ignored';
    isnt $sqlite->dbh, 'foo', 'dbh constructor ignored';
    isnt $sqlite->_database, 'foo', '_database constructor ignored';

    is_deeply $sqlite->db_attrs, { RaiseError => 1, AutoCommit => 1 }, 'db_attrs';

    my $sql = 'SELECT name FROM account';
    my $expected = [ [ 'Gene' ] ];

    my $dbh = DBI->connect( $sqlite->dsn, '', '', $sqlite->db_attrs );
    isa_ok $dbh, 'DBI::db';
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my $got = $sth->fetchall_arrayref;
    is_deeply $got, $expected, 'expected data';
    $dbh->disconnect;

    return $sqlite->_database->filename;
}

sub from_db {
    my $sqlite = Test::SQLite->new( database => 'eg/test.db' );
    ok -e $sqlite->_database, 'create test database from database';

    my $sql = 'SELECT name FROM account';
    my $expected = [ [ 'Gene' ] ];

    my $dbh = $sqlite->dbh;
    isa_ok $dbh, 'DBI::db';
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my $got = $sth->fetchall_arrayref;
    is_deeply $got, $expected, 'expected data';

    return $sqlite->_database->filename;
}
