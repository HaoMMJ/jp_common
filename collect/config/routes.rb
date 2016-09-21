Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  #10000 common
  get 'index'   => 'collect#index'
  get 'collect_all'   => 'collect#collect_all'
  get 'jlpt_collect'   => 'collect#jlpt_collect'
  get 'jlpt_insert'   => 'collect#jlpt_insert'
  get 'save'    => 'collect#save'
  get 'fix_302' => 'collect#fix_302'
  get 'filter'  => 'collect#filter'
  get 'fix_unicode_insert' => 'collect#fix_unicode_insert'
  get 'insert_wrong_format' => 'collect#insert_wrong_format'
  get 'common_list' => 'collect#common_list'
  get 'create_meaning' => 'collect#create_meaning'
  get 'create_missing_words' => 'collect#create_missing_words'
  get 'filter_15000' => 'collect#filter_15000'
  get 'create_jisho_meaning' => 'collect#create_jisho_meaning'
  get 'create_missing_meanings' => 'collect#create_missing_meanings'
  get 'fix_not_found' => 'collect#fix_not_found'
  get 'import_kanji_dictionary' => 'collect#import_kanji_dictionary'
  get 'fix_raw_dictionary_source' => 'collect#fix_raw_dictionary_source'

  #Minna
  get 'create_minna_raw_data' => 'minna#create_minna_raw_data'
  get 'create_minna_dictionary' => 'minna#create_minna_dictionary'
  get 'create_minna_quizlet' => 'minna#create_minna_quizlet'
  get 'fix_minna_level' => 'minna#fix_level'


  #Dictionary
  get  'create_list' => 'dictionary#create_list_form'
  post 'create_list' => 'dictionary#create_list'
  get  'update_list/:id' => 'dictionary#update_list_form', as: :dictionary_detail
  post 'update_dic_info/:id' => 'dictionary#update_dic_info', as: :dictionary_update
  post 'update_list' => 'dictionary#update_list'
  get 'import_data_to_vocabs' => 'dictionary#import_data_to_vocabs'

  #Reading
  get 'create_course_form' => 'reading#create_course_form'
  post 'create_course' => 'reading#create_course'
  get 'update_course_form' => 'reading#update_course_form'
  post 'update_course' => 'reading#update_course'
  get 'create_lession_form' => 'reading#create_lession_form'
  get 'create_lession' => 'reading#create_lession'
  get 'update_lession_form' => 'reading#update_lession_form'
  get 'update_lession' => 'reading#update_lession'
  get 'auto_translate_form' => 'reading#auto_translate_form'
  post 'auto_translate' => 'reading#auto_translate'
  get 'search_word' => 'reading#search_word'

  #Fix
  get 'detect_vocabulary_error' => 'fix#detect_vocabulary_error'
  get 'fix_vocabulary' => 'fix#fix_vocabulary'
  get 'manual_fix_vocabulary' => 'fix#manual_fix_vocabulary'

  #Full Dictionary
  get 'filter_full_dictionary' => 'vocabulary#filter_full_dictionary'
  get 'filter_duplicate_hiragana' => 'vocabulary#filter_duplicate_hiragana'
  get 'last_filter_hiragana' => 'vocabulary#last_filter_hiragana'
  get 'insert_hiragana' => 'vocabulary#insert_hiragana'
end
