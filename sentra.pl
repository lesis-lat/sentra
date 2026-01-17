#!/usr/bin/env perl

use 5.030;
use strict;
use warnings;
use lib './lib/';
use Sentra::Network::Flow;

our $VERSION = '0.0.1';

exit Sentra::Network::Flow -> new();
