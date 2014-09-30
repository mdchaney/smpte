#--
# Copyright 2014 Michael Chaney Consulting Corporation
#
# Released under the terms of the MIT License or the GNU
# General Public License, v. 2
#++

require 'minitest/autorun'
require 'smpte'

class SMPTETest < Minitest::Test
  def setup
    @options = {}
  end

  def teardown
  end

  def test_has_expected_methods
    smpte1 = SMPTE::SMPTE.new('01:00:00')

    assert_respond_to smpte1, :frame_count
    assert_respond_to smpte1, :has_frames
    assert_respond_to smpte1, :has_subframes
    assert_respond_to smpte1, :df
    assert_respond_to smpte1, :hours
    assert_respond_to smpte1, :minutes
    assert_respond_to smpte1, :seconds
    assert_respond_to smpte1, :frames
    assert_respond_to smpte1, :subframes

    assert_respond_to smpte1, :eql?
    assert_respond_to smpte1, :<=>
    assert_respond_to smpte1, :-
    assert_respond_to smpte1, :+
    assert_respond_to smpte1, :to_df
    assert_respond_to smpte1, :to_ndf
    assert_respond_to smpte1, :to_s
    assert_respond_to smpte1, :to_str
    assert_respond_to smpte1, :to_i
    assert_respond_to smpte1, :to_int
    assert_respond_to smpte1, :to_f
  end

  def test_simple_parse_string
    smpte1 = SMPTE::SMPTE.new('01:00:00')
    assert_equal 1, smpte1.hours
    assert_equal 0, smpte1.minutes
    assert_equal 0, smpte1.seconds
    assert_equal 0, smpte1.frames
    assert_equal 1 * 60 * 60 * 30, smpte1.frame_count
    assert_equal 'ndf', smpte1.df
    assert_equal false, smpte1.has_frames
  end

  def test_parse_string_with_frames
    smpte1 = SMPTE::SMPTE.new('02:23:45:15')
    assert_equal 2, smpte1.hours
    assert_equal 23, smpte1.minutes
    assert_equal 45, smpte1.seconds
    assert_equal 15, smpte1.frames
    assert_equal 'ndf', smpte1.df
    assert_equal true, smpte1.has_frames
  end

  def test_parse_string_with_subframes
    smpte1 = SMPTE::SMPTE.new('03:12:34:56.02')
    assert_equal 3, smpte1.hours
    assert_equal 12, smpte1.minutes
    assert_equal 34, smpte1.seconds
    assert_equal 56, smpte1.frames
    assert_equal 0.02, smpte1.subframes
    assert_equal 'ndf', smpte1.df
  end

  def test_parse_string_with_df
    smpte1 = SMPTE::SMPTE.new('03:13:24;35')
    assert_equal 3, smpte1.hours
    assert_equal 13, smpte1.minutes
    assert_equal 24, smpte1.seconds
    assert_equal 35, smpte1.frames
    assert_equal 'df', smpte1.df
  end

  def test_df_flag
    smpte1 = SMPTE::SMPTE.new('01:01:01', 'df')
    assert_equal 'df', smpte1.df
    smpte2 = SMPTE::SMPTE.new('01:01:01', 'ndf')
    assert_equal 'ndf', smpte2.df
    smpte1 = SMPTE::SMPTE.new('01:01:01', 'drop frame')
    assert_equal 'df', smpte1.df
    smpte2 = SMPTE::SMPTE.new('01:01:01', 'some random crap that is not valid')
    assert_equal 'ndf', smpte2.df
  end

  def test_craps_with_invalid_string
    assert_raises(SMPTE::InvalidParameterError) { SMPTE::SMPTE.new('wofiwejef') }
  end

  def test_create_with_integer
    one_hour_of_frames = 1 * 60 * 60 * 30
    smpte2 = SMPTE::SMPTE.new(one_hour_of_frames)  # one hour
    assert_equal 1, smpte2.hours
    assert_equal 0, smpte2.minutes
    assert_equal 0, smpte2.seconds
    assert_equal 0, smpte2.frames
    assert_equal one_hour_of_frames, smpte2.frame_count
    assert_equal 'ndf', smpte2.df
  end

  def test_create_with_float
    smpte3 = SMPTE::SMPTE.new(5.01)
    assert_equal 0, smpte3.hours
    assert_equal 0, smpte3.minutes
    assert_equal 0, smpte3.seconds
    assert_equal 5, smpte3.frames
    assert_equal 5.01, smpte3.frame_count
    assert_equal 'ndf', smpte3.df
  end

  def test_create_with_another_smpte
    smpte4 = SMPTE::SMPTE.new('01:30:40')
    smpte5 = SMPTE::SMPTE.new(smpte4)
    assert_equal smpte4.frame_count, smpte5.frame_count
  end

  # Can't create a SMPTE from an array - just picked a common core class
  # to test this.
  def test_craps_with_invalid_initializer
    assert_raises(SMPTE::InvalidParameterError) { SMPTE::SMPTE.new(Array.new) }
  end

  def test_equality_operator
    smpte6 = SMPTE::SMPTE.new('01:02:03:04')
    smpte7 = SMPTE::SMPTE.new('01:02:03:04')
    assert_equal true, smpte6.eql?(smpte7)
  end

  def test_comparison_operator
    smpte8 = SMPTE::SMPTE.new('02:00:00:00')
    smpte9 = SMPTE::SMPTE.new('02:00:00:01')
    smpte10 = SMPTE::SMPTE.new(smpte9)
    assert_equal -1, (smpte8 <=> smpte9)
    assert_equal 1, (smpte9 <=> smpte8)
    assert_equal 0, (smpte9 <=> smpte10)
  end

  def test_minus_operator
    smpte11 = SMPTE::SMPTE.new('02:00:01:00')
    smpte12 = SMPTE::SMPTE.new('02:00:00:00')
    smpte13 = smpte11 - smpte12
    assert_equal 30, smpte13.frame_count
  end

  def test_plus_operator
    smpte14 = SMPTE::SMPTE.new(20)
    smpte15 = smpte14 + 10
    assert_equal 30, smpte15.frame_count
  end

  def test_to_df
    smpte16 = SMPTE::SMPTE.new(100, 'df')
    assert_equal smpte16.frame_count, smpte16.to_df.frame_count
    smpte17 = SMPTE::SMPTE.new(100, 'ndf')
    assert_equal smpte17.frame_count, smpte17.to_df.frame_count
  end

  def test_to_ndf
    smpte16 = SMPTE::SMPTE.new(100, 'df')
    assert_equal smpte16.frame_count, smpte16.to_ndf.frame_count
    smpte17 = SMPTE::SMPTE.new(100, 'ndf')
    assert_equal smpte17.frame_count, smpte17.to_ndf.frame_count
  end

  def test_to_s
    smpte18 = SMPTE::SMPTE.new('01:00:00:00')
    assert_equal '01:00:00:00', smpte18.to_s
  end

  def test_to_s_with_df
    smpte18 = SMPTE::SMPTE.new('01:00:00;20')
    assert_equal '01:00:00;20', smpte18.to_s
  end

  def test_to_s_with_subframes
    smpte18 = SMPTE::SMPTE.new('01:00:00:00.02')
    assert_equal '01:00:00:00.02', smpte18.to_s
  end

  def test_to_s_with_subframes_and_df
    smpte18 = SMPTE::SMPTE.new('01:00:00;00.02')
    assert_equal '01:00:00;00.02', smpte18.to_s
  end

  def test_to_s_sans_frames
    smpte19 = SMPTE::SMPTE.new('01:00:00')
    assert_equal '01:00:00', smpte19.to_s
  end

  def test_to_i
    smpte20 = SMPTE::SMPTE.new('01:00:00')
    assert_equal 108000, smpte20.to_i
    smpte21 = SMPTE::SMPTE.new('01:00:00', 'df')
    assert_equal 107892, smpte21.to_i
  end

  def test_to_i_with_subframes
    smpte22 = SMPTE::SMPTE.new('01:00:00:00.02')
    assert_equal 108000, smpte22.to_i
  end

  def test_to_f
    smpte23 = SMPTE::SMPTE.new('01:00:00:00.05')
    assert_equal 108000.05, smpte23.to_f
  end
end
