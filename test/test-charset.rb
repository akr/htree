require 'test/unit'
require 'htree/parse'

class TestCharset < Test::Unit::TestCase
  def setup
    @old_kcode = $KCODE
  end

  def teardown
    $KCODE = @old_kcode
  end

  def self.mark_string(str, charset)
    def str.read() self end
    class << str; self end.__send__(:define_method, :charset) { charset }
    str
  end

  # HIRAGANA LETTER A in various charset
  UTF8 = mark_string("\343\201\202", 'UTF-8')
  EUCKR = mark_string("\252\242", 'EUC-KR')
  EUCJP = mark_string("\244\242", 'EUC-JP')
  SJIS = mark_string("\202\240", 'Shift_JIS')
  ISO2022JP = mark_string("\e$B$\"\e(B", 'ISO-2022-JP')

  def test_u
    $KCODE = 'u'
    assert_equal(UTF8, HTree.parse(UTF8).children[0].to_s)
    assert_equal(UTF8, HTree.parse(EUCKR).children[0].to_s)
    assert_equal(UTF8, HTree.parse(EUCJP).children[0].to_s)
    assert_equal(UTF8, HTree.parse(SJIS).children[0].to_s)
    assert_equal(UTF8, HTree.parse(ISO2022JP).children[0].to_s)
  end

  def test_e
    $KCODE = 'e'
    assert_equal(EUCJP, HTree.parse(UTF8).children[0].to_s)
    assert_equal(EUCKR, HTree.parse(EUCKR).children[0].to_s)
    assert_equal(EUCJP, HTree.parse(EUCJP).children[0].to_s)
    assert_equal(EUCJP, HTree.parse(SJIS).children[0].to_s)
    assert_equal(EUCJP, HTree.parse(ISO2022JP).children[0].to_s)
  end

  def test_s
    $KCODE = 's'
    assert_equal(SJIS, HTree.parse(UTF8).children[0].to_s)
    assert_equal(SJIS, HTree.parse(EUCKR).children[0].to_s)
    assert_equal(SJIS, HTree.parse(EUCJP).children[0].to_s)
    assert_equal(SJIS, HTree.parse(SJIS).children[0].to_s)
    assert_equal(SJIS, HTree.parse(ISO2022JP).children[0].to_s)
  end

end
