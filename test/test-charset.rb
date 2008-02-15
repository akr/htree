require 'test/unit'
require 'htree/parse'

class TestCharset < Test::Unit::TestCase
  def setup
    unless "".respond_to? :force_encoding
      @old_kcode = $KCODE
    end
  end

  def teardown
    unless "".respond_to? :force_encoding
      $KCODE = @old_kcode
    end
  end

  def self.mark_string(str, charset)
    def str.read() self end
    class << str; self end.__send__(:define_method, :charset) { charset }
    if str.respond_to? :force_encoding
      str.force_encoding charset
    end
    str
  end

  # HIRAGANA LETTER A in various charset
  UTF8 = mark_string("\343\201\202", 'UTF-8')
  EUCKR = mark_string("\252\242", 'EUC-KR')
  EUCJP = mark_string("\244\242", 'EUC-JP')
  SJIS = mark_string("\202\240", 'Shift_JIS')
  ISO2022JP = mark_string("\e$B$\"\e(B", 'ISO-2022-JP')

  def with_kcode(kcode)
    if "".respond_to? :force_encoding
      if HTree::Encoder.internal_charset.start_with?(kcode.upcase)
        yield
      end
    else
      old = $KCODE
      begin
        $KCODE = kcode
        yield
      ensure
        $KCODE = old
      end
    end
  end

  def test_u
    with_kcode('u') {
      assert_equal(UTF8, HTree.parse(UTF8).children[0].to_s)
      assert_equal(UTF8, HTree.parse(EUCKR).children[0].to_s)
      assert_equal(UTF8, HTree.parse(EUCJP).children[0].to_s)
      assert_equal(UTF8, HTree.parse(SJIS).children[0].to_s)
      assert_equal(UTF8, HTree.parse(ISO2022JP).children[0].to_s)
    }
  end

  def test_e
    with_kcode('e') {
      assert_equal(EUCJP, HTree.parse(UTF8).children[0].to_s)
      assert_equal(EUCJP, HTree.parse(EUCKR).children[0].to_s)
      assert_equal(EUCJP, HTree.parse(EUCJP).children[0].to_s)
      assert_equal(EUCJP, HTree.parse(SJIS).children[0].to_s)
      assert_equal(EUCJP, HTree.parse(ISO2022JP).children[0].to_s)
    }
  end

  def test_s
    with_kcode('s') {
      assert_equal(SJIS, HTree.parse(UTF8).children[0].to_s)
      assert_equal(SJIS, HTree.parse(EUCKR).children[0].to_s)
      assert_equal(SJIS, HTree.parse(EUCJP).children[0].to_s)
      assert_equal(SJIS, HTree.parse(SJIS).children[0].to_s)
      assert_equal(SJIS, HTree.parse(ISO2022JP).children[0].to_s)
    }
  end

end
