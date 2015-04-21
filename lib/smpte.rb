# SMPTE gem is useful for manipulating SMPTE time codes.  It parses
# string representations and allows comparison, arithmetic operations,
# and computation of frame counts (including with the drop-frame format).
#
# Contact Michael Chaney Consulting Corporation for commercial
# support for this code: sales@michaelchaney.com
#
# Author::    Michael Chaney (mdchaney@michaelchaney.com)
# Copyright:: Copyright (c) 2014 Michael Chaney Consulting Corporation
# License::   Diestributed under the terms of the MIT License or the GNU General Public License v. 2
#
# == Example
#  smpte = SMPTE::SMPTE.new('01:00:00:00')
#  smpte.frame_count
#  => 108000
#  smpte2 = SMPTE::SMPTE.new('01:00:00;00')
#  smpte2.frame_count
#  => 107892
#  smpte3 = SMPTE::SMPTE.new('02:00:00:00')
#  smpte3 > smpte
#  => true
require 'smpte/base'
