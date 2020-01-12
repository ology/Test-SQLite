#!/usr/bin/env perl
use strict;
use warnings;

use DBI;
use Test::More;

use_ok 'Test::SQLite';

my $sqlite = Test::SQLite->new( schema => 't/test.sql' );
ok -e $sqlite->testdb, 'create testdb';

$sqlite = Test::SQLite->new( database => 't/test.db' );
ok -e $sqlite->testdb, 'create testdb';

my $dbh = DBI->connect( $sqlite->dsn, '', '' );
my $sql = 'SELECT name FROM account';
my $sth = $dbh->prepare($sql);
$sth->execute;
my $got = $sth->fetchall_arrayref;
my $expected = [ [ 'Gene' ] ];
is_deeply $got, $expected, 'expected data';
$dbh->disconnect;

$dbh = $sqlite->dbh;
isa_ok $dbh, 'DBI::db';
$sth = $dbh->prepare($sql);
$sth->execute;
$got = $sth->fetchall_arrayref;
is_deeply $got, $expected, 'expected data';

done_testing();
