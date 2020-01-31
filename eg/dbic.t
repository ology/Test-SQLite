#!/usr/bin/env perl
use strict;
use warnings;

use Test::More;
use Test::SQLite;

use MyApp::Schema;  # Existing database model

my $sqlite = Test::SQLite->new(schema => '/some/empty.sql');
isa_ok $sqlite, 'Test::SQLite';

my $schema = MyApp::Schema->connect( $sqlite->dsn );
isa_ok $schema, 'MyApp::Schema';

$schema->deploy;

my $name  = 'test-' . time();
my $class = 'Account';

my $user = $schema->resultset($class)->create({
    name     => $name,
    password => 'test',
});
isa_ok $user, 'MyApp::Schema::Result::Account';

my $result = $schema->resultset($class)->search_by_name($name); # Custom ResultSet method
isa_ok $result, 'MyApp::Schema::Result::Account';
is $result->name, $user->name, 'name';
is $result->id, $user->id, 'id';

done_testing();
