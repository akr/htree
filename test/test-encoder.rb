require 'test/unit'
require 'htree/encoder'

class TestEncoder < Test::Unit::TestCase
  EUC_JISX0212_CH = "\217\260\241" # cannot encode with Shift_JIS.
  EUC_JISX0208_CH = "\260\241"

  def test_minimal_charset
    out = HTree::Encoder.new('Shift_JIS', 'EUC-JP')
    assert_equal("US-ASCII", out.minimal_charset)
    out.output_text("a")
    assert_equal("US-ASCII", out.minimal_charset)
    out.output_text(EUC_JISX0212_CH)
    assert_equal("US-ASCII", out.minimal_charset)
    out.output_text("b")
    assert_equal("US-ASCII", out.minimal_charset)
    assert_equal("a&#19970;b", out.finish)
  end

  def test_minimal_charset_2
    out = HTree::Encoder.new('ISO-2022-JP-2', 'EUC-JP')
    assert_equal("US-ASCII", out.minimal_charset)
    out.output_text("a")
    assert_equal("US-ASCII", out.minimal_charset)
    out.output_text(EUC_JISX0208_CH)
    assert_equal("ISO-2022-JP", out.minimal_charset)
    out.output_text("b")
    assert_equal("ISO-2022-JP", out.minimal_charset)
    out.output_text(EUC_JISX0212_CH)
    assert_equal("ISO-2022-JP-2", out.minimal_charset)
    assert_equal("a\e$B0!\e(Bb\e$(D0!\e(B", out.finish)
  end

  def test_minimal_charset_u
    out = HTree::Encoder.new('UTF-16BE', 'EUC-JP')
    assert_equal("UTF-16BE", out.minimal_charset)
    out.output_text("a")
    assert_equal("UTF-16BE", out.minimal_charset)
    assert_equal("\000a", out.finish)
  end

  def test_close
    out = HTree::Encoder.new('ISO-2022-JP', 'EUC-JP')
    out.output_string(EUC_JISX0208_CH)
    assert_equal("ISO-2022-JP", out.minimal_charset)
    assert_equal("\e$B0!\e(B", out.finish)
  end

end
