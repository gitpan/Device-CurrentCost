#!/usr/bin/perl
#
# Copyright (C) 2011 by Mark Hindess

use strict;
use constant {
  DEBUG => $ENV{DEVICE_CURRENT_COST_TEST_DEBUG}
};
use Test::More tests => 88;
use t::Helpers qw/test_error/;
use POSIX qw/:termios_h/;

$|=1;
use_ok('Device::CurrentCost');
BEGIN { use_ok('Device::CurrentCost::Constants'); }

my $dev = Device::CurrentCost->new(device => 't/log/envy.reading.xml');
is($dev->type, CURRENT_COST_ENVY, 'envy device');
is(current_cost_type_string($dev->type), 'Envy', '... type name');
is($dev->baud, 57600, '... baud rate');
is($dev->baud, 57600, '... baud rate (cache)');
is($dev->posix_baud, 0010001, '... posix baud rate');
my $msg = $dev->read;
ok($msg, '... reading');
ok(!$msg->has_history, '... no history');
ok($msg->has_readings, '... has readings');
is($msg->device, 'CC128', '... device');
is($msg->device_version, 'v0.11', '... device version');
is($msg->device_type, CURRENT_COST_ENVY, '... device type');
is($msg->device_type, CURRENT_COST_ENVY, '... device type (cache)');
is($msg->boot_time, 7736559, '... device seconds since boot');
is($msg->boot_time, 7736559, '... device seconds since boot (cache)');
is($msg->sensor, 1, '... sensor');
is($msg->id, '01234', '... id');
is($msg->value, 2151+345, '... value');
is($msg->units, 'watts', '... units');
is(0+$msg->value(1), 345, '... value(1)');
is(0+$msg->value(2), 2151, '... value(2)');
is(0+$msg->value(3), 0, '... value(3)');
is($msg->temperature, 18.7, '... temperature');
is($msg->summary, q{Device: CC128 v0.11
  Sensor: 1 [01234,1]
  Total: 2496 watts
  Phase 1: 345 watts
  Phase 2: 2151 watts
  Phase 3: 0 watts
}, '... summary');

is(test_error(sub { $dev->read }),
   'Device::CurrentCost->read: closed', '... eof');

$dev = Device::CurrentCost->new(device => 't/log/classic.reading.xml',
                                type => CURRENT_COST_CLASSIC);
is($dev->type, CURRENT_COST_CLASSIC, 'classic device');
is(current_cost_type_string($dev->type), 'Classic', '... type name');
is($dev->baud, 9600, '... baud rate');
is($dev->posix_baud, POSIX::B9600, '... posix baud rate');
$msg = $dev->read(1);
ok($msg, '... reading');
ok(!$msg->has_history, '... no history');
ok($msg->has_readings, '... has readings');
is($msg->device_version, 'v1.06', '... device version');
is($msg->device, 'CC02', '... device');
is($msg->device_type, CURRENT_COST_CLASSIC, '... device type');
is($msg->boot_time, 131521, '... device seconds since boot');
is($msg->sensor, 0, '... sensor');
is($msg->id, '12345', '... id');
is($msg->value, 7806+144+144, '... value');
is($msg->units, 'watts', '... units');
is(0+$msg->value(1), 7806, '... value(1)');
is(0+$msg->value(2), 144, '... value(2)');
is(0+$msg->value(3), 144, '... value(3)');
is($msg->temperature, 21.1, '... temperature');
is($msg->summary('  '), q{  Device: CC02 v1.06
    Sensor: 0 [12345,1]
    Total: 8094 watts
    Phase 1: 7806 watts
    Phase 2: 144 watts
    Phase 3: 144 watts
}, '... summary');

is(test_error(sub { Device::CurrentCost->new() }),
   q{Device::CurrentCost->new: 'device' parameter is required},
   'constructor with missing device parameter');

like(test_error(sub { Device::CurrentCost->new(device => 't/not-found') }),
   qr!^sysopen of 't/not-found' failed: !,
   'constructor with invalid device');

$dev = Device::CurrentCost->new(device => 't/log/classic.too.short.xml',
                                type => CURRENT_COST_CLASSIC);
is($dev->type, CURRENT_COST_CLASSIC, 'classic device');
is(current_cost_type_string($dev->type), 'Classic', '... type name');
is($dev->baud, 9600, '... baud rate');
is(test_error(sub { $dev->read }),
   'Device::CurrentCost->read: closed', '... incomplete message');

$dev = Device::CurrentCost->new(device => 't/log/envy.history.xml');
$msg = $dev->read();
ok($msg, '... reading');
ok($msg->has_history, '... has history');
ok(!$msg->has_readings, '... no readings');
is($msg->device_version, 'v0.11', '... device version');
is($msg->device, 'CC128', '... device');
is($msg->device_type, CURRENT_COST_ENVY, '... device type');
is($msg->boot_time, 51541830, '... device seconds since boot');
is($msg->value, undef, '... no value');
is($msg->units, undef, '... no units');
is_deeply($msg->history,
          {
           0 => { hours => { 284 => 2.167, 286 => 1.936,
                             288 => 2.681, 290 => 4.543 } },
           1 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           2 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           3 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           4 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           5 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           6 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           7 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           8 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
           9 => { hours => { 284 => 0, 286 => 0, 288 => 0, 290 => 0 } },
          },
          '... history');
is($msg->summary, q{Device: CC128 v0.11
  History
    Sensor 0
      -284 hours: 2.167
      -286 hours: 1.936
      -288 hours: 2.681
      -290 hours: 4.543
    Sensor 1
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 2
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 3
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 4
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 5
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 6
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 7
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 8
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
    Sensor 9
      -284 hours: 0
      -286 hours: 0
      -288 hours: 0
      -290 hours: 0
}, '... summary');


$dev = Device::CurrentCost->new(device => 't/log/classic.history.xml');
$msg = $dev->read();
ok($msg, '... reading');
ok($msg->has_history, '... has history');
ok($msg->has_readings, '... has readings');
is($msg->device_version, 'v1.06', '... device version');
is($msg->device, 'CC02', '... device');
is($msg->device_type, CURRENT_COST_CLASSIC, '... device type');
is($msg->boot_time, 131533, '... device seconds since boot');
is($msg->sensor, 0, '... sensor');
is($msg->id, '12345', '... id');
is($msg->value, 8040, '... value');
is($msg->units, 'watts', '... units');
is(0+$msg->value(1), 7752, '... value(1)');
is(0+$msg->value(2), 144, '... value(2)');
is(0+$msg->value(3), 144, '... value(3)');
is(0+$msg->temperature, 21, '... temperature');
is($msg->summary,
   q{Device: CC02 v1.06
  Sensor: 0 [12345,1]
  Total: 8040 watts
  Phase 1: 7752 watts
  Phase 2: 144 watts
  Phase 3: 144 watts
  History
    Sensor 0
      -01 days: 0
      -02 days: 0
      -03 days: 0
      -04 days: 0
      -05 days: 0
      -06 days: 0
      -07 days: 0
      -08 days: 0
      -09 days: 0
      -10 days: 0
      -11 days: 0
      -12 days: 0
      -13 days: 0
      -14 days: 0
      -15 days: 0
      -16 days: 0
      -17 days: 0
      -18 days: 0
      -19 days: 0
      -20 days: 0
      -21 days: 0
      -22 days: 0
      -23 days: 0
      -24 days: 0
      -25 days: 0
      -26 days: 0
      -27 days: 0
      -28 days: 0
      -29 days: 0
      -30 days: 0
      -31 days: 0
      -02 hours: 1.3
      -04 hours: 0
      -06 hours: 0
      -08 hours: 0
      -10 hours: 0
      -12 hours: 0
      -14 hours: 0
      -16 hours: 0
      -18 hours: 0
      -20 hours: 0
      -22 hours: 0
      -24 hours: 0
      -26 hours: 0
      -01 months: 0
      -02 months: 0
      -03 months: 0
      -04 months: 0
      -05 months: 0
      -06 months: 0
      -07 months: 0
      -08 months: 0
      -09 months: 0
      -10 months: 0
      -11 months: 0
      -12 months: 0
      -1 years: 0
      -2 years: 0
      -3 years: 0
      -4 years: 0
}, '... summary');

$dev = Device::CurrentCost->new(device => 't/log/cc128.two.xml');
$msg = $dev->read;
ok($msg, '... reading');
ok(!$msg->has_history, '... no history');
ok($msg->has_readings, '... has readings');
is($msg->summary,
   q{Device: CC128 v0.11
  Sensor: 0 [00077,1]
  Total: 1380 watts
  Phase 1: 1380 watts
}, '... summary');
$msg = $dev->read;
ok($msg, '... reading');
ok(!$msg->has_history, '... no history');
ok($msg->has_readings, '... has readings');
is($msg->summary,
   q{Device: CC128 v0.11
  Sensor: 0 [00077,1]
  Total: 1469 watts
  Phase 1: 1469 watts
}, '... summary');

$dev->{baud} = 9900;
is(test_error(sub { $dev->posix_baud }),
   "Unsupported baud rate: 9900\n", '... unsupported baud rate');
