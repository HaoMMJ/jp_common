class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception

  def is_hiragana(w)
    !!(w =~ /^([\p{Hiragana}]*)$/)
  end

  def is_katakana(w)
    !!(w =~ /\p{Katakana}+/)
  end

  def is_kanji(w)
    !is_katakana(w) && !is_hiragana(w)
  end

  def is_japanese(w)
    !!(w =~ /^([\p{Hiragana}\p{Katakana}\p{Han}]*)$/)
  end
end
