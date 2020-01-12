#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Test::More;
use Test::Exception;

use_ok 'Test::SQLite';

throws_ok {
    Test::SQLite->new( schema => 't/test.sql', database => 't/test.db' )
} qr/Schema and database may not be used at the same time/,
'schema and database declared together';

my $sqlite = Test::SQLite->new( schema => 'eg/test.sql' );
ok -e $sqlite->_database, 'create test database from schema';

my $dbh = DBI->connect( $sqlite->dsn, '', '' );
isa_ok $dbh, 'DBI::db';
my $sql = 'SELECT name FROM account';
my $sth = $dbh->prepare($sql);
$sth->execute;
my $got = $sth->fetchall_arrayref;
my $expected = [ [ 'Gene' ] ];
is_deeply $got, $expected, 'expected data';
$dbh->disconnect;

$sqlite = Test::SQLite->new( database => 'eg/test.db' );
ok -e $sqlite->_database, 'create test database from database';

$dbh = $sqlite->dbh;
isa_ok $dbh, 'DBI::db';
$sth = $dbh->prepare($sql);
$sth->execute;
$got = $sth->fetchall_arrayref;
is_deeply $got, $expected, 'expected data';

done_testing();
